// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/interfaces/IVelodromeCLPool.sol";
import "../src/interfaces/IWETH.sol";
import "../src/LiskConfig.sol";

contract DebugCLPoolSwap is Script, LiskConfig {
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEBUGGING CL POOL SWAP ===");
        console.log("Pool address:", WETH_wstETH_CL_POOL);
        console.log("WETH address:", WETH);
        console.log("wstETH address:", wstETH);
        
        // Check if pool exists and is callable
        IVelodromeCLPool pool = IVelodromeCLPool(WETH_wstETH_CL_POOL);
        IWETH wethToken = IWETH(WETH);
        
        console.log("\n=== Step 1: Check Pool State ===");
        try pool.slot0() returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        ) {
            console.log("Pool is accessible");
            console.log("sqrtPriceX96:", sqrtPriceX96);
            console.log("Current tick:", int256(tick));
            console.log("Pool unlocked:", unlocked);
        } catch Error(string memory reason) {
            console.log("Pool slot0() failed:", reason);
            vm.stopBroadcast();
            return;
        } catch {
            console.log("Pool slot0() failed with unknown error");
            vm.stopBroadcast();
            return;
        }
        
        console.log("\n=== Step 2: Check Token Order ===");
        try pool.token0() returns (address token0) {
            address token1 = pool.token1();
            console.log("Pool token0:", token0);
            console.log("Pool token1:", token1);
            console.log("WETH < wstETH?", WETH < wstETH);
            
            if (token0 != WETH) {
                console.log("ERROR: token0 is not WETH!");
                console.log("Expected token0 (WETH):", WETH);
                console.log("Actual token0:", token0);
            }
            if (token1 != wstETH) {
                console.log("ERROR: token1 is not wstETH!");
                console.log("Expected token1 (wstETH):", wstETH);
                console.log("Actual token1:", token1);
            }
        } catch {
            console.log("ERROR: Cannot read pool tokens");
            vm.stopBroadcast();
            return;
        }
        
        console.log("\n=== Step 3: Check Our WETH Balance ===");
        uint256 wethBalance = wethToken.balanceOf(msg.sender);
        console.log("Our WETH balance:", wethBalance);
        
        if (wethBalance == 0) {
            console.log("Getting some WETH for testing...");
            wethToken.deposit{value: 0.0001 ether}();
            wethBalance = wethToken.balanceOf(msg.sender);
            console.log("New WETH balance:", wethBalance);
        }
        
        console.log("\n=== Step 4: Test Small CL Pool Swap ===");
        uint256 swapAmount = 0.00001 ether; // Very small amount
        
        // Approve WETH to pool
        wethToken.approve(WETH_wstETH_CL_POOL, swapAmount);
        console.log("Approved", swapAmount, "WETH to pool");
        
        // Get price limit
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint256 slippageBps = 500; // 5% slippage for testing
        uint160 priceDelta = uint160((uint256(sqrtPriceX96) * slippageBps) / 10000);
        uint160 sqrtPriceLimitX96 = sqrtPriceX96 - priceDelta;
        
        console.log("Swap parameters:");
        console.log("- Amount:", swapAmount);
        console.log("- zeroForOne: true (WETH->wstETH)");
        console.log("- sqrtPriceX96:", sqrtPriceX96);
        console.log("- sqrtPriceLimitX96:", sqrtPriceLimitX96);
        
        // Deploy minimal callback contract for testing
        TestCallback callback = new TestCallback();
        
        // Try the swap via callback contract
        try callback.testSwap(WETH_wstETH_CL_POOL, WETH, swapAmount) {
            console.log("SUCCESS: CL pool swap worked!");
        } catch Error(string memory reason) {
            console.log("SWAP FAILED:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("SWAP FAILED with low-level error");
            console.log("Error data length:", lowLevelData.length);
            if (lowLevelData.length > 0) {
                console.logBytes(lowLevelData);
            }
        }
        
        vm.stopBroadcast();
    }
}

contract TestCallback is LiskConfig {
    
    function testSwap(address pool, address wethAddr, uint256 amount) external {
        IVelodromeCLPool clPool = IVelodromeCLPool(pool);
        IWETH weth = IWETH(wethAddr);
        
        // Transfer WETH from caller
        weth.transferFrom(msg.sender, address(this), amount);
        
        // Approve to pool
        weth.approve(pool, amount);
        
        // Get current price
        (uint160 sqrtPriceX96, , , , , , ) = clPool.slot0();
        uint160 sqrtPriceLimitX96 = sqrtPriceX96 - uint160((uint256(sqrtPriceX96) * 500) / 10000); // 5% slippage
        
        // Perform swap
        clPool.swap(
            address(this),      // recipient  
            true,              // zeroForOne (WETH->wstETH)
            int256(amount),    // amountSpecified
            sqrtPriceLimitX96, // sqrtPriceLimitX96
            ""                 // data
        );
    }
    
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        console.log("=== CALLBACK CALLED ===");
        console.log("amount0Delta:", amount0Delta);
        console.log("amount1Delta:", amount1Delta);
        
        // Pay what we owe (positive delta = we owe tokens)
        if (amount0Delta > 0) {
            IWETH(WETH).transfer(msg.sender, uint256(amount0Delta));
            console.log("Paid", uint256(amount0Delta), "WETH to pool");
        }
        if (amount1Delta > 0) {
            IERC20(wstETH).transfer(msg.sender, uint256(amount1Delta));
            console.log("Paid", uint256(amount1Delta), "wstETH to pool");
        }
        
        console.log("Callback completed successfully");
    }
}
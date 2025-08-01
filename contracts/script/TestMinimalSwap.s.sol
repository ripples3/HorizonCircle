// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiskConfig.sol";

interface IMinimalCLPool {
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
    
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

interface IERC20Minimal {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TestMinimalSwap is Script, LiskConfig {
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== MINIMAL SWAP TEST ===");
        
        IMinimalCLPool pool = IMinimalCLPool(WETH_wstETH_CL_POOL);
        IERC20Minimal weth = IERC20Minimal(WETH);
        
        // Get some WETH
        uint256 initialBalance = weth.balanceOf(msg.sender);
        console.log("Initial WETH balance:", initialBalance);
        
        if (initialBalance < 0.0001 ether) {
            // Deposit ETH to get WETH
            (bool success,) = WETH.call{value: 0.0001 ether}(abi.encodeWithSignature("deposit()"));
            require(success, "Failed to get WETH");
            console.log("Deposited ETH to get WETH");
        }
        
        uint256 wethBalance = weth.balanceOf(msg.sender);
        console.log("Current WETH balance:", wethBalance);
        
        // Deploy a simple callback contract
        MinimalCallback callback = new MinimalCallback();
        console.log("Deployed callback at:", address(callback));
        
        // Transfer some WETH to callback for testing
        uint256 swapAmount = 0.00001 ether; // Very small amount
        weth.transfer(address(callback), swapAmount);
        console.log("Transferred", swapAmount, "WETH to callback");
        
        // Test the swap
        try callback.testSwap() {
            console.log("SUCCESS: Minimal swap worked!");
        } catch Error(string memory reason) {
            console.log("FAILED:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("FAILED with low-level error, data length:", lowLevelData.length);
            if (lowLevelData.length > 0 && lowLevelData.length <= 100) {
                console.logBytes(lowLevelData);
            }
        }
        
        vm.stopBroadcast();
    }
}

contract MinimalCallback is LiskConfig {
    
    function testSwap() external {
        console.log("=== CALLBACK TEST SWAP ===");
        
        IMinimalCLPool pool = IMinimalCLPool(WETH_wstETH_CL_POOL);
        IERC20Minimal weth = IERC20Minimal(WETH);
        
        uint256 swapAmount = weth.balanceOf(address(this));
        console.log("Callback WETH balance:", swapAmount);
        require(swapAmount > 0, "No WETH to swap");
        
        // Get current pool state
        (uint160 sqrtPriceX96, int24 tick,,,, uint8 feeProtocol, bool unlocked) = pool.slot0();
        console.log("Pool state:");
        console.log("- sqrtPriceX96:", sqrtPriceX96);
        console.log("- tick:", int256(tick));
        console.log("- feeProtocol:", uint256(feeProtocol));
        console.log("- unlocked:", unlocked);
        
        if (!unlocked) {
            console.log("ERROR: Pool is locked!");
            return;
        }
        
        // Approve WETH to pool
        weth.approve(WETH_wstETH_CL_POOL, swapAmount);
        console.log("Approved", swapAmount, "WETH to pool");
        
        // Calculate price limit (very generous for testing)
        uint160 minSqrtPriceX96 = sqrtPriceX96 / 2; // Allow 50% price movement
        
        console.log("Swap parameters:");
        console.log("- recipient:", address(this));
        console.log("- zeroForOne: true");
        console.log("- amountSpecified:", swapAmount);
        console.log("- sqrtPriceLimitX96:", minSqrtPriceX96);
        
        // Perform the swap
        (int256 amount0, int256 amount1) = pool.swap(
            address(this),           // recipient
            true,                   // zeroForOne (WETH -> wstETH)
            int256(swapAmount),     // amountSpecified (exact input)
            minSqrtPriceX96,        // sqrtPriceLimitX96 (generous limit)
            ""                      // data
        );
        
        console.log("Swap completed!");
        console.log("amount0 (WETH delta):", amount0);
        console.log("amount1 (wstETH delta):", amount1);
        
        // Check final balances
        uint256 finalWETH = weth.balanceOf(address(this));
        uint256 finalwstETH = IERC20Minimal(wstETH).balanceOf(address(this));
        console.log("Final WETH balance:", finalWETH);
        console.log("Final wstETH balance:", finalwstETH);
    }
    
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        console.log("=== CALLBACK CALLED ===");
        console.log("Caller:", msg.sender);
        console.log("Expected pool:", WETH_wstETH_CL_POOL);
        console.log("amount0Delta (WETH owed):", amount0Delta);
        console.log("amount1Delta (wstETH owed):", amount1Delta);
        
        require(msg.sender == WETH_wstETH_CL_POOL, "Invalid caller");
        
        // Pay what we owe to the pool
        if (amount0Delta > 0) {
            bool success = IERC20Minimal(WETH).transfer(msg.sender, uint256(amount0Delta));
            require(success, "WETH transfer failed");
            console.log("Paid", uint256(amount0Delta), "WETH to pool");
        }
        
        if (amount1Delta > 0) {
            bool success = IERC20Minimal(wstETH).transfer(msg.sender, uint256(amount1Delta));
            require(success, "wstETH transfer failed");
            console.log("Paid", uint256(amount1Delta), "wstETH to pool");
        }
        
        console.log("Callback completed successfully");
    }
}
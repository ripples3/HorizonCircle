// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IWETH {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IVelodromeCLPool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

/**
 * @title TestSwapMinimal
 * @notice Absolute minimal swap test to isolate the exact issue
 */
contract TestSwapMinimal is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== MINIMAL SWAP TEST ===");
        console.log("Using existing WETH from user");
        
        uint256 userWETH = IWETH(WETH).balanceOf(TEST_USER);
        console.log("User WETH balance:", userWETH);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Use a very small amount
        uint256 swapAmount = 1000000000000; // 0.000001 ETH
        console.log("Testing with amount:", swapAmount);
        
        // Transfer WETH to this contract for the callback
        IWETH(WETH).transfer(address(this), swapAmount);
        console.log("WETH transferred to contract");
        
        // Test 1: Try with no price limit (most permissive)
        console.log("\n=== TEST 1: NO PRICE LIMIT ===");
        try IVelodromeCLPool(POOL).swap(
            address(this),  // recipient
            true,           // zeroForOne (WETH -> wstETH)
            int256(swapAmount), // exact input
            0,              // no price limit
            ""              // no data
        ) returns (int256 amount0, int256 amount1) {
            console.log("SUCCESS: No price limit worked!");
            console.log("amount0:", vm.toString(amount0));
            console.log("amount1:", vm.toString(amount1));
        } catch Error(string memory reason) {
            console.log("FAILED:", reason);
        } catch (bytes memory) {
            console.log("FAILED: Low-level error");
        }
        
        // Transfer more for test 2
        IWETH(WETH).transfer(address(this), swapAmount);
        
        // Test 2: Try with recipient as msg.sender instead of address(this)
        console.log("\n=== TEST 2: DIFFERENT RECIPIENT ===");
        try IVelodromeCLPool(POOL).swap(
            msg.sender,     // recipient = msg.sender
            true,           // zeroForOne
            int256(swapAmount),
            0,              // no price limit
            ""
        ) returns (int256 amount0, int256 amount1) {
            console.log("SUCCESS: Different recipient worked!");
            console.log("amount0:", vm.toString(amount0));
            console.log("amount1:", vm.toString(amount1));
        } catch Error(string memory reason) {
            console.log("FAILED:", reason);
        } catch (bytes memory) {
            console.log("FAILED: Low-level error");
        }
        
        // Transfer more for test 3
        IWETH(WETH).transfer(address(this), swapAmount);
        
        // Test 3: Try negative amount (exact output instead of exact input)
        console.log("\n=== TEST 3: EXACT OUTPUT ===");
        try IVelodromeCLPool(POOL).swap(
            address(this),
            true,
            -int256(swapAmount/2), // negative for exact output
            0,
            ""
        ) returns (int256 amount0, int256 amount1) {
            console.log("SUCCESS: Exact output worked!");
            console.log("amount0:", vm.toString(amount0));
            console.log("amount1:", vm.toString(amount1));
        } catch Error(string memory reason) {
            console.log("FAILED:", reason);
        } catch (bytes memory) {
            console.log("FAILED: Low-level error");
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== MINIMAL TEST COMPLETE ===");
    }
    
    // Callback - just pay whatever is requested
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external {
        console.log("CALLBACK CALLED!");
        console.log("amount0Delta:", vm.toString(amount0Delta));
        console.log("amount1Delta:", vm.toString(amount1Delta));
        
        if (amount0Delta > 0) {
            console.log("Paying WETH:", uint256(amount0Delta));
            IWETH(WETH).transfer(POOL, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            console.log("ERROR: amount1Delta positive, shouldn't happen");
        }
    }
}
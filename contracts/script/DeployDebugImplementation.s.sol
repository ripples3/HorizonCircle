// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";
import "../src/HorizonCircleImplementation.sol";

contract DeployDebugImplementation is Script {
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING DEBUG IMPLEMENTATION FOR CL POOL ISSUE ===");
        
        // Create a debug version of the implementation with enhanced error reporting
        DebugImplementation debugImpl = new DebugImplementation();
        
        console.log("Debug implementation deployed:", address(debugImpl));
        
        // Deploy factory with debug implementation
        address REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC;
        
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            address(debugImpl)
        );
        
        console.log("Debug factory deployed:", address(factory));
        
        vm.stopBroadcast();
    }
}

contract DebugImplementation is HorizonCircleImplementation {
    
    // Override the _swapWETHToWstETH function to add debug info
    function _swapWETHToWstETH(uint256 wethAmount, uint256 minOut) internal returns (uint256 wstETHReceived) {
        console.log("DEBUG: Starting _swapWETHToWstETH");
        console.log("DEBUG: wethAmount =", wethAmount);
        console.log("DEBUG: minOut =", minOut);
        
        require(wethAmount > 0, "Invalid amount");
        
        IVelodromeCLPool pool = IVelodromeCLPool(WETH_wstETH_CL_POOL);
        
        // Approve WETH to pool
        weth.approve(WETH_wstETH_CL_POOL, wethAmount);
        console.log("DEBUG: Approved WETH to pool");
        
        // Get current pool state for price limit calculation
        console.log("DEBUG: Getting pool state...");
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        console.log("DEBUG: sqrtPriceX96 =", sqrtPriceX96);
        
        // Calculate safe price limits (industry standard MEV protection)
        uint256 slippageBps = MAX_SLIPPAGE; // 50 = 0.5%
        uint160 priceDelta = uint160((uint256(sqrtPriceX96) * slippageBps) / BASIS_POINTS);
        
        // WETH is token0, wstETH is token1 (based on addresses: WETH < wstETH)
        bool zeroForOne = true; // WETH -> wstETH
        uint160 sqrtPriceLimitX96 = sqrtPriceX96 - priceDelta; // Allow price to move down when selling WETH
        
        console.log("DEBUG: Calculated parameters:");
        console.log("DEBUG: - zeroForOne =", zeroForOne);
        console.log("DEBUG: - sqrtPriceLimitX96 =", sqrtPriceLimitX96);
        
        // Direct CL pool swap (required since router doesn't support CL pools)
        console.log("DEBUG: Calling pool.swap()...");
        try pool.swap(
            address(this),              // recipient
            zeroForOne,                 // zeroForOne (WETH -> wstETH)
            int256(wethAmount),         // amountSpecified (exact input)
            sqrtPriceLimitX96,          // sqrtPriceLimitX96 (MEV protection)
            ""                          // data (empty for simple swap)
        ) returns (int256 amount0, int256 amount1) {
            console.log("DEBUG: Swap successful!");
            console.log("DEBUG: amount0 =", amount0);
            console.log("DEBUG: amount1 =", amount1);
            
            // We sold token0 (WETH), received token1 (wstETH)
            wstETHReceived = uint256(-amount1);
            console.log("DEBUG: wstETHReceived =", wstETHReceived);
            
        } catch Error(string memory reason) {
            console.log("DEBUG: Swap failed with error:", reason);
            revert(string(abi.encodePacked("DEBUG CL pool swap failed: ", reason)));
        } catch (bytes memory lowLevelData) {
            console.log("DEBUG: Swap failed with low-level error");
            console.log("DEBUG: Error data length:", lowLevelData.length);
            if (lowLevelData.length > 0 && lowLevelData.length <= 100) {
                console.logBytes(lowLevelData);
            }
            revert("DEBUG CL pool swap failed with unknown error");
        }
        
        console.log("DEBUG: Checking slippage...");
        require(wstETHReceived >= minOut, "!slippage");
        console.log("DEBUG: _swapWETHToWstETH completed successfully");
        
        return wstETHReceived;
    }
}
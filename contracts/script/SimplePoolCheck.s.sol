// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiskConfig.sol";

contract SimplePoolCheck is Script, LiskConfig {
    
    function run() external view {
        console.log("=== SIMPLE POOL ACCESSIBILITY CHECK ===");
        console.log("Pool address:", WETH_wstETH_CL_POOL);
        
        // Check if there's any code at the pool address
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3)
        }
        console.log("Pool code size:", codeSize);
        
        if (codeSize == 0) {
            console.log("ERROR: No contract deployed at pool address!");
            return;
        }
        
        console.log("Pool has code - checking basic calls...");
        
        // Try to read basic pool information
        (bool success, bytes memory result) = WETH_wstETH_CL_POOL.staticcall(
            abi.encodeWithSignature("token0()")
        );
        
        if (success && result.length >= 32) {
            address token0 = abi.decode(result, (address));
            console.log("Pool token0:", token0);
            console.log("Expected WETH:", WETH);
            console.log("token0 == WETH?", token0 == WETH);
        } else {
            console.log("ERROR: Cannot read token0 from pool");
            console.log("Success:", success);
            console.log("Result length:", result.length);
        }
        
        (success, result) = WETH_wstETH_CL_POOL.staticcall(
            abi.encodeWithSignature("token1()")
        );
        
        if (success && result.length >= 32) {
            address token1 = abi.decode(result, (address));
            console.log("Pool token1:", token1);
            console.log("Expected wstETH:", wstETH);
            console.log("token1 == wstETH?", token1 == wstETH);
        } else {
            console.log("ERROR: Cannot read token1 from pool");
        }
        
        // Check if this is actually a CL pool
        (success, result) = WETH_wstETH_CL_POOL.staticcall(
            abi.encodeWithSignature("slot0()")
        );
        
        if (success) {
            console.log("Pool has slot0() function - this is a CL pool");
            if (result.length >= 32) {
                uint160 sqrtPriceX96 = abi.decode(result, (uint160));
                console.log("Current sqrtPriceX96:", sqrtPriceX96);
                console.log("Price > 0?", sqrtPriceX96 > 0);
            }
        } else {
            console.log("ERROR: Pool does not have slot0() - not a CL pool?");
        }
        
        // Check pool fee
        (success, result) = WETH_wstETH_CL_POOL.staticcall(
            abi.encodeWithSignature("fee()")
        );
        
        if (success && result.length >= 32) {
            uint24 fee = abi.decode(result, (uint24));
            console.log("Pool fee:", fee);
        } else {
            console.log("Cannot read pool fee");
        }
    }
}
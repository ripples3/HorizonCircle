// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiskConfig.sol";

contract VerifyPoolAddress is Script, LiskConfig {
    
    function run() external view {
        console.log("=== VERIFY POOL ADDRESS ON LISK MAINNET ===");
        console.log("Pool address:", WETH_wstETH_CL_POOL);
        console.log("WETH address:", WETH);
        console.log("wstETH address:", wstETH);
        
        // Check if contract exists at pool address
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3)
        }
        console.log("Contract code size:", codeSize);
        
        if (codeSize == 0) {
            console.log("ERROR: No contract at this address!");
            return;
        }
        
        // Try to call different pool functions to identify the interface
        console.log("\n=== TESTING DIFFERENT POOL INTERFACES ===");
        
        // Test standard UniV3 interface
        (bool success, bytes memory result) = WETH_wstETH_CL_POOL.staticcall(
            abi.encodeWithSignature("token0()")
        );
        
        if (success && result.length >= 32) {
            address token0 = abi.decode(result, (address));
            console.log("UniV3 token0():", token0);
            
            (success, result) = WETH_wstETH_CL_POOL.staticcall(
                abi.encodeWithSignature("token1()")
            );
            
            if (success && result.length >= 32) {
                address token1 = abi.decode(result, (address));
                console.log("UniV3 token1():", token1);
                console.log("Tokens match WETH/wstETH?", token0 == WETH && token1 == wstETH);
            }
        }
        
        // Test slot0() different ways
        console.log("\n=== TESTING SLOT0() VARIATIONS ===");
        
        // Try basic slot0()
        (success, result) = WETH_wstETH_CL_POOL.staticcall(
            abi.encodeWithSignature("slot0()")
        );
        console.log("slot0() success:", success);
        console.log("slot0() result length:", result.length);
        
        if (success && result.length >= 32) {
            uint160 sqrtPriceX96 = abi.decode(result, (uint160));
            console.log("sqrtPriceX96:", sqrtPriceX96);
        }
        
        // Try fee()
        (success, result) = WETH_wstETH_CL_POOL.staticcall(
            abi.encodeWithSignature("fee()")
        );
        if (success && result.length >= 32) {
            uint24 fee = abi.decode(result, (uint24));
            console.log("Pool fee:", fee);
        }
        
        // Try tickSpacing()
        (success, result) = WETH_wstETH_CL_POOL.staticcall(
            abi.encodeWithSignature("tickSpacing()")
        );
        if (success && result.length >= 32) {
            int24 tickSpacing = abi.decode(result, (int24));
            console.log("Tick spacing:", int256(tickSpacing));
        }
        
        // Try sqrtPriceX96() (alternative naming)
        (success, result) = WETH_wstETH_CL_POOL.staticcall(
            abi.encodeWithSignature("sqrtPriceX96()")
        );
        console.log("sqrtPriceX96() alternative success:", success);
        
        // Check if this might be a proxy
        console.log("\n=== CHECKING FOR PROXY PATTERN ===");
        
        // Check for proxy implementation slot
        bytes32 implementationSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        bytes32 implementation = vm.load(WETH_wstETH_CL_POOL, implementationSlot);
        if (implementation != bytes32(0)) {
            console.log("EIP-1967 implementation:", address(uint160(uint256(implementation))));
        }
        
        // Check for logic contract slot (common proxy pattern)
        bytes32 logicSlot = bytes32(uint256(0));
        bytes32 logic = vm.load(WETH_wstETH_CL_POOL, logicSlot);
        if (logic != bytes32(0)) {
            console.log("Logic contract at slot 0:", address(uint160(uint256(logic))));
        }
        
        console.log("\n=== ALTERNATIVE ADDRESSES TO TRY ===");
        console.log("If this pool address is incorrect, check:");
        console.log("1. Lisk Blockscout explorer for WETH/wstETH pools");
        console.log("2. Velodrome factory for CL pool creation events");
        console.log("3. Alternative pool addresses on Lisk mainnet");
    }
}
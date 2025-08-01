// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract TestProxyDebug is Script {
    address constant PROXY = 0x9F2d30Ea5135aF2B826c4E3df6794c0bA01B859a;
    address constant IMPLEMENTATION = 0xc4aF1079184D99C44bA299ab11B1c7d11Fa4Ec48;
    
    function run() external {
        console.log("=== DEBUGGING PROXY ISSUE ===");
        console.log("Proxy:", PROXY);
        console.log("Implementation:", IMPLEMENTATION);
        
        // Check proxy bytecode
        bytes memory proxyCode = address(PROXY).code;
        console.log("Proxy code length:", proxyCode.length);
        console.logBytes(proxyCode);
        
        // Check if proxy is pointing to implementation
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        bytes32 implSlot = vm.load(PROXY, slot);
        console.log("EIP1967 implementation slot:");
        console.logBytes32(implSlot);
        
        // For minimal proxy, check the hardcoded address at bytes 10-29
        if (proxyCode.length >= 45) {
            bytes20 hardcodedImpl;
            assembly {
                hardcodedImpl := mload(add(add(proxyCode, 0x20), 10))
            }
            console.log("Hardcoded implementation in proxy:");
            console.log(address(hardcodedImpl));
            
            if (address(hardcodedImpl) == IMPLEMENTATION) {
                console.log("SUCCESS: Proxy points to correct implementation");
            } else {
                console.log("ERROR: Proxy points to wrong implementation");
            }
        }
        
        console.log("=== PROXY DEBUG COMPLETE ===");
    }
}
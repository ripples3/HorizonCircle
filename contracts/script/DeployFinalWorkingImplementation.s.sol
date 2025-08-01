// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";
import "../src/HorizonCircleImplementation.sol";

contract DeployFinalWorkingImplementation is Script {
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING FINAL WORKING IMPLEMENTATION ===");
        
        // Deploy the latest implementation (should have working CL pool integration)  
        HorizonCircleImplementation implementation = new HorizonCircleImplementation();
        
        console.log("Final implementation deployed:", address(implementation));
        console.log("Implementation size:", type(HorizonCircleImplementation).creationCode.length, "bytes");
        
        // Deploy factory pointing to this implementation
        address REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC;
        
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            address(implementation)
        );
        
        console.log("Final factory deployed:", address(factory));
        
        vm.stopBroadcast();
        
        console.log("\n=== READY FOR FINAL TEST ===");
        console.log("Use this factory for the ultimate test:");
        console.log("Factory:", address(factory));
        console.log("Implementation:", address(implementation));
        console.log("Registry:", REGISTRY);
    }
}
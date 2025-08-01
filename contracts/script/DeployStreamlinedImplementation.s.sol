// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleStreamlined.sol";
import "../src/HorizonCircleMinimalProxy.sol";
import "../src/CircleRegistry.sol";

contract DeployStreamlinedImplementation is Script {
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING STREAMLINED HORIZONCIRCLE SYSTEM ===");
        console.log("Goal: Fix gas issues with simplified loan execution");
        
        // Deploy streamlined implementation
        HorizonCircleStreamlined implementation = new HorizonCircleStreamlined();
        console.log("Streamlined Implementation deployed:", address(implementation));
        
        // Deploy new registry for event-driven discovery
        CircleRegistry registry = new CircleRegistry();
        console.log("Registry deployed:", address(registry));
        
        // Deploy new factory pointing to streamlined implementation
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(address(registry), address(implementation));
        console.log("Streamlined Factory deployed:", address(factory));
        
        vm.stopBroadcast();
        
        console.log("\n=== STREAMLINED DEPLOYMENT COMPLETE ===");
        console.log("This implementation:");
        console.log("- Removes complex Morpho lending market integration");
        console.log("- Removes DEX swap complexity (direct WETH->ETH conversion)"); 
        console.log("- Focuses on core social lending functionality");
        console.log("- Should be under 20KB to avoid gas issues");
        console.log("- Maintains Morpho vault yield generation");
        
        console.log("\nProduction addresses:");
        console.log("- Streamlined Implementation:", address(implementation));
        console.log("- Streamlined Factory:", address(factory));
        console.log("- Registry:", address(registry));
        
        console.log("\nNext: Test with script/TestStreamlinedImplementation.s.sol");
    }
}
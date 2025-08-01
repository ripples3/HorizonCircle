// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleCore.sol";

contract DeployCircleImplementation is Script {
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Deploying HorizonCircleCore Implementation ===");
        
        // Deploy the actual circle implementation (not factory)
        HorizonCircleCore implementation = new HorizonCircleCore();
        
        console.log("HorizonCircleCore implementation deployed:", address(implementation));
        console.log("This is the ACTUAL circle implementation that should be used by factories");
        
        vm.stopBroadcast();
    }
}
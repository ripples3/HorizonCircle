// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SwapModule.sol";
import "../src/LendingModule.sol";

contract DeployModules is Script {
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING SWAP AND LENDING MODULES ===");
        console.log("Deployer:", msg.sender);
        
        // Deploy SwapModule
        SwapModule swapModule = new SwapModule();
        console.log("SwapModule deployed:", address(swapModule));
        
        // Deploy LendingModule
        LendingModule lendingModule = new LendingModule();
        console.log("LendingModule deployed:", address(lendingModule));
        
        console.log("");
        console.log("=== DEPLOYMENT COMPLETE ===");
        console.log("SwapModule:", address(swapModule));
        console.log("LendingModule:", address(lendingModule));
        console.log("Owner of both modules:", msg.sender);
        
        vm.stopBroadcast();
    }
}
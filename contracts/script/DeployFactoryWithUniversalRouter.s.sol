// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../script/DeployFactoryWithModules.s.sol";

contract DeployFactoryWithUniversalRouter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOY FACTORY WITH UNIVERSAL ROUTER ===" );
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Use verified contracts and Universal Router module
        address registry = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
        address implementation = 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56;
        address swapModule = 0xFb9c203bF7C0B00A1deb0C47b24156e3b9f6F49C; // Universal Router SwapModule
        address lendingModule = 0x96F582fAF5a1D61640f437EBea9758b18a678720;
        
        // Deploy Factory with Universal Router swap module
        HorizonCircleMinimalProxyWithModules factory = new HorizonCircleMinimalProxyWithModules(
            registry,
            implementation,
            swapModule,
            lendingModule
        );
        
        console.log("Factory:", address(factory));
        console.log("Registry:", registry);  
        console.log("Implementation:", implementation);
        console.log("Swap Module (Universal Router):", swapModule);
        console.log("Lending Module:", lendingModule);
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Factory now uses Universal Router for swaps");
        console.log("This is the industry standard approach");
    }
}
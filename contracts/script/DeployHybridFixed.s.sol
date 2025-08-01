// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleCore.sol";
import "../src/HorizonCircleModularFactory.sol";
import "../src/CircleRegistry.sol";

contract DeployHybridFixed is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== DEPLOYING HYBRID: FIXED CONTRIBUTION + WORKING DEFI ===");
        console.log("Deploying from:", vm.addr(deployerPrivateKey));
        
        // Deploy our FIXED implementation (with proper contribution logic)
        HorizonCircleCore implementation = new HorizonCircleCore();
        console.log("Fixed Implementation deployed:", address(implementation));
        
        // Use existing WORKING registry
        address workingRegistry = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
        console.log("Using existing working registry:", workingRegistry);
        
        // Deploy factory with FIXED implementation but will use WORKING modules
        HorizonCircleModularFactory factory = new HorizonCircleModularFactory(
            workingRegistry,
            address(implementation)
        );
        console.log("Hybrid Factory deployed:", address(factory));
        
        // Get the NEW modules (these should match the working ones)
        address newSwapModule = address(factory.swapModule());
        address newLendingModule = address(factory.lendingModule());
        
        console.log("New Swap Module:", newSwapModule);
        console.log("New Lending Module:", newLendingModule);
        
        // Compare with working modules
        console.log("\nComparison with working modules:");
        console.log("Working Swap Module:  0xe071b320B3Bf9Cd8a026A98cC59F3636272642b1");
        console.log("Working Lending Module: 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801");
        
        vm.stopBroadcast();
        
        console.log("\n=== HYBRID DEPLOYMENT COMPLETE ===");
        console.log("Result: FIXED contribution logic + should have working DeFi");
        console.log("- Factory:", address(factory));
        console.log("- Registry:", workingRegistry);
        console.log("- Implementation:", address(implementation));
        console.log("\nThis combines:");
        console.log("- Fixed contributeToRequest() that actually deducts shares");
        console.log("- executeRequest() without double deduction bug");
        console.log("- Fresh SwapModule and LendingModule (should be configured same as working ones)");
    }
}
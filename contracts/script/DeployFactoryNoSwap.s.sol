// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleNoSwap.sol";
import "../src/HorizonCircleMinimalProxyWithModules.sol";
import "../src/LendingModuleNoSwap.sol";

contract DeployFactoryNoSwap is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOY NO-SWAP FACTORY ===");
        console.log("This bypasses swap failures completely");
        console.log("Uses WETH directly as collateral");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy implementation that doesn't require swaps
        HorizonCircleNoSwap implementation = new HorizonCircleNoSwap();
        console.log("HorizonCircleNoSwap implementation:", address(implementation));
        
        // Use existing registry and lending module
        address registry = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
        address lendingModule = 0xe843ccdbd4f9694208f06aff3cb5bc8f228c7d48; // Our funded no-swap lending module
        address dummySwapModule = address(0x1); // Dummy address since we don't use it
        
        console.log("Using registry:", registry);
        console.log("Using lending module:", lendingModule);
        
        // Deploy factory with no-swap implementation
        HorizonCircleMinimalProxyWithModules factory = new HorizonCircleMinimalProxyWithModules(
            registry,
            address(implementation),
            dummySwapModule,    // Won't be used
            lendingModule
        );
        
        console.log("Factory deployed:", address(factory));
        
        vm.stopBroadcast();
        
        console.log("\\n=== DEPLOYMENT COMPLETE ===");
        console.log("Factory with no-swap implementation ready!");
        console.log("Users can now borrow ETH without swap failures!");
        console.log("\\n=== NEXT STEPS ===");
        console.log("1. Update frontend to use new factory address");
        console.log("2. Test complete flow with TestCompleteFlowNoSwap.s.sol");
    }
}
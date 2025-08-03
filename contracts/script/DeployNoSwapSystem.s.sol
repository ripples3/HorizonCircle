// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleNoSwap.sol";
import "../src/HorizonCircleMinimalProxyFactory.sol";

contract DeployNoSwapSystem is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOY NO-SWAP SYSTEM ===");
        console.log("This bypasses swap failures completely");
        console.log("Uses WETH directly as collateral");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy no-swap implementation
        HorizonCircleNoSwap implementation = new HorizonCircleNoSwap();
        console.log("HorizonCircleNoSwap implementation:", address(implementation));
        
        // Deploy simple factory with no-swap implementation  
        HorizonCircleMinimalProxyFactory factory = new HorizonCircleMinimalProxyFactory(
            address(implementation)
        );
        
        console.log("Factory deployed:", address(factory));
        
        vm.stopBroadcast();
        
        console.log("\\n=== DEPLOYMENT COMPLETE ===");
        console.log("Factory:", address(factory));
        console.log("Implementation:", address(implementation));
        console.log("Lending Module (already deployed):", "0xe843ccdbd4f9694208f06aff3cb5bc8f228c7d48");
        console.log("\\n=== AUTHORIZATION NEEDED ===");
        console.log("Run: cast send 0xe843ccdbd4f9694208f06aff3cb5bc8f228c7d48 'authorizeUser(address)' <CIRCLE_ADDRESS>");
        console.log("\\n=== NEXT STEPS ===");
        console.log("1. Create test circle with new factory");
        console.log("2. Authorize circle in lending module");  
        console.log("3. Test complete flow");
    }
}
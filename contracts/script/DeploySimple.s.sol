// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// Import contracts directly
import "../src/HorizonCircleWithMorphoAuth.sol";

contract DeploySimple is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOY IMPLEMENTATION ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Implementation
        HorizonCircleWithMorphoAuth implementation = new HorizonCircleWithMorphoAuth();
        console.log("Implementation:", address(implementation));
        
        vm.stopBroadcast();
        
        console.log("\nVERIFY:");
        console.log("forge verify-contract", address(implementation), "src/HorizonCircleWithMorphoAuth.sol:HorizonCircleWithMorphoAuth --rpc-url https://rpc.api.lisk.com --verifier blockscout --verifier-url https://blockscout.lisk.com/api --compiler-version 0.8.20");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SwapModuleSimple.sol";

contract DeployAndTestSimpleSwap is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOY & TEST SIMPLE SWAP MODULE ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy
        SwapModuleSimple swapModule = new SwapModuleSimple();
        console.log("SwapModuleSimple deployed:", address(swapModule));
        
        vm.stopBroadcast();
        
        console.log("\nNOTE: This module uses MIN price limit for maximum slippage tolerance");
        console.log("If this works, the issue is with price calculation");
        console.log("If this fails, the issue is with the callback or pool itself");
    }
}
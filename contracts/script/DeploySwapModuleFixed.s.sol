// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SwapModuleFixed.sol";

contract DeploySwapModuleFixed is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOY FIXED SWAP MODULE ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the fixed SwapModule
        SwapModuleFixed swapModule = new SwapModuleFixed();
        console.log("SwapModuleFixed deployed:", address(swapModule));
        console.log("Owner:", swapModule.owner());
        console.log("WETH Pool:", 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3);
        
        vm.stopBroadcast();
        
        console.log("\nDeployment complete!");
        console.log("SwapModule with fixed callback:", address(swapModule));
    }
}
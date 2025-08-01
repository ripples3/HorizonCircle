// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SwapModuleFixed.sol";

contract DeployFixedSwapModule is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== DEPLOYING FIXED SWAP MODULE ===");
        console.log("Deployer address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy fixed SwapModule
        SwapModuleFixed fixedSwapModule = new SwapModuleFixed();
        console.log("Fixed SwapModule deployed at:", address(fixedSwapModule));
        console.log("Fixed SwapModule owner:", fixedSwapModule.owner());
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Fixed SwapModule:", address(fixedSwapModule));
        console.log("Ready to test with improved callback handling");
    }
}
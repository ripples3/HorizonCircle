// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";

contract DeployFinalFactory is Script {
    address constant REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC; // Existing registry
    address constant FINAL_IMPLEMENTATION = 0x9b1490Ae6eC1b40D0de05cC4b52e0117A31997F7; // Single CL pool solution
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying FINAL Factory ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Registry:", REGISTRY);
        console.log("Implementation:", FINAL_IMPLEMENTATION);

        // Deploy final factory with corrected Universal Router implementation
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            FINAL_IMPLEMENTATION
        );
        console.log("Factory deployed at:", address(factory));

        vm.stopBroadcast();

        console.log("\n=== PRODUCTION DEPLOYMENT COMPLETE ===");
        console.log("REGISTRY:", REGISTRY);
        console.log("FACTORY:", address(factory));
        console.log("IMPLEMENTATION:", FINAL_IMPLEMENTATION);
        console.log("STATUS: Ready for user 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c testing");
    }
}
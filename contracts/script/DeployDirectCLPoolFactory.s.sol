// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";

contract DeployDirectCLPoolFactory is Script {
    address constant REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC; // Existing registry
    address constant DIRECT_CL_IMPLEMENTATION = 0xd61bF891484f9aB5cFbeF7c23c7d77D7e3Ce5297; // Direct CL pool solution
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying DIRECT CL POOL Factory ==");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Registry:", REGISTRY);
        console.log("Implementation:", DIRECT_CL_IMPLEMENTATION);

        // Deploy factory with direct CL pool implementation
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            DIRECT_CL_IMPLEMENTATION
        );
        console.log("Factory deployed at:", address(factory));

        vm.stopBroadcast();

        console.log("\n=== DIRECT CL POOL FACTORY DEPLOYMENT COMPLETE ===");
        console.log("REGISTRY:", REGISTRY);
        console.log("FACTORY:", address(factory));
        console.log("IMPLEMENTATION:", DIRECT_CL_IMPLEMENTATION);
        console.log("STATUS: Ready for user 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c testing with direct CL pool integration");
    }
}
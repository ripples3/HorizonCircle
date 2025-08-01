// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";

contract DeployFactoryWithFixedImplementation is Script {
    address constant REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC; // Existing registry
    address constant FIXED_IMPLEMENTATION = 0xD57e266A470f1af6b69B6287bAD2fd32b002aa12; // Fixed contribution accounting + industry standard CL pool
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying Factory with Fixed CL Implementation ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Registry:", REGISTRY);
        console.log("Implementation:", FIXED_IMPLEMENTATION);

        // Deploy factory pointing to fixed implementation
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            FIXED_IMPLEMENTATION
        );
        console.log("Factory deployed at:", address(factory));

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("REGISTRY:", REGISTRY);
        console.log("FACTORY:", address(factory));
        console.log("IMPLEMENTATION:", FIXED_IMPLEMENTATION);
    }
}
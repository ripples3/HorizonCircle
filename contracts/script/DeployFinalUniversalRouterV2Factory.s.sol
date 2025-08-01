// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";

contract DeployFinalUniversalRouterV2Factory is Script {
    address constant REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC; // Existing registry
    address constant UNIVERSAL_ROUTER_V2_IMPLEMENTATION = 0xF475545C89ab1b1cbE902E874294A316f66dFD00; // Universal Router V2 factory fix
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying FINAL UNIVERSAL ROUTER V2 FACTORY ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Registry:", REGISTRY);
        console.log("Implementation:", UNIVERSAL_ROUTER_V2_IMPLEMENTATION);

        // Deploy NEW factory with Universal Router V2 implementation
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            UNIVERSAL_ROUTER_V2_IMPLEMENTATION
        );
        console.log("NEW Factory deployed at:", address(factory));

        vm.stopBroadcast();

        console.log("\n=== FINAL UNIVERSAL ROUTER V2 FACTORY DEPLOYMENT COMPLETE ===");
        console.log("REGISTRY:", REGISTRY);
        console.log("FACTORY:", address(factory));
        console.log("IMPLEMENTATION:", UNIVERSAL_ROUTER_V2_IMPLEMENTATION);
        console.log("STATUS: Ready for final testing - correct factory/implementation separation");
    }
}
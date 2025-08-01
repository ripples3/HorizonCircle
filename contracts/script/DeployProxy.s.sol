// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleImplementation.sol";
import "../src/HorizonCircleMinimalProxy.sol";
import "../src/CircleRegistry.sol";

contract DeployProxy is Script {
    function run() external {
        // Handle both 0x-prefixed and non-prefixed private keys
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey;
        
        if (bytes(pkString).length > 2 && bytes(pkString)[0] == "0" && bytes(pkString)[1] == "x") {
            deployerPrivateKey = vm.parseUint(pkString);
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy implementation contract (only once)
        HorizonCircleImplementation implementation = new HorizonCircleImplementation();
        console.log("Implementation deployed at:", address(implementation));

        // 2. Deploy registry
        CircleRegistry registry = new CircleRegistry();
        console.log("Registry deployed at:", address(registry));

        // 3. Deploy proxy factory
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            address(registry),
            address(implementation)
        );
        console.log("Proxy Factory deployed at:", address(factory));

        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("Implementation (deploy once):", address(implementation));
        console.log("Registry (event discovery):", address(registry));
        console.log("Factory (minimal proxy):", address(factory));
        console.log("\n=== UPDATE FRONTEND CONFIG ===");
        console.log("REGISTRY:", address(registry));
        console.log("FACTORY:", address(factory));
    }
}
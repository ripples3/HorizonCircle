// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import "../src/CircleRegistry.sol";

contract DeployRegistryScript is Script {
    function run() public {
        // Handle private key
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey;
        
        if (bytes(pkString).length > 2 && bytes(pkString)[0] == "0" && bytes(pkString)[1] == "x") {
            deployerPrivateKey = vm.parseUint(pkString);
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console2.log("Deploying CircleRegistry (Industry Standard Pattern)...");
        console2.log("Deployer:", deployer);
        console2.log("ETH Balance:", deployer.balance / 1e18, "ETH");
        
        CircleRegistry registry = new CircleRegistry();
        
        console2.log("\nRegistry deployed at:", address(registry));
        console2.log("Initial circle count:", registry.getCircleCount());
        
        // Skip registering existing circles for clean testing environment
        console2.log("\nSkipping existing circle registration for clean testing...");
        
        vm.stopBroadcast();
        
        console2.log("\n=== Deployment Complete ===");
        console2.log("Industry standard registry pattern deployed!");
        console2.log("Users can now:");
        console2.log("1. Deploy HorizonCircle contracts directly");
        console2.log("2. Register them in the registry");
        console2.log("3. Frontend tracks all circles via registry");
    }
}
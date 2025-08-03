// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";

contract DeployFactory is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOY FACTORY ===" );
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Use verified contracts
        address registry = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
        address implementation = 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56;
        
        // Deploy Factory
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            registry,
            implementation
        );
        
        console.log("Factory:", address(factory));
        console.log("Registry:", registry);  
        console.log("Implementation:", implementation);
        
        vm.stopBroadcast();
        
        console.log("\nVERIFY:");
        console.log("Factory verification command:");
        console.log(address(factory));
        console.log(registry);
        console.log(implementation);
    }
}
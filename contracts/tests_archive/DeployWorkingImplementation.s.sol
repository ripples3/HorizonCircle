// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleImplementation.sol";

contract DeployWorkingImplementation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying WORKING Implementation (Under Size Limit) ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        // Deploy implementation - this should be under size limit
        HorizonCircleImplementation implementation = new HorizonCircleImplementation();
        console.log("Implementation deployed at:", address(implementation));
        
        // Test basic functionality
        console.log("WETH:", implementation.WETH());
        console.log("wstETH:", implementation.wstETH());
        console.log("VELODROME_ROUTER:", implementation.VELODROME_ROUTER());

        vm.stopBroadcast();

        console.log("\n=== WORKING IMPLEMENTATION DEPLOYED ===");
        console.log("IMPLEMENTATION:", address(implementation));
        console.log("STATUS: Ready for factory creation");
    }
}
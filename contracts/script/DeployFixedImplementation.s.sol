// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleImplementation.sol";

contract DeployFixedImplementation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying FIXED Implementation (Proxy-Friendly) ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        // Deploy fixed implementation with proxy-friendly initialization
        HorizonCircleImplementation implementation = new HorizonCircleImplementation();
        console.log("Fixed implementation deployed at:", address(implementation));
        
        // Test basic constants
        console.log("WETH:", implementation.WETH());
        console.log("VELODROME_ROUTER:", implementation.VELODROME_ROUTER());

        vm.stopBroadcast();

        console.log("\n=== PROXY-FRIENDLY IMPLEMENTATION DEPLOYED ===");
        console.log("IMPLEMENTATION:", address(implementation));
        console.log("STATUS: Ready for proxy testing");
    }
}
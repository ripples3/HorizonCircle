// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleImplementation.sol";

contract DeployBasisPointsFix is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying Implementation with Industry Standard Basis Points Fix ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        // Deploy new implementation with fixed basis points (10000 instead of 1000)
        HorizonCircleImplementation implementation = new HorizonCircleImplementation();
        console.log("Implementation deployed at:", address(implementation));
        
        // Verify the fix
        console.log("BASIS_POINTS:", implementation.BASIS_POINTS()); // Should be 10000
        console.log("MAX_SLIPPAGE:", implementation.MAX_SLIPPAGE()); // Should be 50 (0.5%)
        console.log("DEFAULT_LTV:", implementation.DEFAULT_LTV()); // Should be 8500 (85%)

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("IMPLEMENTATION:", address(implementation));
        console.log("Next: Update factory to point to this implementation");
    }
}
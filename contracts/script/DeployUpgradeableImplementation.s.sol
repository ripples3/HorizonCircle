// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleImplementation.sol";

contract DeployUpgradeableImplementation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying UPGRADEABLE Implementation (Fixed ReentrancyGuard) ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        // Deploy implementation with proper upgradeable ReentrancyGuard
        HorizonCircleImplementation implementation = new HorizonCircleImplementation();
        console.log("Upgradeable implementation deployed at:", address(implementation));
        
        // Test basic constants to verify deployment
        console.log("WETH:", implementation.WETH());
        console.log("VELODROME_ROUTER:", implementation.VELODROME_ROUTER());

        vm.stopBroadcast();

        console.log("\n=== UPGRADEABLE IMPLEMENTATION DEPLOYED ===");
        console.log("IMPLEMENTATION:", address(implementation));
        console.log("FIXES:");
        console.log("- Uses ReentrancyGuardUpgradeable for proper proxy support");
        console.log("- Proper __ReentrancyGuard_init() initialization");
        console.log("- All DEX integration features preserved");
        console.log("STATUS: Ready for proxy testing with full feature set");
    }
}
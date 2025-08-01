// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleImplementation.sol";

contract DeployOnlyImplementation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== Deploying ERC4626 Implementation Only ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        
        // Deploy just the implementation with ERC4626 fix
        HorizonCircleImplementation implementation = new HorizonCircleImplementation();
        
        console.log("Implementation deployed at:", address(implementation));
        console.log("=== ERC4626 previewWithdraw() fix included ===");
        
        vm.stopBroadcast();
    }
}
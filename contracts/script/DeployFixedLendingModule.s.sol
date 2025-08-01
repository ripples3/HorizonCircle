// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingModuleFixed.sol";

contract DeployFixedLendingModule is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== DEPLOYING FIXED LENDING MODULE ===");
        console.log("Using correct Morpho address: 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8");
        console.log("Using correct market ID: 0xaf10335b50689207d1fd37afd98e87aa0eb209c9074d8655642636223cc5f3a0");
        console.log("Deployer address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy fixed LendingModule
        LendingModuleFixed fixedLendingModule = new LendingModuleFixed();
        console.log("Fixed LendingModule deployed at:", address(fixedLendingModule));
        console.log("Fixed LendingModule owner:", fixedLendingModule.owner());
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Fixed LendingModule:", address(fixedLendingModule));
        console.log("Ready to test complete loan execution with both fixed modules");
    }
}
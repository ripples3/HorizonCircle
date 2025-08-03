// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingModuleNoSwap.sol";

contract DeployLendingModuleNoSwap is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOY LENDING MODULE NO SWAP ===");
        console.log("This module bypasses swap requirement");
        console.log("Uses WETH directly as collateral");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the no-swap lending module
        LendingModuleNoSwap lendingModule = new LendingModuleNoSwap();
        console.log("LendingModuleNoSwap deployed:", address(lendingModule));
        
        // Fund it with ETH so it can send to borrowers
        payable(address(lendingModule)).transfer(0.0001 ether);
        console.log("Funded with 0.0001 ETH");
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("This module will actually deliver ETH to borrowers!");
        console.log("No more swap failures blocking loans");
    }
}
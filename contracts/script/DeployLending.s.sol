// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingModuleSimplified.sol";

contract DeployLending is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOY LENDING MODULE ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Lending Module
        LendingModuleSimplified lendingModule = new LendingModuleSimplified();
        console.log("LendingModule:", address(lendingModule));
        
        // Fund it so users receive ETH
        payable(address(lendingModule)).transfer(0.0001 ether);
        console.log("Funded with 0.0001 ETH");
        
        vm.stopBroadcast();
        
        console.log("\nVERIFY:");
        console.log("forge verify-contract", address(lendingModule), "src/LendingModuleSimplified.sol:LendingModuleSimplified --rpc-url https://rpc.api.lisk.com --verifier blockscout --verifier-url https://blockscout.lisk.com/api --compiler-version 0.8.20");
    }
}
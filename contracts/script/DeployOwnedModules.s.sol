// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SwapModule.sol";
import "../src/LendingModule.sol";

contract DeployOwnedModules is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== DEPLOYING MODULES WITH OUR OWNERSHIP ===");
        console.log("Deployer address:", deployer);
        console.log("This deployer will be the owner of both modules");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy SwapModule
        SwapModule swapModule = new SwapModule();
        console.log("SwapModule deployed at:", address(swapModule));
        console.log("SwapModule owner:", swapModule.owner());
        
        // Deploy LendingModule  
        LendingModule lendingModule = new LendingModule();
        console.log("LendingModule deployed at:", address(lendingModule));
        console.log("LendingModule owner:", lendingModule.owner());
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("New SwapModule:", address(swapModule));
        console.log("New LendingModule:", address(lendingModule));
        console.log("Both modules owned by:", deployer);
        console.log("\nNext steps:");
        console.log("1. Update contracts to use these new module addresses");
        console.log("2. Authorize circles to use these modules");
        console.log("3. Test complete loan execution flow");
        
        // Immediately authorize our test circles
        console.log("\n=== AUTHORIZING TEST CIRCLES ===");
        
        address selfFundedCircle = 0x278Bd6D9858993C8F6C0f458fDE5Cb74A9989b4B;
        address socialCircle = 0x42763dE10Cc0fAE0DA120F046cC3834d5AccDBF9;
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Pre-authorize our test circles
        swapModule.authorizeCircle(selfFundedCircle);
        swapModule.authorizeCircle(socialCircle);
        lendingModule.authorizeCircle(selfFundedCircle);
        lendingModule.authorizeCircle(socialCircle);
        
        vm.stopBroadcast();
        
        console.log("Authorized circles:");
        console.log("- Self-funded circle:", selfFundedCircle);
        console.log("- Social circle:", socialCircle);
        console.log("Both circles can now execute loans!");
        
        // Verify authorization
        console.log("\n=== VERIFICATION ===");
        console.log("Self-funded swap authorized:", swapModule.authorizedCallers(selfFundedCircle));
        console.log("Self-funded lending authorized:", lendingModule.authorizedCallers(selfFundedCircle));
        console.log("Social swap authorized:", swapModule.authorizedCallers(socialCircle));
        console.log("Social lending authorized:", lendingModule.authorizedCallers(socialCircle)); 
        
        console.log("\nSUCCESS: Ready for complete loan execution testing!");
    }
}
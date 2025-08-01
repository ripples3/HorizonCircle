// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface ISwapModule {
    function owner() external view returns (address);
    function authorizeCircle(address circle) external;
    function authorizedCallers(address circle) external view returns (bool);
}

interface ILendingModule {
    function owner() external view returns (address);
    function authorizeCircle(address circle) external;
    function authorizedCallers(address circle) external view returns (bool);
}

contract AuthorizeModules is Script {
    address constant SWAP_MODULE = 0xFCb88eEA3643e373075d4017748C8CD2861972ED;
    address constant LENDING_MODULE = 0xF5D0DfED1C0894064018144D79B919d861B2aAbF;
    
    // Test circles from recent testing
    address constant SELF_FUNDED_CIRCLE = 0x278Bd6D9858993C8F6C0f458fDE5Cb74A9989b4B;
    address constant SOCIAL_CIRCLE = 0x42763dE10Cc0fAE0DA120F046cC3834d5AccDBF9;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== MODULE AUTHORIZATION SCRIPT ===");
        console.log("Deployer address:", deployer);
        
        // Check module ownership
        ISwapModule swapModule = ISwapModule(SWAP_MODULE);
        ILendingModule lendingModule = ILendingModule(LENDING_MODULE);
        
        address swapOwner = swapModule.owner();
        address lendingOwner = lendingModule.owner();
        
        console.log("\n=== MODULE OWNERSHIP ===");
        console.log("SwapModule owner:", swapOwner);
        console.log("LendingModule owner:", lendingOwner);
        console.log("Are you the owner?", swapOwner == deployer && lendingOwner == deployer);
        
        // Check current authorization status
        console.log("\n=== CURRENT AUTHORIZATION STATUS ===");
        bool selfFundedSwapAuth = swapModule.authorizedCallers(SELF_FUNDED_CIRCLE);
        bool selfFundedLendingAuth = lendingModule.authorizedCallers(SELF_FUNDED_CIRCLE);
        bool socialSwapAuth = swapModule.authorizedCallers(SOCIAL_CIRCLE);
        bool socialLendingAuth = lendingModule.authorizedCallers(SOCIAL_CIRCLE);
        
        console.log("Self-funded circle swap authorized:", selfFundedSwapAuth);
        console.log("Self-funded circle lending authorized:", selfFundedLendingAuth);
        console.log("Social circle swap authorized:", socialSwapAuth);
        console.log("Social circle lending authorized:", socialLendingAuth);
        
        // Only proceed if we're the owner
        if (swapOwner != deployer || lendingOwner != deployer) {
            console.log("\n=== AUTHORIZATION FAILED ===");
            console.log("You are not the owner of the modules!");
            console.log("The module owner needs to run this script or manually authorize the circles");
            return;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Authorize self-funded circle
        if (!selfFundedSwapAuth) {
            console.log("\nAuthorizing self-funded circle for swap module...");
            swapModule.authorizeCircle(SELF_FUNDED_CIRCLE);
            console.log("SUCCESS: Self-funded circle authorized for swaps");
        }
        
        if (!selfFundedLendingAuth) {
            console.log("Authorizing self-funded circle for lending module...");
            lendingModule.authorizeCircle(SELF_FUNDED_CIRCLE);
            console.log("SUCCESS: Self-funded circle authorized for lending");
        }
        
        // Authorize social circle
        if (!socialSwapAuth) {
            console.log("\nAuthorizing social circle for swap module...");
            swapModule.authorizeCircle(SOCIAL_CIRCLE);
            console.log("SUCCESS: Social circle authorized for swaps");
        }
        
        if (!socialLendingAuth) {
            console.log("Authorizing social circle for lending module...");
            lendingModule.authorizeCircle(SOCIAL_CIRCLE);
            console.log("SUCCESS: Social circle authorized for lending");
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== AUTHORIZATION COMPLETE ===");
        console.log("Both circles are now authorized to use swap and lending modules");
        console.log("You can now test the complete loan execution flow!");
        
        // Verify final state
        console.log("\n=== FINAL VERIFICATION ===");
        console.log("Self-funded circle swap:", swapModule.authorizedCallers(SELF_FUNDED_CIRCLE));
        console.log("Self-funded circle lending:", lendingModule.authorizedCallers(SELF_FUNDED_CIRCLE));
        console.log("Social circle swap:", swapModule.authorizedCallers(SOCIAL_CIRCLE));
        console.log("Social circle lending:", lendingModule.authorizedCallers(SOCIAL_CIRCLE));
    }
}
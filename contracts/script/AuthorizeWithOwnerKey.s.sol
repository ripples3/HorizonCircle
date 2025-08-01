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

contract AuthorizeWithOwnerKey is Script {
    address constant SWAP_MODULE = 0xFCb88eEA3643e373075d4017748C8CD2861972ED;
    address constant LENDING_MODULE = 0xF5D0DfED1C0894064018144D79B919d861B2aAbF;
    
    // Test circles from recent testing
    address constant SELF_FUNDED_CIRCLE = 0x278Bd6D9858993C8F6C0f458fDE5Cb74A9989b4B;
    address constant SOCIAL_CIRCLE = 0x42763dE10Cc0fAE0DA120F046cC3834d5AccDBF9;
    
    function run() external {
        // Use MODULE_OWNER_PRIVATE_KEY if available, otherwise fall back to PRIVATE_KEY
        uint256 moduleOwnerPrivateKey;
        try vm.envUint("MODULE_OWNER_PRIVATE_KEY") returns (uint256 key) {
            moduleOwnerPrivateKey = key;
        } catch {
            moduleOwnerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        
        address moduleOwner = vm.addr(moduleOwnerPrivateKey);
        
        console.log("=== MODULE AUTHORIZATION WITH OWNER KEY ===");
        console.log("Using address:", moduleOwner);
        
        // Check if this is the correct owner
        ISwapModule swapModule = ISwapModule(SWAP_MODULE);
        ILendingModule lendingModule = ILendingModule(LENDING_MODULE);
        
        address swapOwner = swapModule.owner();
        address lendingOwner = lendingModule.owner();
        
        console.log("Expected owner:", swapOwner);
        console.log("Are we the owner?", swapOwner == moduleOwner && lendingOwner == moduleOwner);
        
        if (swapOwner != moduleOwner || lendingOwner != moduleOwner) {
            console.log("\n=== AUTHORIZATION FAILED ===");
            console.log("The key provided is not the module owner!");
            console.log("Expected owner:", swapOwner);
            console.log("Provided address:", moduleOwner);
            console.log("Set MODULE_OWNER_PRIVATE_KEY environment variable with the correct private key");
            return;
        }
        
        // Check current status
        console.log("\n=== CURRENT STATUS ===");
        bool selfFundedSwapAuth = swapModule.authorizedCallers(SELF_FUNDED_CIRCLE);
        bool selfFundedLendingAuth = lendingModule.authorizedCallers(SELF_FUNDED_CIRCLE);
        bool socialSwapAuth = swapModule.authorizedCallers(SOCIAL_CIRCLE);
        bool socialLendingAuth = lendingModule.authorizedCallers(SOCIAL_CIRCLE);
        
        console.log("Self-funded circle swap authorized:", selfFundedSwapAuth);
        console.log("Self-funded circle lending authorized:", selfFundedLendingAuth);
        console.log("Social circle swap authorized:", socialSwapAuth);
        console.log("Social circle lending authorized:", socialLendingAuth);
        
        vm.startBroadcast(moduleOwnerPrivateKey);
        
        // Authorize circles
        if (!selfFundedSwapAuth) {
            console.log("\nAuthorizing self-funded circle for swaps...");
            swapModule.authorizeCircle(SELF_FUNDED_CIRCLE);
        }
        
        if (!selfFundedLendingAuth) {
            console.log("Authorizing self-funded circle for lending...");
            lendingModule.authorizeCircle(SELF_FUNDED_CIRCLE);
        }
        
        if (!socialSwapAuth) {
            console.log("Authorizing social circle for swaps...");
            swapModule.authorizeCircle(SOCIAL_CIRCLE);
        }
        
        if (!socialLendingAuth) {
            console.log("Authorizing social circle for lending...");
            lendingModule.authorizeCircle(SOCIAL_CIRCLE);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== AUTHORIZATION COMPLETE! ===");
        console.log("Both circles are now authorized for complete loan execution");
        
        // Final verification
        console.log("\n=== VERIFICATION ===");
        console.log("Self-funded swap:", swapModule.authorizedCallers(SELF_FUNDED_CIRCLE));
        console.log("Self-funded lending:", lendingModule.authorizedCallers(SELF_FUNDED_CIRCLE));
        console.log("Social swap:", swapModule.authorizedCallers(SOCIAL_CIRCLE));
        console.log("Social lending:", lendingModule.authorizedCallers(SOCIAL_CIRCLE));
        
        console.log("\n🎉 SUCCESS: Ready to test complete loan execution flow!");
    }
}
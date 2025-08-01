// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface ISwapModule {
    function authorizedCallers(address) external view returns (bool);
    function owner() external view returns (address);
}

interface ILendingModule {
    function authorizedCallers(address) external view returns (bool);
    function owner() external view returns (address);
}

interface IFactory {
    function swapModule() external view returns (address);
    function lendingModule() external view returns (address);
}

contract CheckAuthorization is Script {
    address constant FACTORY = 0x6b51Cb6Cc611b7415b951186E9641aFc87Df77DB;
    address constant TEST_CIRCLE = 0xecE652E6b2B74f06C8B2b0EBfEc4401e75312Cd4; // From our test
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external view {
        console.log("=== CHECKING AUTHORIZATION STATUS ===");
        console.log("Factory:", FACTORY);
        console.log("Test Circle:", TEST_CIRCLE);
        console.log("User:", USER);
        
        // Get module addresses
        address swapModule = IFactory(FACTORY).swapModule();
        address lendingModule = IFactory(FACTORY).lendingModule();
        
        console.log("\nModule Addresses:");
        console.log("SwapModule:", swapModule);
        console.log("LendingModule:", lendingModule);
        
        // Check module owners
        address swapOwner = ISwapModule(swapModule).owner();
        address lendingOwner = ILendingModule(lendingModule).owner();
        
        console.log("\nModule Owners:");
        console.log("SwapModule owner:", swapOwner);
        console.log("LendingModule owner:", lendingOwner);
        console.log("Factory address:", FACTORY);
        console.log("User address:", USER);
        
        // Check if circle is authorized
        bool swapAuthorized = ISwapModule(swapModule).authorizedCallers(TEST_CIRCLE);
        bool lendingAuthorized = ILendingModule(lendingModule).authorizedCallers(TEST_CIRCLE);
        
        console.log("\nAuthorization Status for Test Circle:");
        console.log("SwapModule authorized:", swapAuthorized);
        console.log("LendingModule authorized:", lendingAuthorized);
        
        if (swapAuthorized && lendingAuthorized) {
            console.log("\nSUCCESS: Circle is properly authorized!");
            console.log("The DeFi failure must be something else...");
        } else {
            console.log("\nPROBLEM FOUND: Circle is NOT authorized!");
            console.log("This explains why executeRequest() fails");
            
            if (swapOwner == FACTORY) {
                console.log("Factory should have authorized the circle automatically");
                console.log("There might be a bug in the factory authorization logic");
            } else {
                console.log("Modules are not owned by factory - manual authorization needed");
            }
        }
        
        console.log("\n=== AUTHORIZATION CHECK COMPLETE ===");
    }
}
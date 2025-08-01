// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IMorphoAuth {
    function setAuthorization(address authorized, bool newIsAuthorized) external;
    function isAuthorized(address authorizer, address authorized) external view returns (bool);
}

contract TestMorphoAuthorization is Script {
    address constant MORPHO = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    address constant CIRCLE = 0x2e7fD1f7A32697d131F16547fFfd84E57945d73E; // From previous test
    address constant LENDING_MODULE = 0xB5fe149c80235fAb970358543EEce1C800FDcA64; // From previous test
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING MORPHO AUTHORIZATION ===");
        console.log("Circle:", CIRCLE);
        console.log("Lending Module:", LENDING_MODULE);
        
        IMorphoAuth morpho = IMorphoAuth(MORPHO);
        
        // Check current authorization status
        console.log("\\n=== CURRENT AUTHORIZATION STATUS ===");
        try morpho.isAuthorized(CIRCLE, LENDING_MODULE) returns (bool isAuth) {
            console.log("Is lending module authorized by circle:", isAuth);
            
            if (!isAuth) {
                console.log("ISSUE: Lending module not authorized by circle");
                console.log("SOLUTION: Circle must call setAuthorization()");
                
                vm.startBroadcast(deployerPrivateKey);
                
                // The circle needs to authorize the lending module
                // Note: This would need to be called FROM the circle address
                console.log("\\n=== ATTEMPTING AUTHORIZATION ===");
                console.log("Circle needs to authorize lending module...");
                
                // This is the call that the CIRCLE needs to make:
                // morpho.setAuthorization(LENDING_MODULE, true);
                
                console.log("\\nREQUIRED ACTION:");
                console.log("The circle contract needs to call:");
                console.log("morpho.setAuthorization(lendingModule, true)");
                console.log("This allows lending module to borrow on behalf of circle");
                
                vm.stopBroadcast();
            } else {
                console.log("Authorization already set - should work");
            }
            
        } catch {
            console.log("Cannot check authorization - function might not exist");
        }
        
        console.log("\\n=== MORPHO BLUE AUTHORIZATION PATTERN ===");
        console.log("1. Circle supplies collateral to Morpho (WORKING)");
        console.log("2. Circle authorizes lending module: setAuthorization(lendingModule, true)");
        console.log("3. Lending module can then borrow on behalf of circle");
        console.log("4. This is standard Morpho Blue delegation pattern");
        
        console.log("\\n=== IMPLEMENTATION NEEDED ===");
        console.log("Add to lending module initialization:");
        console.log("- Circle calls morpho.setAuthorization(address(this), true)");
        console.log("- This authorizes lending module to manage circle's position");
    }
}
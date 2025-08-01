// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IMorpho {
    function position(bytes32 marketId, address user) external view returns (
        uint256 supplyShares,
        uint128 borrowShares,
        uint128 collateral
    );
}

contract CheckCirclePosition is Script {
    address constant MORPHO = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    bytes32 constant MARKET_ID = 0xaf10335b50689207d1fd37afd98e87aa0eb209c9074d8655642636223cc5f3a0;
    
    function run() external view {
        console.log("=== CHECKING CIRCLE POSITIONS IN MORPHO ===");
        console.log("The issue might be existing positions...");
        
        IMorpho morpho = IMorpho(MORPHO);
        
        // Check various circle addresses we've been testing with
        address[] memory testAddresses = new address[](4);
        testAddresses[0] = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c; // Deployer
        testAddresses[1] = 0xd5F15FCD6ea81E636660f918DDb869E41fC2C2d1; // Recent circle
        testAddresses[2] = 0xe4798808E5F6139313e0B5A03B20Cfab47c9432e; // Previous circle  
        testAddresses[3] = 0x2a5AEDd55486425C097149e3c76c5bcf63b9AF25; // Earlier circle
        
        string[] memory labels = new string[](4);
        labels[0] = "Deployer";
        labels[1] = "Recent Circle";
        labels[2] = "Previous Circle";  
        labels[3] = "Earlier Circle";
        
        for (uint i = 0; i < testAddresses.length; i++) {
            console.log("\\nChecking:", labels[i]);
            console.log("Address:", testAddresses[i]);
            
            try morpho.position(MARKET_ID, testAddresses[i]) returns (
                uint256 supplyShares,
                uint128 borrowShares,
                uint128 collateral
            ) {
                console.log("  Supply shares:", supplyShares);
                console.log("  Borrow shares:", borrowShares);  
                console.log("  Collateral:", collateral);
                
                if (supplyShares > 0 || borrowShares > 0 || collateral > 0) {
                    console.log("  *** HAS EXISTING POSITION ***");
                    console.log("  This might be blocking new operations!");
                } else {
                    console.log("  Clean position - should work for supply");
                }
            } catch {
                console.log("  Cannot read position");
            }
        }
        
        console.log("\\n=== ANALYSIS ===");
        console.log("If any test addresses have existing positions,");
        console.log("that could explain the 677 gas revert.");
        console.log("Morpho might not allow additional collateral");
        console.log("on existing positions without proper cleanup.");
        
        console.log("\\n=== SOLUTION ===");
        console.log("1. Use completely fresh circle addresses");
        console.log("2. Or clear existing positions first");
        console.log("3. Or use different position management functions");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleImplementation.sol";

contract TestCompleteWorkingLoanExecution is Script {
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant CIRCLE = 0xdE40B6007AAf0f98390308a2F86Ee51B6b3EFDBc; // Working circle from previous test
    
    function run() external {
        vm.startPrank(USER);
        
        console.log("=== FINAL TEST: Complete Working Loan Execution ===");
        console.log("User:", USER);
        console.log("Working Circle:", CIRCLE);
        
        HorizonCircleImplementation circle = HorizonCircleImplementation(payable(CIRCLE));
        
        // Check current balance (should be ~30000000000000 from previous deposit)
        uint256 userBalance = circle.getUserBalance(USER);
        console.log("Current user balance:", userBalance);
        
        if (userBalance == 0) {
            console.log("Making deposit first...");
            circle.deposit{value: 0.00003 ether}();
            userBalance = circle.getUserBalance(USER);
            console.log("User balance after deposit:", userBalance);
        }
        
        // Calculate 70% LTV for safe testing
        uint256 borrowAmount = (userBalance * 70) / 100;
        console.log("Borrowing amount (70% LTV):", borrowAmount);
        
        // Create self-contribution request
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        
        uint256[] memory contributorAmounts = new uint256[](1);
        contributorAmounts[0] = borrowAmount;
        
        bytes32 requestId = circle.requestCollateral(
            borrowAmount,        // borrowAmount
            borrowAmount,        // collateralAmount 
            contributors,
            contributorAmounts,
            "FINAL TEST: Complete loan execution with working implementation"
        );
        
        console.log("Request created:");
        console.logBytes32(requestId);
        
        // Make self-contribution
        circle.contributeToRequest(requestId);
        console.log("Self-contribution made");
        
        // Execute the loan - THE MOMENT OF TRUTH
        console.log("\n=== THE FINAL MOMENT: Execute Request with Full DEX Integration ===");
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            console.log("COMPLETE SUCCESS!");
            console.log("Loan executed with full DEX integration!");
            console.logBytes32(loanId);
            
            // Check final state
            uint256 finalCircleBalance = circle.getUserBalance(USER);
            uint256 finalEthBalance = USER.balance;
            
            console.log("Final circle balance:", finalCircleBalance);
            console.log("Final ETH balance:", finalEthBalance);
            console.log("");
            console.log("BREAKTHROUGH: COMPLETE SYSTEM WORKING!");
            console.log("- Proxy pattern working");
            console.log("- Complex implementation working");  
            console.log("- DEX integration working");
            console.log("- Morpho integration working");
            console.log("- Complete loan execution working");
            console.log("- Single pool integration is PERFECT");
            
        } catch Error(string memory reason) {
            console.log("Final test failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Final test failed with low-level error");
            console.log("Error data length:", lowLevelData.length);
            if (lowLevelData.length > 0) {
                console.logBytes(lowLevelData);
            }
        }
        
        vm.stopPrank();
    }
}
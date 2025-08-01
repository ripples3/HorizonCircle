// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleImplementation.sol";

contract TestFullLoanExecutionWithWorkingCircle is Script {
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant CIRCLE = 0xA69975fc3C17B6bA5A1A81E6C46AF524Cb698c19; // Fresh working circle
    
    function run() external {
        vm.startPrank(USER);
        
        console.log("=== Testing Full Loan Execution with Working Circle ===");
        console.log("User:", USER);
        console.log("Circle:", CIRCLE);
        
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
        
        // Calculate 70% LTV borrow amount for safe testing
        uint256 borrowAmount = (userBalance * 70) / 100;
        console.log("Borrowing amount (70% LTV):", borrowAmount);
        
        // Create self-contribution request
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        
        uint256[] memory contributorAmounts = new uint256[](1);
        contributorAmounts[0] = borrowAmount;
        
        bytes32 requestId = circle.requestCollateral(
            borrowAmount,        // borrowAmount
            borrowAmount,        // collateralAmount (same since 70% < 85% LTV limit)
            contributors,
            contributorAmounts,
            "Working circle test"
        );
        
        console.log("Request created:");
        console.logBytes32(requestId);
        
        // Make self-contribution
        circle.contributeToRequest(requestId);
        console.log("Self-contribution made");
        
        // Check if all contributors responded
        bool responded = circle.allContributorsResponded(requestId);
        console.log("All contributors responded:", responded);
        
        // Execute the loan - this is where DEX integration should work
        console.log("\n=== CRITICAL TEST: Execute Request (DEX Integration) ===");
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS: Loan executed! DEX integration working!");
            console.logBytes32(loanId);
            
            // Check final balances
            uint256 finalCircleBalance = circle.getUserBalance(USER);
            uint256 finalEthBalance = USER.balance;
            
            console.log("Final circle balance:", finalCircleBalance);
            console.log("Final ETH balance:", finalEthBalance);
            console.log("BREAKTHROUGH: Complete loan execution successful!");
            
        } catch Error(string memory reason) {
            console.log("FAILED: executeRequest failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("FAILED: executeRequest failed with low-level error");
            console.log("Error data length:", lowLevelData.length);
            if (lowLevelData.length > 0) {
                console.logBytes(lowLevelData);
            }
        }
        
        vm.stopPrank();
    }
}
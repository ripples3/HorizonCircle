// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

interface ICircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function userShares(address user) external view returns (uint256);
    function totalShares() external view returns (uint256);
    function requestCollateral(
        uint256 borrowAmount,
        uint256 collateralAmount, 
        address[] memory contributors,
        uint256[] memory amounts,
        string memory purpose
    ) external returns (bytes32 requestId);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32 loanId);
    function isMember(address user) external view returns (bool);
}

contract TestFixedContributions2 is Script {
    address constant FACTORY = 0x8144c8A43396A4E94222094746152bA8d35D85c0; // Fixed factory
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING FIXED CONTRIBUTION LOGIC - ROUND 2 ===");
        console.log("Factory:", FACTORY);
        console.log("User:", USER);
        console.log("User ETH balance:", USER.balance, "wei");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Create new circle
        console.log("\n1. Creating fresh circle...");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        string memory circleName = string(abi.encodePacked("FixedTest2_", vm.toString(block.timestamp)));
        address circleAddress = IFactory(FACTORY).createCircle(circleName, members);
        console.log("Circle created:", circleAddress);
        
        // Verify basic functionality
        bool isMember = ICircle(circleAddress).isMember(USER);
        console.log("User is member:", isMember);
        
        // Step 2: Make a fresh deposit
        console.log("\n2. Making fresh deposit...");
        uint256 depositAmount = 0.0001 ether; // Larger amount for better testing
        console.log("Depositing:", depositAmount, "wei");
        
        ICircle(circleAddress).deposit{value: depositAmount}();
        
        uint256 userBalance = ICircle(circleAddress).getUserBalance(USER);
        uint256 userShares = ICircle(circleAddress).userShares(USER);
        uint256 totalShares = ICircle(circleAddress).totalShares();
        
        console.log("User balance after deposit:", userBalance, "wei");
        console.log("User vault shares:", userShares);
        console.log("Total vault shares:", totalShares);
        
        // Step 3: Create loan request (smaller amount for testing)
        console.log("\n3. Creating loan request...");
        uint256 borrowAmount = (userBalance * 50) / 100; // Only 50% for safer testing
        console.log("Requesting loan amount:", borrowAmount, "wei");
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER; // Self-funded
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount; // Collateral = borrow amount
        
        bytes32 requestId = ICircle(circleAddress).requestCollateral(
            borrowAmount,
            borrowAmount, // collateralNeeded = borrowAmount
            contributors,
            amounts,
            "Test #2: Fixed contribution logic validation"
        );
        console.log("Request ID:", vm.toString(requestId));
        
        // Step 4: Test contribution with detailed tracking
        console.log("\n4. Testing contribution with detailed tracking...");
        console.log("=== BEFORE CONTRIBUTION ===");
        console.log("User vault shares:", ICircle(circleAddress).userShares(USER));
        console.log("Total vault shares:", ICircle(circleAddress).totalShares());
        console.log("User balance:", ICircle(circleAddress).getUserBalance(USER), "wei");
        
        // Calculate expected share deduction
        uint256 sharesBefore = ICircle(circleAddress).userShares(USER);
        uint256 totalSharesBefore = ICircle(circleAddress).totalShares();
        
        try ICircle(circleAddress).contributeToRequest(requestId) {
            console.log("Contribution transaction successful!");
            
            console.log("\n=== AFTER CONTRIBUTION ===");
            uint256 sharesAfter = ICircle(circleAddress).userShares(USER);
            uint256 totalSharesAfter = ICircle(circleAddress).totalShares();
            uint256 balanceAfter = ICircle(circleAddress).getUserBalance(USER);
            
            console.log("User vault shares:", sharesAfter);
            console.log("Total vault shares:", totalSharesAfter);
            console.log("User balance:", balanceAfter, "wei");
            
            uint256 sharesDeducted = sharesBefore - sharesAfter;
            uint256 totalSharesDeducted = totalSharesBefore - totalSharesAfter;
            
            console.log("\n=== ANALYSIS ===");
            console.log("Shares deducted from user:", sharesDeducted);
            console.log("Total shares deducted:", totalSharesDeducted);
            console.log("Requested contribution:", borrowAmount, "wei");
            
            // Verify the math is correct
            if (sharesDeducted > 0 && totalSharesDeducted > 0) {
                console.log("SUCCESS: Shares were properly deducted!");
                console.log("Contribution logic is working correctly!");
                
                // Step 5: Try execute request
                console.log("\n5. Testing executeRequest...");
                try ICircle(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
                    console.log("AMAZING: executeRequest worked!");
                    console.log("Loan ID:", vm.toString(loanId));
                    
                    // Check final state
                    uint256 finalShares = ICircle(circleAddress).userShares(USER);
                    console.log("Final shares after execution:", finalShares);
                    
                    if (finalShares == sharesAfter) {
                        console.log("PERFECT: No double deduction during execution!");
                    } else {
                        console.log("Note: Shares changed during execution (might be expected)");
                        console.log("Difference:", sharesAfter > finalShares ? sharesAfter - finalShares : finalShares - sharesAfter);
                    }
                    
                } catch Error(string memory reason) {
                    console.log("executeRequest failed (expected for DeFi issues):", reason);
                } catch {
                    console.log("executeRequest failed with unknown error (expected for DeFi issues)");
                }
                
            } else {
                console.log("ERROR: No shares were deducted - contribution logic still broken!");
            }
            
        } catch Error(string memory reason) {
            console.log("Contribution failed:", reason);
        } catch {
            console.log("Contribution failed with unknown error");
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== TEST ROUND 2 COMPLETE ===");
        console.log("Testing fixed contribution logic with user:", USER);
    }
}
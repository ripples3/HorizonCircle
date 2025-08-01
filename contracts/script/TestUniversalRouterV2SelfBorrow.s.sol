// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";
import "../src/HorizonCircleImplementation.sol";

contract TestUniversalRouterV2SelfBorrow is Script {
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant FACTORY = 0x95e4c63Ee7e82b94D75dDbF858F0D2D0600fcCdD; // Previous working factory from conversation history
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Testing Universal Router V2 Self Borrow ===");
        console.log("User:", USER);
        console.log("Factory:", FACTORY);
        console.log("Script runner:", msg.sender);
        
        // 1. Create a circle for testing with ONLY the target user
        HorizonCircleMinimalProxy factory = HorizonCircleMinimalProxy(FACTORY);
        address[] memory initialMembers = new address[](1);
        initialMembers[0] = USER;       // Only the target test user
        
        address circleAddress = factory.createCircle("UniversalRouterV2Test", initialMembers);
        console.log("Circle created:", circleAddress);
        
        HorizonCircleImplementation circle = HorizonCircleImplementation(payable(circleAddress));
        
        vm.stopBroadcast();
        
        // Switch to USER account for all operations
        vm.deal(USER, 1 ether); // Give user some ETH for gas  
        vm.startPrank(USER);
        
        // 2. User deposits 0.00003 ETH
        uint256 depositAmount = 0.00003 ether;
        console.log("User depositing:", depositAmount);
        circle.deposit{value: depositAmount}();
        console.log("User deposit successful");
        
        // Check balance
        uint256 userBalance = circle.getUserBalance(USER);
        console.log("User balance after deposit:", userBalance);
        
        // 3. Calculate 70% LTV borrow amount for safe testing
        uint256 borrowAmount = (userBalance * 70) / 100; // 70% of user's actual balance
        console.log("Borrowing amount (70% LTV):", borrowAmount);
        
        // 4. Create self-contribution request (user contributes to own loan)
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        
        uint256[] memory contributorAmounts = new uint256[](1);
        contributorAmounts[0] = borrowAmount; // User contributes the full collateral needed
        
        bytes32 requestId = circle.requestCollateral(
            borrowAmount,        // borrowAmount
            borrowAmount,        // collateralAmount (same since 70% < 85% LTV limit)
            contributors,
            contributorAmounts,
            "Universal Router V2 test"
        );
        
        console.log("Request created:");
        console.logBytes32(requestId);
        
        // 5. Contribute to own request
        circle.contributeToRequest(requestId);
        console.log("Self-contribution made");
        
        // 6. Execute the loan with UNIVERSAL ROUTER V2 FACTORY FIX
        console.log("Executing loan with Universal Router V2 factory fix...");
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS: Loan executed with Universal Router V2 factory fix!");
            console.logBytes32(loanId);
            
            // Check final balances
            uint256 finalBalance = circle.getUserBalance(USER);
            uint256 ethBalance = USER.balance;
            
            console.log("Final circle balance:", finalBalance);
            console.log("Final ETH balance:", ethBalance);
            console.log("BREAKTHROUGH: Universal Router validation issue RESOLVED!");
            
        } catch Error(string memory reason) {
            console.log("FAILED: Loan execution failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("FAILED: Loan execution failed with low-level error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopPrank();
    }
}
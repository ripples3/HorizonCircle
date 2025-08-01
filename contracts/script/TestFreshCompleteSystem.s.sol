// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";
import "../src/HorizonCircleImplementation.sol";

contract TestFreshCompleteSystem is Script {
    address constant REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC;
    address constant WORKING_IMPLEMENTATION = 0xEaAb6d6e56e53e9a31fFdb7951C1fD198Aee0180; // Size-fixed implementation
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== FRESH COMPLETE SYSTEM TEST ===");
        console.log("Implementation:", WORKING_IMPLEMENTATION);
        
        // Deploy fresh factory
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            WORKING_IMPLEMENTATION
        );
        console.log("Fresh factory deployed:", address(factory));
        
        vm.stopBroadcast();
        
        // Create and test complete system
        vm.startPrank(USER);
        
        console.log("\n=== Step 1: Create Circle ===");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        address circleAddr = factory.createCircle("CompleteSystemTest", members);
        console.log("Circle created:", circleAddr);
        
        HorizonCircleImplementation circle = HorizonCircleImplementation(payable(circleAddr));
        
        console.log("\n=== Step 2: Test Basic Functions ===");
        string memory circleName = circle.name();
        console.log("Circle name:", circleName);
        
        bool isMember = circle.isCircleMember(USER);
        console.log("Is member:", isMember);
        
        console.log("\n=== Step 3: Deposit ===");
        circle.deposit{value: 0.00003 ether}();
        console.log("Deposit completed");
        
        uint256 userBalance = circle.getUserBalance(USER);
        console.log("User balance:", userBalance);
        
        console.log("\n=== Step 4: Create Loan Request ===");
        uint256 borrowAmount = (userBalance * 70) / 100;
        console.log("Borrow amount (70% LTV):", borrowAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        uint256[] memory contributorAmounts = new uint256[](1);
        contributorAmounts[0] = borrowAmount;
        
        bytes32 requestId = circle.requestCollateral(
            borrowAmount,
            borrowAmount,
            contributors,
            contributorAmounts,
            "Complete system test"
        );
        console.log("Request created");
        
        console.log("\n=== Step 5: Contribute ===");
        circle.contributeToRequest(requestId);
        console.log("Contribution made");
        
        console.log("\n=== Step 6: EXECUTE LOAN (THE MOMENT OF TRUTH) ===");
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            console.log("");
            console.log("SUCCESS: COMPLETE LOAN EXECUTION WORKING!");
            console.log("Loan ID created");
            console.log("SYSTEM STATUS: 100% FUNCTIONAL");
            console.log("");
            
        } catch Error(string memory reason) {
            console.log("Execution failed:", reason);
        } catch (bytes memory) {
            console.log("Execution failed with low-level error");
        }
        
        vm.stopPrank();
    }
}
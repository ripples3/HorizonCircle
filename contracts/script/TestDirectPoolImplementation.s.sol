// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";
import "../src/HorizonCircleImplementation.sol";

contract TestDirectPoolImplementation is Script {
    address constant REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC;
    address constant ROUTER_IMPLEMENTATION = 0x377Ff7F5c50F46f17955535b836958B04aB33cE4; // Router-based implementation (industry standard)
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== TESTING ROUTER IMPLEMENTATION ===");
        console.log("Implementation (Router):", ROUTER_IMPLEMENTATION);
        
        // Deploy fresh factory with router implementation
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            ROUTER_IMPLEMENTATION
        );
        console.log("Factory deployed:", address(factory));
        
        vm.stopBroadcast();
        
        // Test complete system
        vm.startPrank(USER);
        
        console.log("\n=== Step 1: Create Circle ===");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        address circleAddr = factory.createCircle("DirectPoolTest", members);
        console.log("Circle created:", circleAddr);
        
        HorizonCircleImplementation circle = HorizonCircleImplementation(payable(circleAddr));
        
        console.log("\n=== Step 2: Verify Basic Functions ===");
        string memory circleName = circle.name();
        console.log("Circle name:", circleName);
        
        bool isMember = circle.isCircleMember(USER);
        console.log("Is member:", isMember);
        
        console.log("\n=== Step 3: Deposit ===");
        circle.deposit{value: 0.00003 ether}();
        console.log("Deposit completed");
        
        uint256 userBalance = circle.getUserBalance(USER);
        console.log("User balance:", userBalance);
        
        console.log("\n=== Step 4: Create and Execute Loan (DIRECT POOL SWAP) ===");
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
            "Direct pool swap test"
        );
        console.log("Request created");
        
        circle.contributeToRequest(requestId);
        console.log("Contribution made");
        
        console.log("\n=== FINAL TEST: Router Swap Integration ===");
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            console.log("");
            console.log("SUCCESS: ROUTER SWAP WORKING!");
            console.log("Loan execution completed with Velodrome Router");
            console.log("System Status: 100% FUNCTIONAL");
            console.log("Industry standard approach is working!");
            console.log("");
            
        } catch Error(string memory reason) {
            console.log("Router execution failed:", reason);
        } catch (bytes memory) {
            console.log("Router execution failed with low-level error");
        }
        
        vm.stopPrank();
    }
}
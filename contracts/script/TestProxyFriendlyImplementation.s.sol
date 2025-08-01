// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";
import "../src/HorizonCircleImplementation.sol";

contract TestProxyFriendlyImplementation is Script {
    address constant REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC;
    address constant FIXED_IMPLEMENTATION = 0xEaAb6d6e56e53e9a31fFdb7951C1fD198Aee0180; // Proxy-friendly
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Testing Proxy-Friendly Implementation ===");
        console.log("Fixed Implementation:", FIXED_IMPLEMENTATION);
        
        // Deploy factory with fixed implementation
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            FIXED_IMPLEMENTATION
        );
        console.log("Factory deployed:", address(factory));
        
        vm.stopBroadcast();
        
        // Test circle creation and basic functionality
        vm.startPrank(USER);
        
        console.log("\n=== Creating Circle with Fixed Implementation ===");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        address circleAddr = factory.createCircle("FixedCircle", members);
        console.log("Circle created at:", circleAddr);
        
        HorizonCircleImplementation circle = HorizonCircleImplementation(payable(circleAddr));
        
        console.log("\n=== Testing Circle Functions ===");
        
        // Test basic functions
        try circle.name() returns (string memory circleName) {
            console.log("Circle name:", circleName);
        } catch Error(string memory reason) {
            console.log("Name failed:", reason);
            vm.stopPrank();
            return;
        }
        
        try circle.isCircleMember(USER) returns (bool isMember) {
            console.log("Is member:", isMember);
        } catch Error(string memory reason) {
            console.log("Member check failed:", reason);
            vm.stopPrank();
            return;
        }
        
        // Test deposit
        console.log("\n=== Testing Deposit ===");
        try circle.deposit{value: 0.00003 ether}() {
            console.log("Deposit successful!");
            
            uint256 balance = circle.getUserBalance(USER);
            console.log("User balance:", balance);
            
            console.log("SUCCESS: Proxy implementation working!");
            
        } catch Error(string memory reason) {
            console.log("Deposit failed:", reason);
        }
        
        vm.stopPrank();
    }
}
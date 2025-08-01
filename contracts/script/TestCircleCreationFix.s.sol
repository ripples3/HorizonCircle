// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IWorkingFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
    function getCircleCount() external view returns (uint256);
    function getUserCircles(address user) external view returns (address[] memory);
}

interface IHorizonCircle {
    function name() external view returns (string memory);
    function getMembers() external view returns (address[] memory);
    function isCircleMember(address user) external view returns (bool);
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
}

contract TestCircleCreationFix is Script {
    address constant WORKING_FACTORY = 0xae5CdD2f24F90D04993DA9E13e70586Ab7281E7b;
    
    function run() external {
        vm.startBroadcast();
        
        address testUser = msg.sender;
        console.log("=== Testing Circle Creation Fix ===");
        console.log("Test user:", testUser);
        console.log("Working factory:", WORKING_FACTORY);
        
        // Test 1: Check factory status
        console.log("\n1. Checking factory status...");
        try IWorkingFactory(WORKING_FACTORY).getCircleCount() returns (uint256 count) {
            console.log("SUCCESS: Factory accessible, current circle count:", count);
        } catch Error(string memory reason) {
            console.log("FAILED: Factory not accessible:", reason);
            vm.stopBroadcast();
            return;
        }
        
        // Test 2: Create a test circle
        console.log("\n2. Creating test circle...");
        address[] memory members = new address[](1);
        members[0] = testUser;
        
        string memory circleName = string(abi.encodePacked("TestCircle_", vm.toString(block.timestamp)));
        
        try IWorkingFactory(WORKING_FACTORY).createCircle(circleName, members) returns (address circleAddress) {
            console.log("SUCCESS: Circle created at:", circleAddress);
            
            // Test 3: Verify circle functionality
            console.log("\n3. Testing circle functionality...");
            
            // Test name
            try IHorizonCircle(circleAddress).name() returns (string memory name) {
                console.log("SUCCESS: Circle name:", name);
            } catch Error(string memory reason) {
                console.log("FAILED: Circle name() failed:", reason);
            }
            
            // Test membership
            try IHorizonCircle(circleAddress).isCircleMember(testUser) returns (bool isMember) {
                console.log("SUCCESS: User is member:", isMember);
            } catch Error(string memory reason) {
                console.log("FAILED: isCircleMember() failed:", reason);
            }
            
            // Test members list
            try IHorizonCircle(circleAddress).getMembers() returns (address[] memory circleMembers) {
                console.log("SUCCESS: Circle has", circleMembers.length, "members");
                if (circleMembers.length > 0) {
                    console.log("First member:", circleMembers[0]);
                }
            } catch Error(string memory reason) {
                console.log("FAILED: getMembers() failed:", reason);
            }
            
            // Test 4: Test deposit functionality
            console.log("\n4. Testing deposit functionality...");
            uint256 depositAmount = 0.001 ether;
            
            try IHorizonCircle(circleAddress).deposit{value: depositAmount}() {
                console.log("SUCCESS: Deposit completed");
                
                // Check balance
                try IHorizonCircle(circleAddress).getUserBalance(testUser) returns (uint256 balance) {
                    console.log("SUCCESS: User balance:", balance);
                } catch Error(string memory reason) {
                    console.log("WARNING: getUserBalance() failed:", reason);
                }
                
            } catch Error(string memory reason) {
                console.log("FAILED: Deposit failed:", reason);
            }
            
            // Test 5: Verify user circles
            console.log("\n5. Verifying user circles...");
            try IWorkingFactory(WORKING_FACTORY).getUserCircles(testUser) returns (address[] memory userCircles) {
                console.log("SUCCESS: User has", userCircles.length, "circles");
                bool foundNewCircle = false;
                for (uint i = 0; i < userCircles.length; i++) {
                    if (userCircles[i] == circleAddress) {
                        foundNewCircle = true;
                        break;
                    }
                }
                console.log("New circle in user list:", foundNewCircle);
            } catch Error(string memory reason) {
                console.log("FAILED: getUserCircles() failed:", reason);
            }
            
        } catch Error(string memory reason) {
            console.log("FAILED: Circle creation failed:", reason);
        } catch {
            console.log("FAILED: Circle creation failed with unknown error");
        }
        
        console.log("\n=== Test Complete ===");
        console.log("If all tests show SUCCESS, the fix is working properly!");
        
        vm.stopBroadcast();
    }
}
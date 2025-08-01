// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
    function getCircleCount() external view returns (uint256);
}

contract TestFactoryOnly is Script {
    address constant FACTORY = 0xa712DBB01EE385deeB51EB3410A6879674E8C3e4;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        console.log("=== Testing Factory Only ===");
        console.log("Factory:", FACTORY);
        console.log("User:", USER);
        console.log("User balance:", USER.balance, "wei");
        
        // Check factory is working
        uint256 circleCount = IFactory(FACTORY).getCircleCount();
        console.log("Current circle count:", circleCount);
        
        // Try to create a circle
        vm.startPrank(USER);
        
        console.log("\nAttempting to create circle...");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        try IFactory(FACTORY).createCircle("TestCircle", members) returns (address circleAddress) {
            console.log("SUCCESS: Circle created at:", circleAddress);
            
            // Check updated count
            uint256 newCount = IFactory(FACTORY).getCircleCount();
            console.log("New circle count:", newCount);
            
        } catch Error(string memory reason) {
            console.log("FAILED: Circle creation failed:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("FAILED: Circle creation failed with low-level error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopPrank();
    }
}
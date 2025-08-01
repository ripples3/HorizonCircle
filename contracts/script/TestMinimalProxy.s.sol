// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";
import "../src/TestMinimalImplementation.sol";

contract TestMinimalProxy is Script {
    address constant REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Testing Minimal Implementation ===");
        
        // Deploy minimal test implementation
        TestMinimalImplementation minimalImpl = new TestMinimalImplementation();
        console.log("Minimal implementation:", address(minimalImpl));
        
        // Deploy factory with minimal implementation
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            address(minimalImpl)
        );
        console.log("Factory deployed:", address(factory));
        
        vm.stopBroadcast();
        
        // Test with minimal implementation
        vm.startPrank(USER);
        
        console.log("\n=== Creating Circle with Minimal Implementation ===");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        address circleAddr = factory.createCircle("MinimalTest", members);
        console.log("Circle created at:", circleAddr);
        
        TestMinimalImplementation circle = TestMinimalImplementation(circleAddr);
        
        console.log("\n=== Testing Basic Functions ===");
        
        try circle.name() returns (string memory circleName) {
            console.log("SUCCESS: Circle name:", circleName);
        } catch Error(string memory reason) {
            console.log("Name failed:", reason);
            vm.stopPrank();
            return;
        }
        
        try circle.isCircleMember(USER) returns (bool isMember) {
            console.log("SUCCESS: Is member:", isMember);
        } catch Error(string memory reason) {
            console.log("Member check failed:", reason);
            vm.stopPrank();
            return;
        }
        
        try circle.getMemberCount() returns (uint256 count) {
            console.log("SUCCESS: Member count:", count);
            console.log("BREAKTHROUGH: Proxy system is working!");
        } catch Error(string memory reason) {
            console.log("Member count failed:", reason);
        }
        
        vm.stopPrank();
    }
}
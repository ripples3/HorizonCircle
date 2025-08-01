// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";
import "../src/HorizonCircleImplementation.sol";

contract DebugProxyCreation is Script {
    address constant REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC;
    address constant IMPLEMENTATION = 0x672604DF646aCd304DB9f364d1F971e671D348A3;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Debug Proxy Creation ===");
        console.log("Registry:", REGISTRY);
        console.log("Implementation:", IMPLEMENTATION);
        
        // Deploy a fresh factory
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            IMPLEMENTATION
        );
        console.log("Factory deployed:", address(factory));
        console.log("Factory implementation:", factory.implementation());
        
        vm.stopBroadcast();
        
        // Test proxy creation with detailed debugging
        vm.startPrank(USER);
        
        console.log("\n=== Creating Circle ===");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        // Manually check each step
        console.log("Step 1: Creating circle...");
        address circleAddr = factory.createCircle("DebugCircle", members);
        console.log("Circle created at:", circleAddr);
        
        console.log("Step 2: Checking proxy storage...");
        // Check if implementation is set (in EIP-1167, the implementation is embedded in bytecode)
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(circleAddr)
        }
        console.log("Circle code size:", codeSize);
        
        console.log("Step 3: Testing basic calls...");
        HorizonCircleImplementation circle = HorizonCircleImplementation(payable(circleAddr));
        
        // Test the most basic call
        try circle.name() returns (string memory circleName) {
            console.log("Circle name:", circleName);
        } catch Error(string memory reason) {
            console.log("Name call failed:", reason);
        } catch {
            console.log("Name call failed: unknown error");
        }
        
        // Test member check
        try circle.isCircleMember(USER) returns (bool isMember) {
            console.log("Is member:", isMember);
        } catch Error(string memory reason) {
            console.log("Member check failed:", reason);
        } catch {
            console.log("Member check failed: unknown error");
        }
        
        vm.stopPrank();
    }
}
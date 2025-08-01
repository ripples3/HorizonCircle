// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";
import "../src/HorizonCircleImplementation.sol";

contract TestFreshCircleWithWorkingFactory is Script {
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant FACTORY = 0x95e4c63Ee7e82b94D75dDbF858F0D2D0600fcCdD; // Working factory
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Testing Fresh Circle with Working Factory ===");
        console.log("User:", USER);
        console.log("Factory:", FACTORY);
        
        // Check what implementation the factory is using
        HorizonCircleMinimalProxy factory = HorizonCircleMinimalProxy(FACTORY);
        address implementationAddr = factory.implementation();
        console.log("Factory implementation:", implementationAddr);
        
        // Create a new circle
        address[] memory initialMembers = new address[](1);
        initialMembers[0] = USER;
        
        address circleAddress = factory.createCircle("FreshTestCircle", initialMembers);
        console.log("New circle created:", circleAddress);
        
        vm.stopBroadcast();
        
        // Test the new circle
        vm.startPrank(USER);
        
        HorizonCircleImplementation circle = HorizonCircleImplementation(payable(circleAddress));
        
        console.log("\n=== Testing Circle Functions ===");
        
        // Test basic functions
        try circle.isCircleMember(USER) returns (bool isMember) {
            console.log("Is member:", isMember);
        } catch {
            console.log("ERROR: isCircleMember failed - proxy issue");
            vm.stopPrank();
            return;
        }
        
        try circle.totalDeposits() returns (uint256 totalDep) {
            console.log("Total deposits:", totalDep);
        } catch {
            console.log("ERROR: totalDeposits failed");
            vm.stopPrank();
            return;
        }
        
        // Test deposit
        console.log("\n=== Testing Deposit ===");
        try circle.deposit{value: 0.00003 ether}() {
            console.log("Deposit successful");
            
            uint256 userBalance = circle.getUserBalance(USER);
            console.log("User balance after deposit:", userBalance);
            
        } catch Error(string memory reason) {
            console.log("Deposit failed with reason:", reason);
        } catch {
            console.log("Deposit failed with unknown error");
        }
        
        vm.stopPrank();
    }
}
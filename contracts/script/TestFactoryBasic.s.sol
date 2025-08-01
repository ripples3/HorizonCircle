// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
    function swapModule() external view returns (address);
    function lendingModule() external view returns (address);
    function coreImplementation() external view returns (address);
}

contract TestFactoryBasic is Script {
    address constant FACTORY = 0x34A1D3fff3958843C43aD80F30b94c510645C316;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        console.log("=== Testing Factory Basic Functionality ===");
        console.log("Factory:", FACTORY);
        console.log("User:", USER);
        
        // Check factory components
        try IFactory(FACTORY).coreImplementation() returns (address impl) {
            console.log("Core Implementation:", impl);
        } catch {
            console.log("ERROR: Cannot read coreImplementation");
        }
        
        try IFactory(FACTORY).swapModule() returns (address swap) {
            console.log("Swap Module:", swap);
        } catch {
            console.log("ERROR: Cannot read swapModule");
        }
        
        try IFactory(FACTORY).lendingModule() returns (address lending) {
            console.log("Lending Module:", lending);
        } catch {
            console.log("ERROR: Cannot read lendingModule");
        }
        
        // Check user balance
        console.log("User ETH balance:", USER.balance, "wei");
        
        // Try creating a circle (simulation only)
        vm.startPrank(USER);
        
        console.log("\nTesting circle creation...");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        string memory circleName = string(abi.encodePacked("TestBasic_", vm.toString(block.timestamp)));
        
        try IFactory(FACTORY).createCircle(circleName, members) returns (address circleAddress) {
            console.log("SUCCESS: Circle created at:", circleAddress);
        } catch Error(string memory reason) {
            console.log("FAILED: Circle creation failed:", reason);
        } catch {
            console.log("FAILED: Circle creation failed with unknown error");
        }
        
        vm.stopPrank();
    }
}
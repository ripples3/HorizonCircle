// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IStreamlinedFactory {
    function nameExists(string memory) external view returns (bool);
    function implementation() external view returns (address);
    function registry() external view returns (address);
    function createCircle(string memory name, address[] memory members) external returns (address);
}

contract TestSimpleStreamlined is Script {
    address constant FACTORY = 0x34A1D3fff3958843C43aD80F30b94c510645C316;
    
    function run() external {
        console.log("=== SIMPLE STREAMLINED FACTORY TEST ===");
        
        IStreamlinedFactory factory = IStreamlinedFactory(FACTORY);
        
        // Check factory state
        console.log("Factory:", address(factory));
        console.log("Implementation:", factory.implementation());
        console.log("Registry:", factory.registry());
        
        // Check if name exists
        string memory testName = "SimpleTest";
        console.log("Name exists before:", factory.nameExists(testName));
        
        vm.startBroadcast();
        
        // Try minimal create circle call
        address[] memory members = new address[](1);
        members[0] = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
        
        try factory.createCircle(testName, members) returns (address circleAddr) {
            console.log("SUCCESS: Circle created at:", circleAddr);
        } catch Error(string memory reason) {
            console.log("FAILED with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("FAILED with low-level error, length:", lowLevelData.length);
        }
        
        vm.stopBroadcast();
    }
}
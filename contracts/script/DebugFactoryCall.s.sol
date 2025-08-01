// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IInitializingFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

contract DebugFactoryCall is Script {
    address constant FACTORY = 0xa4e70185379F992F40e0aBeA011341bB090df722;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Debug Factory Call ===");
        console.log("Factory:", FACTORY);
        console.log("Caller:", msg.sender);
        
        // Try to create a circle
        address[] memory members = new address[](1);
        members[0] = msg.sender;
        
        try IInitializingFactory(FACTORY).createCircle("test", members) returns (address circle) {
            console.log("SUCCESS: Circle created at:", circle);
        } catch Error(string memory reason) {
            console.log("FAILED with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("FAILED with low level error, length:", lowLevelData.length);
        }
        
        vm.stopBroadcast();
    }
}
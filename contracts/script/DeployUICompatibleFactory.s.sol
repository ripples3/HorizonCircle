// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

/**
 * @title UI Compatible Factory
 * @notice Factory that matches the frontend ABI expectations
 */
contract UICompatibleFactory {
    address public immutable implementation;
    address[] public circlesList;
    mapping(address => address[]) public userCircles;
    
    event CircleCreated(address indexed circleAddress, string name, address indexed creator);
    
    constructor(address _implementation) {
        implementation = _implementation;
    }
    
    function createCircle(string memory name, address[] memory initialMembers) external returns (address) {
        // Create minimal proxy pointing to fixed implementation
        bytes32 salt = keccak256(abi.encodePacked(name, msg.sender, block.timestamp));
        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d3d363d73",
            implementation,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circleAddress;
        assembly {
            circleAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(circleAddress) { revert(0, 0) }
        }
        
        // Store circle
        circlesList.push(circleAddress);
        userCircles[msg.sender].push(circleAddress);
        
        // Add all initial members to their circle lists
        for (uint256 i = 0; i < initialMembers.length; i++) {
            if (initialMembers[i] != msg.sender) {
                userCircles[initialMembers[i]].push(circleAddress);
            }
        }
        
        emit CircleCreated(circleAddress, name, msg.sender);
        return circleAddress;
    }
    
    // Frontend ABI compatibility functions
    function getCircleCount() external view returns (uint256) {
        return circlesList.length;
    }
    
    function getUserCircles(address user) external view returns (address[] memory) {
        return userCircles[user];
    }
    
    function allCircles(uint256 index) external view returns (address) {
        return circlesList[index];
    }
}

contract DeployUICompatibleFactory is Script {
    address constant FIXED_CORE_IMPLEMENTATION = 0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING UI COMPATIBLE FACTORY ===");
        console.log("Fixed implementation:", FIXED_CORE_IMPLEMENTATION);
        console.log("Starting from block: 19636825");
        console.log("");
        
        // Deploy UI compatible factory
        UICompatibleFactory factory = new UICompatibleFactory(FIXED_CORE_IMPLEMENTATION);
        console.log("UI Compatible Factory deployed:", address(factory));
        
        // Test the functions that the frontend expects
        uint256 circleCount = factory.getCircleCount();
        console.log("Circle count:", circleCount);
        
        console.log("");
        console.log("*** SUCCESS: UI COMPATIBLE FACTORY READY ***");
        console.log("");
        console.log("UPDATE FRONTEND web3.ts:");
        console.log("FACTORY:", address(factory));
        console.log("");
        console.log("This factory provides:");
        console.log("- createCircle(string,address[]) -> address");
        console.log("- getCircleCount() -> uint256");
        console.log("- getUserCircles(address) -> address[]");
        console.log("- allCircles(uint256) -> address");
        console.log("- CircleCreated event");
        console.log("");
        console.log("All circles created will use fixed implementation:", FIXED_CORE_IMPLEMENTATION);
        
        vm.stopBroadcast();
    }
}
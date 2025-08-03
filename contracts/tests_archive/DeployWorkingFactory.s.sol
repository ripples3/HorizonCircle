// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract SimpleFactory {
    address public immutable implementation;
    address[] public circlesList;
    mapping(address => address[]) public userCircles;
    
    event CircleCreated(address indexed circleAddress, string name, address indexed creator);
    
    constructor(address _implementation) {
        implementation = _implementation;
    }
    
    function createCircle(string memory name, address[] memory initialMembers) external returns (address) {
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
        
        circlesList.push(circleAddress);
        userCircles[msg.sender].push(circleAddress);
        
        for (uint256 i = 0; i < initialMembers.length; i++) {
            if (initialMembers[i] != msg.sender) {
                userCircles[initialMembers[i]].push(circleAddress);
            }
        }
        
        emit CircleCreated(circleAddress, name, msg.sender);
        return circleAddress;
    }
    
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

contract DeployWorkingFactory is Script {
    address constant WORKING_IMPLEMENTATION = 0xA2878649Adaf8Fc6Be4df7209d526147862AC59B;
    
    function run() external {
        vm.startBroadcast();

        console.log("=== Deploying WORKING Factory ===");
        console.log("Implementation:", WORKING_IMPLEMENTATION);

        SimpleFactory factory = new SimpleFactory(WORKING_IMPLEMENTATION);
        console.log("Working factory deployed:", address(factory));
        console.log("Update frontend FACTORY to:", address(factory));

        vm.stopBroadcast();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IHorizonCircle {
    function initialize(string memory, address[] memory) external;
}

contract CorrectFactory {
    address public immutable implementation;
    address public immutable registry;
    address[] public circlesList;
    mapping(address => address[]) public userCircles;
    
    event CircleCreated(address indexed circleAddress, string name, address indexed creator);
    
    constructor(address _implementation, address _registry) {
        implementation = _implementation;
        registry = _registry;
    }
    
    function createCircle(string memory name, address[] memory initialMembers) external returns (address) {
        require(initialMembers.length > 0, "Need members");
        
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
        
        // Try initialize with just name and members (no factory parameter)
        IHorizonCircle(circleAddress).initialize(name, initialMembers);
        
        // Register in registry if available
        if (registry != address(0)) {
            (bool success,) = registry.call(
                abi.encodeWithSignature("registerCircle(address,string,address[])", circleAddress, name, initialMembers)
            );
            // Continue even if registry fails
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

contract DeployCorrectFactory is Script {
    // Complete implementation with executeRequest and full DeFi integration
    address constant FULL_IMPLEMENTATION = 0xccDDb5f678c2794be86565Bb955Ddbfb388111F1;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Deploying Correct Factory ===");
        console.log("Full Implementation:", FULL_IMPLEMENTATION);
        console.log("Registry:", REGISTRY);
        
        CorrectFactory factory = new CorrectFactory(
            FULL_IMPLEMENTATION,
            REGISTRY
        );
        
        console.log("\nCorrect Factory deployed:", address(factory));
        
        vm.stopBroadcast();
    }
}
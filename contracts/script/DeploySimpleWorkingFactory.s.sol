// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleCore.sol";

// Simple implementation that doesn't require complex initialization
contract SimpleCircleImplementation {
    mapping(address => bool) public isCircleMember;
    mapping(address => uint256) public userShares;
    address[] public members;
    string public name;
    uint256 public totalShares;
    uint256 public totalDeposits;
    
    bool private initialized;
    
    function initialize(string memory _name, address[] memory _members) external {
        require(!initialized, "Already initialized");
        initialized = true;
        name = _name;
        
        for (uint256 i = 0; i < _members.length; i++) {
            members.push(_members[i]);
            isCircleMember[_members[i]] = true;
        }
    }
    
    function deposit() external payable {
        require(isCircleMember[msg.sender], "Not a member");
        require(msg.value > 0, "Amount must be > 0");
        
        uint256 shares = totalShares == 0 ? msg.value : (msg.value * totalShares) / totalDeposits;
        
        userShares[msg.sender] += shares;
        totalShares += shares;
        totalDeposits += msg.value;
    }
    
    function getUserBalance(address user) external view returns (uint256) {
        if (totalShares == 0) return 0;
        return (userShares[user] * totalDeposits) / totalShares;
    }
    
    function getMembers() external view returns (address[] memory) {
        return members;
    }
    
    function getMemberCount() external view returns (uint256) {
        return members.length;
    }
}

contract SimpleWorkingFactory {
    address public immutable implementation;
    address[] public circlesList;
    mapping(address => address[]) public userCircles;
    
    event CircleCreated(address indexed circleAddress, string name, address indexed creator);
    
    constructor() {
        // Deploy the implementation
        implementation = address(new SimpleCircleImplementation());
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
        
        // Initialize with simple method
        SimpleCircleImplementation(circleAddress).initialize(name, initialMembers);
        
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

contract DeploySimpleWorkingFactory is Script {
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Deploying Simple Working Factory ===");
        
        SimpleWorkingFactory factory = new SimpleWorkingFactory();
        
        console.log("Simple working factory deployed:", address(factory));
        console.log("Implementation deployed at:", factory.implementation());
        console.log("This factory creates basic working circles!");
        console.log("Update frontend FACTORY to:", address(factory));
        
        vm.stopBroadcast();
    }
}
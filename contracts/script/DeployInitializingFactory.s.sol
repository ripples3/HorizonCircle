// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IHorizonCircleCore {
    function initialize(
        string memory name,
        address[] memory _members,
        address factory,
        address _swapModule,
        address _lendingModule
    ) external;
}

contract InitializingFactory {
    address public immutable implementation;
    address public immutable swapModule;
    address public immutable lendingModule;
    address[] public circlesList;
    mapping(address => address[]) public userCircles;
    
    event CircleCreated(address indexed circleAddress, string name, address indexed creator);
    
    constructor(address _implementation, address _swapModule, address _lendingModule) {
        implementation = _implementation;
        swapModule = _swapModule;
        lendingModule = _lendingModule;
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
        
        // Initialize the circle with modules
        IHorizonCircleCore(circleAddress).initialize(
            name,
            initialMembers,
            address(this),
            swapModule,
            lendingModule
        );
        
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

contract DeployInitializingFactory is Script {
    address constant HORIZON_CIRCLE_CORE = 0xA2878649Adaf8Fc6Be4df7209d526147862AC59B;
    address constant SWAP_MODULE = 0xe071b320B3Bf9Cd8a026A98cC59F3636272642b1;
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Deploying Initializing Factory ===");
        console.log("HorizonCircleCore:", HORIZON_CIRCLE_CORE);
        console.log("SwapModule:", SWAP_MODULE);
        console.log("LendingModule:", LENDING_MODULE);
        
        InitializingFactory factory = new InitializingFactory(
            HORIZON_CIRCLE_CORE,
            SWAP_MODULE,
            LENDING_MODULE
        );
        
        console.log("Initializing factory deployed:", address(factory));
        console.log("This factory will properly initialize circles with modules!");
        console.log("Update frontend FACTORY to:", address(factory));
        
        vm.stopBroadcast();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IProxyCompatibleHorizonCircleCore {
    function initialize(
        string memory name,
        address[] memory _members,
        address factory,
        address _swapModule,
        address _lendingModule
    ) external;
}

contract FixedModularFactory {
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
        
        // Initialize with proxy-compatible core + modules
        IProxyCompatibleHorizonCircleCore(circleAddress).initialize(
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

contract DeployFixedModularFactory is Script {
    address constant PROXY_COMPATIBLE_CORE = 0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519;
    address constant SWAP_MODULE = 0xe071b320B3Bf9Cd8a026A98cC59F3636272642b1;
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Deploying FIXED Modular Factory ===");
        console.log("ProxyCompatibleCore:", PROXY_COMPATIBLE_CORE);
        console.log("SwapModule:", SWAP_MODULE);
        console.log("LendingModule:", LENDING_MODULE);
        
        FixedModularFactory factory = new FixedModularFactory(
            PROXY_COMPATIBLE_CORE,
            SWAP_MODULE,
            LENDING_MODULE
        );
        
        console.log("FIXED Modular factory deployed:", address(factory));
        console.log("This creates circles with proxy-compatible implementation!");
        console.log("Update frontend FACTORY to:", address(factory));
        console.log("Set MIN_BLOCK_NUMBER to current block for clean slate");
        
        vm.stopBroadcast();
    }
}
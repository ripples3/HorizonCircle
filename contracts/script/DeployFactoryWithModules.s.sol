// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";

contract HorizonCircleMinimalProxyWithModules {
    ICircleRegistry public immutable registry;
    address public immutable implementation;
    address public immutable swapModule;
    address public immutable lendingModule;
    
    mapping(string => bool) public nameExists;
    
    event CircleCreated(address indexed circleAddress, string name, address indexed creator);
    
    constructor(address _registry, address _implementation, address _swapModule, address _lendingModule) {
        registry = ICircleRegistry(_registry);
        implementation = _implementation;
        swapModule = _swapModule;
        lendingModule = _lendingModule;
    }
    
    function getUserCircles(address user) external view returns (address[] memory) {
        return registry.getUserCircles(user);
    }
    
    function createCircle(string memory name, address[] memory initialMembers) external returns (address) {
        require(bytes(name).length > 0, "Name required");
        require(!nameExists[name], "Name exists");
        
        // Create EIP-1167 minimal proxy
        bytes32 salt = keccak256(abi.encodePacked(name, msg.sender, block.timestamp));
        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            implementation,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circleAddress;
        assembly {
            circleAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(circleAddress) { revert(0, 0) }
        }
        
        // Prepare members array (creator + initial members)
        address[] memory members = new address[](initialMembers.length + 1);
        members[0] = msg.sender;
        for (uint256 i = 0; i < initialMembers.length; i++) {
            members[i + 1] = initialMembers[i];
        }
        
        // Initialize the circle with modules
        (bool success,) = circleAddress.call(
            abi.encodeWithSignature(
                "initialize(string,address[],address,address,address)",
                name,
                members,
                address(this),
                swapModule,
                lendingModule
            )
        );
        require(success, "Init failed");
        
        // Mark name as taken
        nameExists[name] = true;
        
        // Register with registry
        registry.registerCircle(circleAddress, name, members);
        
        emit CircleCreated(circleAddress, name, msg.sender);
        return circleAddress;
    }
    
    function getCircleCount() external view returns (uint256) {
        return registry.getCircleCount();
    }
}

contract DeployFactoryWithModules is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOY FACTORY WITH MODULES ===" );
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Use verified contracts and modules
        address registry = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
        address implementation = 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56;
        address swapModule = 0x0f31FF744bdf78D8FDb2e5B037a9320AA86656c6; // New fixed SwapModule
        address lendingModule = 0x96F582fAF5a1D61640f437EBea9758b18a678720;
        
        // Deploy Factory with modules
        HorizonCircleMinimalProxyWithModules factory = new HorizonCircleMinimalProxyWithModules(
            registry,
            implementation,
            swapModule,
            lendingModule
        );
        
        console.log("Factory:", address(factory));
        console.log("Registry:", registry);  
        console.log("Implementation:", implementation);
        console.log("Swap Module:", swapModule);
        console.log("Lending Module:", lendingModule);
        
        vm.stopBroadcast();
        
        console.log("\nVERIFY:");
        console.log("Factory with modules deployed successfully");
    }
}
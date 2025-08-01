// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// Minimal factory that just registers existing circles - no deployment
contract MinimalCircleFactory {
    event CircleCreated(address indexed circleAddress, string name, address indexed creator);
    
    address[] public allCircles;
    mapping(address => address[]) public userCircles;
    mapping(string => bool) public nameExists;
    
    address public immutable registry;
    
    constructor(address _registry) {
        registry = _registry;
    }
    
    // This factory doesn't deploy - it just registers pre-deployed circles
    function createCircle(string memory name, address[] memory initialMembers) external returns (address) {
        revert("Use direct deployment then call registerExistingCircle");
    }
    
    // Register an existing circle (called after direct deployment)
    function registerExistingCircle(address circleAddress, string memory name) external {
        require(circleAddress != address(0), "Invalid address");
        require(bytes(name).length > 0, "Name required");
        require(!nameExists[name], "Name exists");
        
        // Simple ownership check - caller must be able to call a function on the circle
        (bool success,) = circleAddress.call(abi.encodeWithSignature("isCircleMember(address)", msg.sender));
        require(success, "Not authorized");
        
        allCircles.push(circleAddress);
        userCircles[msg.sender].push(circleAddress);
        nameExists[name] = true;
        
        // Register in main registry
        (bool regSuccess,) = registry.call(
            abi.encodeWithSignature("registerCircle(address,string,address[])", circleAddress, name, new address[](0))
        );
        require(regSuccess, "Registry failed");
        
        emit CircleCreated(circleAddress, name, msg.sender);
    }
    
    function getCircleCount() external view returns (uint256) {
        return allCircles.length;
    }
    
    function getUserCircles(address user) external view returns (address[] memory) {
        return userCircles[user];
    }
}

contract DeployMinimalFactoryScript is Script {
    function run() external {
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = bytes(pkString)[0] == "0" ? 
            vm.parseUint(pkString) : vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        address registryAddress = 0x8D1C2d51C73368ae6d044f02bF10eDc4e8FD1eBA;
        
        MinimalCircleFactory factory = new MinimalCircleFactory(registryAddress);
        
        console.log("MinimalCircleFactory deployed at:", address(factory));
        console.log("Registry:", registryAddress);
        
        vm.stopBroadcast();
        
        console.log("\n=== FRONTEND UPDATE NEEDED ===");
        console.log("FACTORY:", address(factory));
    }
}
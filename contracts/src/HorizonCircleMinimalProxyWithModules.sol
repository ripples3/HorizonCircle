// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICircleRegistry {
    function registerCircle(address circle, string memory name, address[] memory members) external;
    function getCircleCount() external view returns (uint256);
    function getUserCircles(address user) external view returns (address[] memory);
}

/**
 * @title HorizonCircleMinimalProxyWithModules
 * @notice Factory for creating HorizonCircles with swap and lending modules
 * @dev Deployed at 0x757A109a1b45174DD98fe7a8a72c8f343d200570
 */
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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CircleRegistry.sol";
import "./SwapModule.sol";
import "./LendingModule.sol";

interface IHorizonCircleCore {
    function initialize(
        string memory name,
        address[] memory members,
        address factory,
        address swapModule,
        address lendingModule
    ) external;
}

/**
 * @title HorizonCircleModularFactory
 * @notice Factory for deploying modular HorizonCircle with 100% functionality
 * @dev Deploys lightweight core + swap/lending modules to avoid gas limits
 */
contract HorizonCircleModularFactory {
    CircleRegistry public immutable registry;
    address public immutable coreImplementation;
    SwapModule public immutable swapModule;
    LendingModule public immutable lendingModule;
    
    event CircleCreated(address indexed circleAddress, string name, address indexed creator);
    
    mapping(string => bool) public nameExists;
    mapping(address => bool) public isCircle;
    
    constructor(address _registry, address _coreImplementation) {
        registry = CircleRegistry(_registry);
        coreImplementation = _coreImplementation;
        
        // Deploy shared modules
        swapModule = new SwapModule();
        lendingModule = new LendingModule();
    }
    
    function createCircle(string memory name, address[] memory initialMembers) external returns (address circleAddress) {
        require(bytes(name).length > 0, "Name required");
        require(!nameExists[name], "Name exists");
        
        // Deploy minimal proxy for core contract
        bytes32 salt = keccak256(abi.encodePacked(name, msg.sender, block.timestamp));
        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            coreImplementation,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        assembly {
            circleAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(circleAddress) { revert(0, 0) }
        }
        
        // Authorize circle in modules
        swapModule.authorizeCircle(circleAddress);
        lendingModule.authorizeCircle(circleAddress);
        
        // Initialize the circle
        address[] memory members = new address[](initialMembers.length + 1);
        members[0] = msg.sender;
        for (uint256 i = 0; i < initialMembers.length; i++) {
            members[i + 1] = initialMembers[i];
        }
        
        IHorizonCircleCore(circleAddress).initialize(
            name,
            members,
            address(this),
            address(swapModule),
            address(lendingModule)
        );
        
        // Register circle
        nameExists[name] = true;
        isCircle[circleAddress] = true;
        registry.registerCircle(circleAddress, name, members);
        
        emit CircleCreated(circleAddress, name, msg.sender);
        return circleAddress;
    }
}
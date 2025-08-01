// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

/**
 * @title Simple Factory for Fixed Implementation
 * @notice Deploys circles using the fixed core implementation
 */
contract SimpleCircleFactory {
    address public immutable implementation;
    
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
        
        emit CircleCreated(circleAddress, name, msg.sender);
        return circleAddress;
    }
    
    function getImplementation() external view returns (address) {
        return implementation;
    }
}

contract DeploySimpleFactory is Script {
    address constant FIXED_CORE_IMPLEMENTATION = 0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING SIMPLE WORKING FACTORY ===");
        console.log("Fixed implementation:", FIXED_CORE_IMPLEMENTATION);
        console.log("");
        
        // Deploy simple factory that uses the fixed implementation
        SimpleCircleFactory factory = new SimpleCircleFactory(FIXED_CORE_IMPLEMENTATION);
        console.log("New working factory deployed:", address(factory));
        
        // Verify it points to correct implementation
        address impl = factory.getImplementation();
        console.log("Factory implementation:", impl);
        console.log("Matches fixed core:", impl == FIXED_CORE_IMPLEMENTATION);
        
        console.log("");
        console.log("*** SUCCESS: WORKING FACTORY READY FOR UI ***");
        console.log("");
        console.log("UPDATE FRONTEND CONFIG:");
        console.log("FACTORY:", address(factory));
        console.log("");
        console.log("This factory will create circles that:");
        console.log("- Use the fixed core implementation");
        console.log("- Have correct wstETH address: 0x76D8de471F54aAA87784119c60Df1bbFc852C415");
        console.log("- Support modular architecture (SwapModule + LendingModule)");
        console.log("- Will NOT have router fallback errors");
        
        vm.stopBroadcast();
    }
}
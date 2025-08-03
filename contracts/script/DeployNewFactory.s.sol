// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract HorizonCircleMinimalProxyWithModules {
    address public immutable implementation;
    address public immutable swapModule;
    address public immutable lendingModule;
    address[] public circlesList;
    
    event CircleCreated(address indexed circleAddress, string name, address indexed creator);
    
    constructor(address _implementation, address _swapModule, address _lendingModule) {
        implementation = _implementation;
        swapModule = _swapModule;
        lendingModule = _lendingModule;
    }
    
    function createCircle(string memory name, address[] memory initialMembers) external returns (address) {
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
        
        // Initialize with modules
        address[] memory members = new address[](initialMembers.length + 1);
        members[0] = msg.sender;
        for (uint256 i = 0; i < initialMembers.length; i++) {
            members[i + 1] = initialMembers[i];
        }
        
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
        require(success, "Initialization failed");
        
        circlesList.push(circleAddress);
        emit CircleCreated(circleAddress, name, msg.sender);
        return circleAddress;
    }
    
    function getCircleCount() external view returns (uint256) {
        return circlesList.length;
    }
}

contract DeployNewFactory is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOYING NEW FACTORY WITH SAME CODE ===");
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Use the same verified contracts
        address implementation = 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56;
        address swapModule = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92;
        address lendingModule = 0x96F582fAF5a1D61640f437EBea9758b18a678720;
        
        console.log("Using verified contracts:");
        console.log("- Implementation:", implementation);
        console.log("- Swap Module:", swapModule);
        console.log("- Lending Module:", lendingModule);
        console.log("");
        
        HorizonCircleMinimalProxyWithModules newFactory = new HorizonCircleMinimalProxyWithModules(
            implementation,
            swapModule,
            lendingModule
        );
        
        console.log("NEW FACTORY DEPLOYED:", address(newFactory));
        console.log("");
        
        vm.stopBroadcast();
        
        console.log("=== NEXT STEPS ===");
        console.log("1. Update frontend to use new factory:", address(newFactory));
        console.log("2. Verify the new factory on Blockscout");
        console.log("3. Test circle creation with new factory");
    }
}
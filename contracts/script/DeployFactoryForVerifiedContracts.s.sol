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
            hex"3d602d80600a3d3981f3363d3d3d373d3d3d363d73",
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

contract DeployFactoryForVerifiedContracts is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOY FACTORY FOR VERIFIED CONTRACTS ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        address implementation = 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56;
        address swapModule = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92;
        address lendingModule = 0x96F582fAF5a1D61640f437EBea9758b18a678720;
        
        HorizonCircleMinimalProxyWithModules factory = new HorizonCircleMinimalProxyWithModules(
            implementation,
            swapModule,
            lendingModule
        );
        
        console.log("Factory deployed:", address(factory));
        console.log("Implementation:", implementation);
        console.log("Swap Module:", swapModule);
        console.log("Lending Module:", lendingModule);
        
        vm.stopBroadcast();
        
        console.log("\\n=== READY FOR TESTING ===");
        console.log("Use this factory with your verified contracts");
    }
}
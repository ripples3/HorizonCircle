// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/CircleRegistry.sol";
// No factory import needed - using direct addresses

contract RegisterExistingCirclesScript is Script {
    function run() external {
        // Get private key from environment
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = bytes(pkString)[0] == "0" ? 
            vm.parseUint(pkString) : vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        address registryAddress = 0x8D1C2d51C73368ae6d044f02bF10eDc4e8FD1eBA;
        address factoryAddress = 0x8d639a8CAe522aDA70408404707748737369dD6e;
        
        CircleRegistry registry = CircleRegistry(registryAddress);
        
        console.log("Registering existing circles from factory...");
        console.log("Factory:", factoryAddress);
        console.log("Registry:", registryAddress);
        
        // Get circle from factory (we know it has 1 circle)
        address circleAddress = 0x22Fb7A14F4eb65e333bB903247e5f97C192C98f4; // From our earlier query
        
        // Get circle details for registration
        string memory circleName = "TestCircle2024";
        address[] memory members = new address[](1);
        members[0] = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c; // Known creator
        
        // Register the circle
        registry.registerCircle(circleAddress, circleName, members);
        
        console.log("Registered circle:", circleAddress);
        console.log("Circle name:", circleName);
        console.log("New registry count:", registry.getCircleCount());
        
        vm.stopBroadcast();
        
        console.log("\n=== REGISTRATION COMPLETE ===");
        console.log("Existing circles now discoverable via registry events");
    }
}
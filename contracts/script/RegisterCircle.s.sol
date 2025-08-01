// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";

interface ICircleRegistry {
    function registerCircle(address circle, string memory name, address[] memory members) external;
}

contract RegisterCircleScript is Script {
    address constant REGISTRY = 0x503c9eaB64Ee36Af23E2d4801b0495A5804e5392;
    address constant NEW_CIRCLE = 0x46b6EEAc59639f3e58eEDB014223c5C675A0a0D9;
    
    function run() public {
        // Handle private key
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey;
        
        if (bytes(pkString).length > 2 && bytes(pkString)[0] == "0" && bytes(pkString)[1] == "x") {
            deployerPrivateKey = vm.parseUint(pkString);
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console2.log("Registering circle in CircleRegistry...");
        console2.log("Registry:", REGISTRY);
        console2.log("Circle:", NEW_CIRCLE);
        console2.log("Deployer:", deployer);
        
        // Prepare members array with just the deployer
        address[] memory members = new address[](1);
        members[0] = deployer;
        
        // Register the circle
        ICircleRegistry(REGISTRY).registerCircle(
            NEW_CIRCLE,
            "Test Circle - Low Min",
            members
        );
        
        console2.log("Circle registered successfully!");
        
        vm.stopBroadcast();
    }
}
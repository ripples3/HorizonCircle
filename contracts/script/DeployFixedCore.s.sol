// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleCore.sol";

contract DeployFixedCore is Script {
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING FIXED CORE IMPLEMENTATION ===");
        console.log("Block starting from: 19636129");
        console.log("Key fix: wstETH address corrected to 0x76D8de471F54aAA87784119c60Df1bbFc852C415");
        
        // Deploy new core implementation with fixed wstETH address
        HorizonCircleCore newCore = new HorizonCircleCore();
        console.log("New core implementation deployed:", address(newCore));
        
        // Deploy a test circle with the new implementation
        bytes32 salt = keccak256(abi.encodePacked("FixedCore", msg.sender, block.timestamp));
        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d3d363d73",
            address(newCore),
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circleAddress;
        assembly {
            circleAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(circleAddress) { revert(0, 0) }
        }
        console.log("Test circle with fixed core:", circleAddress);
        
        console.log("");
        console.log("DEPLOYMENT SUMMARY:");
        console.log("- New Core Implementation:", address(newCore));
        console.log("- Test Circle Address:", circleAddress);
        console.log("- wstETH Address Fixed: 0x76D8de471F54aAA87784119c60Df1bbFc852C415");
        console.log("- All DeFi integration addresses corrected");
        console.log("");
        console.log("Next: Initialize circle and test contribution logic");
        
        vm.stopBroadcast();
    }
}
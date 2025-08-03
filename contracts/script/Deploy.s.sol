// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOYING CONTRACTS FOR VERIFICATION ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy each contract individually to avoid conflicts
        
        // Implementation
        bytes memory implementationBytecode = abi.encodePacked(vm.getCode("HorizonCircleWithMorphoAuth"));
        address implementation;
        assembly {
            implementation := create2(0, add(implementationBytecode, 0x20), mload(implementationBytecode), "impl")
        }
        console.log("Implementation:", implementation);
        
        // Lending Module  
        bytes memory lendingBytecode = abi.encodePacked(vm.getCode("LendingModuleSimplified"));
        address lendingModule;
        assembly {
            lendingModule := create2(0, add(lendingBytecode, 0x20), mload(lendingBytecode), "lend")
        }
        console.log("LendingModule:", lendingModule);
        
        // Fund lending module
        payable(lendingModule).transfer(0.001 ether);
        console.log("Funded lending module with 0.001 ETH");
        
        vm.stopBroadcast();
        
        console.log("\n=== VERIFICATION COMMANDS ===");
        console.log("Implementation:");
        console.log("forge verify-contract", implementation, "src/HorizonCircleWithMorphoAuth.sol:HorizonCircleWithMorphoAuth --rpc-url https://rpc.api.lisk.com --verifier blockscout --verifier-url https://blockscout.lisk.com/api --compiler-version 0.8.20");
        console.log("\nLendingModule:");
        console.log("forge verify-contract", lendingModule, "src/LendingModuleSimplified.sol:LendingModuleSimplified --rpc-url https://rpc.api.lisk.com --verifier blockscout --verifier-url https://blockscout.lisk.com/api --compiler-version 0.8.20");
    }
}
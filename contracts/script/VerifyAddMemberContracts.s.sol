// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract VerifyAddMemberContracts is Script {
    function run() external {
        console.log("Verifying contracts on Lisk Blockscout...");
        
        // Implementation with addMember: 0x8F131C8A090CED5af97Ba94C8698479eDe136eA8
        console.log("Implementation to verify: 0x8F131C8A090CED5af97Ba94C8698479eDe136eA8");
        console.log("Contract name: HorizonCircleWithMorphoAuth");
        console.log("Source file: src/HorizonCircleWithMorphoAuth.sol");
        
        // Factory with addMember: 0x8095cd40DaC4fb335Aa761B9d85bC8A9c24f0658
        console.log("Factory to verify: 0x8095cd40DaC4fb335Aa761B9d85bC8A9c24f0658");
        console.log("Contract name: HorizonCircleMinimalProxyWithModules");
        console.log("Source file: src/HorizonCircleMinimalProxyWithModules.sol");
        
        console.log("");
        console.log("VERIFICATION COMMANDS:");
        console.log("Run these commands to verify on Lisk Blockscout:");
        console.log("");
        
        // Implementation verification
        console.log("1. Verify Implementation:");
        console.log("forge verify-contract \\");
        console.log("  0x8F131C8A090CED5af97Ba94C8698479eDe136eA8 \\");
        console.log("  src/HorizonCircleWithMorphoAuth.sol:HorizonCircleWithMorphoAuth \\");
        console.log("  --verifier-url 'https://blockscout.lisk.com/api' \\");
        console.log("  --etherscan-api-key 'verifyContract' \\");
        console.log("  --num-of-optimizations 200 \\");
        console.log("  --compiler-version v0.8.20+commit.a1b79de6");
        
        console.log("");
        
        // Factory verification
        console.log("2. Verify Factory:");
        console.log("forge verify-contract \\");
        console.log("  0x8095cd40DaC4fb335Aa761B9d85bC8A9c24f0658 \\");
        console.log("  src/HorizonCircleMinimalProxyWithModules.sol:HorizonCircleMinimalProxyWithModules \\");
        console.log("  --verifier-url 'https://blockscout.lisk.com/api' \\");
        console.log("  --etherscan-api-key 'verifyContract' \\");
        console.log("  --num-of-optimizations 200 \\");
        console.log("  --compiler-version v0.8.20+commit.a1b79de6 \\");
        console.log("  --constructor-args $(cast abi-encode 'constructor(address,address,address,address)' 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE 0x8F131C8A090CED5af97Ba94C8698479eDe136eA8 0x1E394C5740f3b04b4a930EC843a43d1d49Ddbd2A 0x96F582fAF5a1D61640f437EBea9758b18a678720)");
        
        console.log("");
        console.log("After verification, these contracts will have visible source code on Lisk Blockscout!");
    }
}
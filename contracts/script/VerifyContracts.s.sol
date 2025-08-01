// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract VerifyContracts is Script {
    function run() external {
        console.log("HorizonCircle Contract Verification Commands for Blockscout");
        console.log("==========================================================");
        console.log("");
        
        console.log("1. Factory Contract:");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --num-of-optimizations 200 \\");
        console.log("  --compiler-version v0.8.20+commit.a1b79de6 \\");
        console.log("  --verifier blockscout \\");
        console.log("  --verifier-url https://blockscout.lisk.com/api \\");
        console.log("  0x95e4c63Ee7e82b94D75dDbF858F0D2D0600fcCdD \\");
        console.log("  src/HorizonCircleModularFactory.sol:HorizonCircleModularFactory");
        console.log("");
        
        console.log("2. Registry Contract:");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --num-of-optimizations 200 \\");
        console.log("  --compiler-version v0.8.20+commit.a1b79de6 \\");
        console.log("  --verifier blockscout \\");
        console.log("  --verifier-url https://blockscout.lisk.com/api \\");
        console.log("  0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE \\");
        console.log("  src/CircleRegistry.sol:CircleRegistry");
        console.log("");
        
        console.log("3. Implementation Contract:");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --num-of-optimizations 200 \\");
        console.log("  --compiler-version v0.8.20+commit.a1b79de6 \\");
        console.log("  --verifier blockscout \\");
        console.log("  --verifier-url https://blockscout.lisk.com/api \\");
        console.log("  0x763004aE80080C36ec99eC5f2dc3F2C260638A83 \\");
        console.log("  src/HorizonCircleWithMorphoAuth.sol:HorizonCircleWithMorphoAuth");
        console.log("");
        
        console.log("4. Lending Module Contract:");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --num-of-optimizations 200 \\");
        console.log("  --compiler-version v0.8.20+commit.a1b79de6 \\");
        console.log("  --verifier blockscout \\");
        console.log("  --verifier-url https://blockscout.lisk.com/api \\");
        console.log("  0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801 \\");
        console.log("  src/LendingModuleSimplified.sol:LendingModuleSimplified");
        console.log("");
        
        console.log("NOTE: Make sure you're in the contracts directory when running these commands.");
        console.log("If verification fails, you may need to:");
        console.log("1. Check if the contract source matches exactly");
        console.log("2. Verify constructor arguments if any were used");
        console.log("3. Try using --etherscan instead of --verifier blockscout");
        console.log("");
        console.log("Alternative manual verification:");
        console.log("Visit https://blockscout.lisk.com/address/[CONTRACT_ADDRESS]/contract-verification");
    }
}
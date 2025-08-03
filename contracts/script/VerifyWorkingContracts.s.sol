// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract VerifyWorkingContracts is Script {
    function run() external {
        console.log("=== VERIFY WORKING CONTRACTS ON BLOCKSCOUT ===");
        console.log("");
        console.log("IMPORTANT: Make sure ETHERSCAN_API_KEY is set in your .env file");
        console.log("Note: Lisk uses Blockscout, so verification might work differently than Etherscan");
        console.log("");
        
        console.log("=== 1. VERIFY REGISTRY (0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE) ===");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --verifier blockscout \\");
        console.log("  --verifier-url https://blockscout.lisk.com/api/ \\");
        console.log("  0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE \\");
        console.log("  src/CircleRegistry.sol:CircleRegistry");
        console.log("");
        
        console.log("=== 2. VERIFY IMPLEMENTATION (0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56) ===");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --verifier blockscout \\");
        console.log("  --verifier-url https://blockscout.lisk.com/api/ \\");
        console.log("  0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56 \\");
        console.log("  src/HorizonCircleWithMorphoAuth.sol:HorizonCircleWithMorphoAuth");
        console.log("");
        
        console.log("=== 3. VERIFY LENDING MODULE (0x96F582fAF5a1D61640f437EBea9758b18a678720) ===");
        console.log("# Constructor arg: morphoVault address");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --verifier blockscout \\");
        console.log("  --verifier-url https://blockscout.lisk.com/api/ \\");
        console.log("  --constructor-args $(cast abi-encode \"constructor(address)\" 0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346) \\");
        console.log("  0x96F582fAF5a1D61640f437EBea9758b18a678720 \\");
        console.log("  src/LendingModuleSimplified.sol:LendingModuleSimplified");
        console.log("");
        
        console.log("=== 4. VERIFY SWAP MODULE (0x68E6b55D4EB478C736c9c19020adD14E7aB35d92) ===");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --verifier blockscout \\");
        console.log("  --verifier-url https://blockscout.lisk.com/api/ \\");
        console.log("  0x68E6b55D4EB478C736c9c19020adD14E7aB35d92 \\");
        console.log("  src/SwapModuleFixed.sol:SwapModuleFixed");
        console.log("");
        
        console.log("=== 5. FACTORY (0x757A109a1b45174DD98fe7a8a72c8f343d200570) ===");
        console.log("NOTE: This factory contract is defined inline in DeployFactoryWithModules.s.sol");
        console.log("It needs special handling for verification.");
        console.log("");
        console.log("First, extract the contract to its own file:");
        console.log("1. Copy the HorizonCircleMinimalProxyWithModules contract from DeployFactoryWithModules.s.sol");
        console.log("2. Save it as src/HorizonCircleMinimalProxyWithModules.sol");
        console.log("3. Then verify with:");
        console.log("");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --verifier blockscout \\");
        console.log("  --verifier-url https://blockscout.lisk.com/api/ \\");
        console.log("  --constructor-args $(cast abi-encode \"constructor(address,address,address,address)\" 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92 0x96F582fAF5a1D61640f437EBea9758b18a678720) \\");
        console.log("  0x757A109a1b45174DD98fe7a8a72c8f343d200570 \\");
        console.log("  src/HorizonCircleMinimalProxyWithModules.sol:HorizonCircleMinimalProxyWithModules");
        console.log("");
        
        console.log("=== ALTERNATIVE: Try standard verification (without blockscout flags) ===");
        console.log("Some explorers work better without explicit blockscout configuration:");
        console.log("");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --watch \\");
        console.log("  <CONTRACT_ADDRESS> \\");
        console.log("  <CONTRACT_PATH>:<CONTRACT_NAME>");
    }
}
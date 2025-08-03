// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract VerifyAllContracts is Script {
    function run() external {
        console.log("=== CONTRACT VERIFICATION STATUS ===");
        console.log("");
        console.log("Working Contracts:");
        console.log("- Factory: 0x757A109a1b45174DD98fe7a8a72c8f343d200570");
        console.log("- Registry: 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE");
        console.log("- Implementation: 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56");
        console.log("- Lending Module: 0x96F582fAF5a1D61640f437EBea9758b18a678720");
        console.log("- Swap Module: 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92");
        console.log("");
        console.log("=== VERIFICATION COMMANDS ===");
        console.log("");
        
        console.log("1. FACTORY - Check if it's HorizonCircleMinimalProxy or a variant:");
        console.log("# First try HorizonCircleMinimalProxy (2 params):");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --watch \\");
        console.log("  --constructor-args $(cast abi-encode \"constructor(address,address)\" 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56) \\");
        console.log("  0x757A109a1b45174DD98fe7a8a72c8f343d200570 \\");
        console.log("  src/HorizonCircleMinimalProxy.sol:HorizonCircleMinimalProxy");
        console.log("");
        
        console.log("2. REGISTRY - CircleRegistry:");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --watch \\");
        console.log("  0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE \\");
        console.log("  src/CircleRegistry.sol:CircleRegistry");
        console.log("");
        
        console.log("3. IMPLEMENTATION - HorizonCircleWithMorphoAuth:");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --watch \\");
        console.log("  0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56 \\");
        console.log("  src/HorizonCircleWithMorphoAuth.sol:HorizonCircleWithMorphoAuth");
        console.log("");
        
        console.log("4. LENDING MODULE - LendingModuleSimplified:");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --watch \\");
        console.log("  --constructor-args $(cast abi-encode \"constructor(address)\" 0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346) \\");
        console.log("  0x96F582fAF5a1D61640f437EBea9758b18a678720 \\");
        console.log("  src/LendingModuleSimplified.sol:LendingModuleSimplified");
        console.log("");
        
        console.log("5. SWAP MODULE - SwapModuleFixed:");
        console.log("forge verify-contract \\");
        console.log("  --chain-id 1135 \\");
        console.log("  --watch \\");
        console.log("  0x68E6b55D4EB478C736c9c19020adD14E7aB35d92 \\");
        console.log("  src/SwapModuleFixed.sol:SwapModuleFixed");
        console.log("");
        
        console.log("NOTE: The working circle (0x690E510D174E67EfB687fCbEae5D10362924AbaC) is a proxy");
        console.log("and doesn't need separate verification.");
        console.log("");
        console.log("IMPORTANT: Set ETHERSCAN_API_KEY in your .env file first!");
    }
}
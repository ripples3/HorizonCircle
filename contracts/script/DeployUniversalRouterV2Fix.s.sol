// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleImplementation.sol";

contract DeployUniversalRouterV2Fix is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying UNIVERSAL ROUTER V2 FACTORY FIX ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        // Deploy implementation with corrected Universal Router (V2 factory instead of CL factory)
        HorizonCircleImplementation implementation = new HorizonCircleImplementation();
        console.log("Implementation deployed at:", address(implementation));
        
        // Verify the key configurations
        console.log("BASIS_POINTS:", implementation.BASIS_POINTS()); // Should be 10000
        console.log("MAX_SLIPPAGE:", implementation.MAX_SLIPPAGE()); // Should be 50 (0.5%)
        console.log("VELODROME_FACTORY_V2:", implementation.VELODROME_FACTORY_V2());
        console.log("VELODROME_ROUTER:", implementation.VELODROME_ROUTER());

        vm.stopBroadcast();

        console.log("\n=== UNIVERSAL ROUTER V2 FACTORY FIX COMPLETE ===");
        console.log("IMPLEMENTATION:", address(implementation));
        console.log("FEATURES:");
        console.log("- Universal Router with V2 factory (industry standard)");
        console.log("- Fixes router validation issue that was caused by CL factory");
        console.log("- ERC4626 previewWithdraw() for exact withdrawals");  
        console.log("- Industry standard basis points and slippage protection");
        console.log("STATUS: Final production solution ready for testing");
    }
}
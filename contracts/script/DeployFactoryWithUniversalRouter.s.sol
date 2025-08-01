// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";

contract DeployFactoryWithUniversalRouter is Script {
    address constant REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC; // Existing registry
    address constant UNIVERSAL_ROUTER_IMPLEMENTATION = 0x2C1a9fCdFf10097aEEafeAc8f621fACF5E6578Df; // Universal Router solution
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying Factory with Universal Router Solution ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Registry:", REGISTRY);
        console.log("Implementation:", UNIVERSAL_ROUTER_IMPLEMENTATION);

        // Deploy factory pointing to Universal Router implementation
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            UNIVERSAL_ROUTER_IMPLEMENTATION
        );
        console.log("Factory deployed at:", address(factory));

        vm.stopBroadcast();

        console.log("\n=== FINAL INDUSTRY STANDARD DEPLOYMENT ===");
        console.log("REGISTRY:", REGISTRY);
        console.log("FACTORY:", address(factory));
        console.log("IMPLEMENTATION:", UNIVERSAL_ROUTER_IMPLEMENTATION);
        console.log("SOLUTION: Universal Router DEX integration (industry standard)");
        console.log("BASIS POINTS: 10000 (industry standard)");
        console.log("SLIPPAGE: 0.5% (properly calculated)");
        console.log("ERC4626: previewWithdraw() for exact withdrawals");
        console.log("READY FOR PRODUCTION TESTING");
    }
}
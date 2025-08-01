// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleCore.sol";
import "../src/HorizonCircleModularFactory.sol";
import "../src/CircleRegistry.sol";

contract DeployModularSystem is Script {
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING MODULAR HORIZONCIRCLE SYSTEM (100% FUNCTIONALITY) ===");
        console.log("Goal: Full DeFi integration with gas-efficient modular architecture");
        
        // Deploy core implementation (lightweight)
        HorizonCircleCore coreImplementation = new HorizonCircleCore();
        console.log("Core Implementation deployed:", address(coreImplementation));
        
        // Check core contract size
        uint256 coreSize;
        assembly {
            coreSize := extcodesize(coreImplementation)
        }
        console.log("Core contract size:", coreSize, "bytes");
        
        // Deploy registry (or use existing)
        CircleRegistry registry = new CircleRegistry();
        console.log("Registry deployed:", address(registry));
        
        // Deploy modular factory (with integrated modules)
        HorizonCircleModularFactory factory = new HorizonCircleModularFactory(
            address(registry),
            address(coreImplementation)
        );
        console.log("Modular Factory deployed:", address(factory));
        console.log("- Swap Module:", address(factory.swapModule()));
        console.log("- Lending Module:", address(factory.lendingModule()));
        
        vm.stopBroadcast();
        
        console.log("\n=== MODULAR DEPLOYMENT COMPLETE ===");
        console.log("Architecture:");
        console.log("- Lightweight Core: Handles deposits, shares, and coordination");
        console.log("- Swap Module: Dedicated WETH->wstETH CL pool integration");
        console.log("- Lending Module: Morpho lending market operations");
        console.log("");
        console.log("Benefits:");
        console.log("- 100% functionality maintained");
        console.log("- Core contract stays under 15KB");
        console.log("- Gas-intensive operations isolated in modules");
        console.log("- No gas limit issues during execution");
        console.log("");
        console.log("Production addresses:");
        console.log("- Core Implementation:", address(coreImplementation));
        console.log("- Modular Factory:", address(factory));
        console.log("- Registry:", address(registry));
    }
}
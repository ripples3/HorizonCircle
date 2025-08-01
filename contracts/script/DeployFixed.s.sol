// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleCore.sol";
import "../src/HorizonCircleModularFactory.sol";
import "../src/CircleRegistry.sol";

contract DeployFixed is Script {
    function run() external {
        // Get private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== DEPLOYING WITH PROPER PRIVATE KEY ==");
        console.log("Deploying from:", vm.addr(deployerPrivateKey));
        
        // Deploy clean implementation
        HorizonCircleCore implementation = new HorizonCircleCore();
        console.log("Implementation deployed:", address(implementation));
        
        // Check implementation size
        uint256 implSize;
        assembly {
            implSize := extcodesize(implementation)
        }
        console.log("Implementation size:", implSize, "bytes");
        require(implSize > 0, "Implementation not deployed");
        require(implSize < 24576, "Implementation too large");
        
        // Deploy registry
        CircleRegistry registry = new CircleRegistry();
        console.log("Registry deployed:", address(registry));
        
        // Deploy factory
        HorizonCircleModularFactory factory = new HorizonCircleModularFactory(
            address(registry),
            address(implementation)
        );
        console.log("Factory deployed:", address(factory));
        console.log("- Swap Module:", address(factory.swapModule()));
        console.log("- Lending Module:", address(factory.lendingModule()));
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Ready for testing:");
        console.log("- Factory:", address(factory));
        console.log("- Registry:", address(registry));
        console.log("- Implementation:", address(implementation));
    }
}
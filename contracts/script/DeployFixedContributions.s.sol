// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleCore.sol";
import "../src/HorizonCircleModularFactory.sol";
import "../src/CircleRegistry.sol";

contract DeployFixedContributions is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== DEPLOYING FIXED CONTRIBUTION LOGIC ===");
        console.log("Deploying from:", vm.addr(deployerPrivateKey));
        
        // Deploy fixed implementation with proper contribution logic
        HorizonCircleCore implementation = new HorizonCircleCore();
        console.log("Fixed Implementation deployed:", address(implementation));
        
        // Check implementation size
        uint256 implSize;
        assembly {
            implSize := extcodesize(implementation)
        }
        console.log("Implementation size:", implSize, "bytes");
        require(implSize > 0, "Implementation not deployed");
        require(implSize < 24576, "Implementation too large");
        
        // Deploy new registry for fixed contracts
        CircleRegistry registry = new CircleRegistry();
        console.log("Registry deployed:", address(registry));
        
        // Deploy factory with fixed implementation
        HorizonCircleModularFactory factory = new HorizonCircleModularFactory(
            address(registry),
            address(implementation)
        );
        console.log("Factory deployed:", address(factory));
        console.log("- Swap Module:", address(factory.swapModule()));
        console.log("- Lending Module:", address(factory.lendingModule()));
        
        vm.stopBroadcast();
        
        console.log("\n=== FIXED CONTRACTS DEPLOYED ===");
        console.log("Ready for testing:");
        console.log("- Factory:", address(factory));
        console.log("- Registry:", address(registry));
        console.log("- Implementation:", address(implementation));
        console.log("\nKey fixes:");
        console.log("- contributeToRequest() now actually deducts vault shares");
        console.log("- executeRequest() no longer double-deducts shares");
        console.log("- Social lending contributions are now real and immediate");
    }
}
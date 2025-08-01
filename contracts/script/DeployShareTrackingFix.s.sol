// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleCore.sol";
import "../src/HorizonCircleModularFactory.sol";
import "../src/CircleRegistry.sol";

contract DeployShareTrackingFix is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== DEPLOYING SHARE TRACKING FIX ===");
        console.log("Deploying from:", vm.addr(deployerPrivateKey));
        
        // Deploy fixed implementation with share tracking
        HorizonCircleCore implementation = new HorizonCircleCore();
        console.log("Share Tracking Implementation deployed:", address(implementation));
        
        // Check implementation size
        uint256 implSize;
        assembly {
            implSize := extcodesize(implementation)
        }
        console.log("Implementation size:", implSize, "bytes");
        require(implSize > 0, "Implementation not deployed");
        require(implSize < 24576, "Implementation too large");
        
        // Use existing working registry
        address workingRegistry = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
        
        // Deploy factory with share tracking fix
        HorizonCircleModularFactory factory = new HorizonCircleModularFactory(
            workingRegistry,
            address(implementation)
        );
        console.log("Share Tracking Factory deployed:", address(factory));
        console.log("- Swap Module:", address(factory.swapModule()));
        console.log("- Lending Module:", address(factory.lendingModule()));
        
        vm.stopBroadcast();
        
        console.log("\n=== SHARE TRACKING FIX DEPLOYED ===");
        console.log("Key improvements:");
        console.log("- Tracks actual shares contributed to each request");
        console.log("- Uses tracked shares instead of recalculating during execution");
        console.log("- Eliminates ERC4626 precision/rounding issues");
        console.log("- Factory:", address(factory));
        console.log("- Implementation:", address(implementation));
    }
}
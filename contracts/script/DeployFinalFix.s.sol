// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleCore.sol";
import "../src/HorizonCircleModularFactory.sol";

contract DeployFinalFix is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== DEPLOYING FINAL FIX ===");
        
        // Deploy fixed implementation
        HorizonCircleCore implementation = new HorizonCircleCore();
        console.log("Final Implementation deployed:", address(implementation));
        
        // Deploy factory with final fix
        HorizonCircleModularFactory factory = new HorizonCircleModularFactory(
            0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE, // existing registry
            address(implementation)
        );
        console.log("Final Factory deployed:", address(factory));
        
        vm.stopBroadcast();
        
        console.log("\nFIX: Removed strict WETH amount validation");
        console.log("Now uses whatever WETH the vault redemption provides");
    }
}
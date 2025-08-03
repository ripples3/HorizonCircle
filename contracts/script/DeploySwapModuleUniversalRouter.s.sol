// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SwapModuleUniversalRouter.sol";

contract DeploySwapModuleUniversalRouter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOY UNIVERSAL ROUTER SWAP MODULE ===");
        console.log("Using industry standard Velodrome Universal Router");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the Universal Router based SwapModule
        SwapModuleUniversalRouter swapModule = new SwapModuleUniversalRouter();
        console.log("SwapModuleUniversalRouter deployed:", address(swapModule));
        console.log("Owner:", swapModule.owner());
        console.log("Universal Router:", 0x01D40099fCD87C018969B0e8D4aB1633Fb34763C);
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("This module uses the same Universal Router that processes");
        console.log("millions in daily volume on Velodrome");
    }
}
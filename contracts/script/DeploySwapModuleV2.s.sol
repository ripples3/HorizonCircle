// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/SwapModuleV2.sol";

contract DeploySwapModuleV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOYING SWAP MODULE V2 ===");
        console.log("Fixing Velodrome pool swap execution issue");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy improved swap module
        SwapModuleV2 swapModule = new SwapModuleV2();
        
        console.log("SUCCESS: SwapModuleV2 deployed at:", address(swapModule));
        console.log("Pool:", 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3);
        console.log("WETH:", 0x4200000000000000000000000000000000000006);
        console.log("wstETH:", 0x76D8de471F54aAA87784119c60Df1bbFc852C415);
        
        // Check token order in pool
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("SwapModuleV2 address:", address(swapModule));
        console.log("WETH is token0:", swapModule.wethIsToken0());
        console.log("Ready for testing with corrected token ordering");
    }
}
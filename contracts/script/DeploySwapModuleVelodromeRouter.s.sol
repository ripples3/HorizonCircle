// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/SwapModuleVelodromeRouter.sol";

contract DeploySwapModuleVelodromeRouter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOYING VELODROME ROUTER SWAP MODULE ===");
        console.log("Using industry standard Velodrome Router approach");
        console.log("Router:", 0x3a63171DD9BebF4D07BC782FECC7eb0b890C2A45);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy router-based swap module
        SwapModuleVelodromeRouter swapModule = new SwapModuleVelodromeRouter();
        
        console.log("SUCCESS: SwapModuleVelodromeRouter deployed at:", address(swapModule));
        console.log("WETH:", 0x4200000000000000000000000000000000000006);
        console.log("wstETH:", 0x76D8de471F54aAA87784119c60Df1bbFc852C415);
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Industry standard Velodrome Router implementation ready");
        console.log("This should resolve CL pool liquidity issues");
    }
}
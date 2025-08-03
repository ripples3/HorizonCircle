// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/SwapModuleIndustryStandard.sol";

contract DeploySwapModuleIndustryStandard is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOYING INDUSTRY STANDARD SWAP MODULE ===");
        console.log("Using Uniswap V3 compatible patterns");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy industry standard swap module
        SwapModuleIndustryStandard swapModule = new SwapModuleIndustryStandard();
        
        console.log("SUCCESS: SwapModuleIndustryStandard deployed at:", address(swapModule));
        console.log("Pool:", 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3);
        console.log("WETH:", 0x4200000000000000000000000000000000000006);
        console.log("wstETH:", 0x76D8de471F54aAA87784119c60Df1bbFc852C415);
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Industry standard implementation ready for testing");
        console.log("Ready for TestSwapIndustryStandard.s.sol");
    }
}
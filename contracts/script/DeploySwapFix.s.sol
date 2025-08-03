// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SwapModuleFixed.sol";

contract DeploySwapFix is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOY FIXED SWAP MODULE ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        SwapModuleFixed swapModule = new SwapModuleFixed();
        console.log("SwapModuleFixed deployed:", address(swapModule));
        
        vm.stopBroadcast();
        
        console.log("\\n=== NEXT STEPS ===");
        console.log("1. Test with existing circle contracts");
        console.log("2. Replace swap module address in working factory");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PoolTester.sol";

contract DeployAndTestPool is Script {
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING POOL TESTER ===");
        
        // Deploy the pool tester
        PoolTester tester = new PoolTester();
        console.log("PoolTester deployed at:", address(tester));
        
        // Test the swap with 0.001 ETH
        console.log("Testing swap with 0.001 ETH...");
        tester.testSwap{value: 0.001 ether}();
        
        console.log("Test completed - check events for results");
        
        vm.stopBroadcast();
    }
}
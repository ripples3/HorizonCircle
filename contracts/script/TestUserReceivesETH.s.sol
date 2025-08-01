// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract TestUserReceivesETH is Script {
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING IF USER CAN RECEIVE ETH ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Check user balance before
        uint256 balanceBefore = USER.balance;
        console.log("User balance before:", balanceBefore);
        
        // Send ETH directly to user
        uint256 testAmount = 0.00001 ether; // 10 microETH
        console.log("Sending test amount:", testAmount);
        
        (bool success, ) = USER.call{value: testAmount}("");
        
        // Check user balance after
        uint256 balanceAfter = USER.balance;
        uint256 received = balanceAfter - balanceBefore;
        
        console.log("User balance after:", balanceAfter);
        console.log("ETH received:", received);
        console.log("Transfer success:", success);
        
        if (received > 0 && success) {
            console.log("SUCCESS: User can receive ETH");
        } else {
            console.log("FAILURE: User cannot receive ETH");
        }
        
        vm.stopBroadcast();
    }
}
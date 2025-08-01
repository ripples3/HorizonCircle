// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract TestSendToUser is Script {
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== TESTING SENDING ETH FROM DEPLOYER TO USER ===");
        console.log("Deployer:", deployer);
        console.log("User:", USER);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Check balances before
        uint256 deployerBefore = deployer.balance;
        uint256 userBefore = USER.balance;
        
        console.log("Deployer balance before:", deployerBefore);
        console.log("User balance before:", userBefore);
        
        // Send ETH from deployer to user
        uint256 testAmount = 0.00001 ether; // 10 microETH
        console.log("Sending from deployer to user:", testAmount);
        
        (bool success, ) = USER.call{value: testAmount}("");
        
        // Check balances after
        uint256 deployerAfter = deployer.balance;
        uint256 userAfter = USER.balance;
        uint256 userReceived = userAfter - userBefore;
        
        console.log("Deployer balance after:", deployerAfter);
        console.log("User balance after:", userAfter);
        console.log("User ETH received:", userReceived);
        console.log("Transfer success:", success);
        
        if (userReceived > 0 && success) {
            console.log("SUCCESS: User CAN receive ETH from other addresses!");
            console.log("The lending module issue is elsewhere.");
        } else {
            console.log("FAILURE: User cannot receive ETH");
        }
        
        vm.stopBroadcast();
    }
}
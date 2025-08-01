// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract FundAndTestLendingModule is Script {
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== FUNDING EXISTING LENDING MODULE TO FIX THE ISSUE ===");
        console.log("Lending Module:", LENDING_MODULE);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Check current balance
        uint256 balanceBefore = LENDING_MODULE.balance;
        console.log("Module ETH balance before:", balanceBefore);
        
        // Fund the lending module with ETH
        uint256 fundingAmount = 0.0001 ether; // 100 microETH for testing
        console.log("Funding module with:", fundingAmount);
        
        (bool success, ) = LENDING_MODULE.call{value: fundingAmount}("");
        require(success, "Funding failed");
        
        // Check balance after funding
        uint256 balanceAfter = LENDING_MODULE.balance;
        console.log("Module ETH balance after:", balanceAfter);
        console.log("Funding increase:", balanceAfter - balanceBefore);
        
        if (balanceAfter > balanceBefore) {
            console.log("\n*** SUCCESS! LENDING MODULE NOW HAS ETH ***");
            console.log("Module address:", LENDING_MODULE);
            console.log("ETH balance:", balanceAfter);
            console.log("This should fix the user receiving 0 ETH issue");
            console.log("\nNext steps:");
            console.log("1. Create a circle that uses this funded module");
            console.log("2. Authorize the circle in the module");
            console.log("3. Test loan execution - user should receive ETH");
        } else {
            console.log("\n*** ISSUE: Funding didn't increase balance ***");
        }
        
        vm.stopBroadcast();
    }
}
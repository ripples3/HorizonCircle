// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircle.sol";

contract TestDirectBorrow is Script {
    function run() external {
        // Use private key from environment
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey;
        
        if (bytes(pkString).length == 66 && bytes(pkString)[0] == "0" && bytes(pkString)[1] == "x") {
            deployerPrivateKey = vm.parseUint(pkString);
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        address user = vm.addr(deployerPrivateKey);
        console.log("=== DIRECT BORROW UNIVERSAL ROUTER TEST ===");
        console.log("User address:", user);
        console.log("Initial balance:", user.balance, "wei");
        
        // Deploy new circle with direct borrow functionality
        address[] memory initialMembers = new address[](1);
        initialMembers[0] = user;
        
        console.log("Deploying new circle with borrowDirectly function...");
        
        try new HorizonCircle(
            "Direct Borrow Test Circle",
            initialMembers,
            address(0)
        ) returns (HorizonCircle circle) {
            console.log("SUCCESS: Circle deployed at:", address(circle));
            console.log("CL Pool (Direct):", "0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3");
            
            // Test deposit
            uint256 depositAmount = user.balance / 3;
            console.log("Depositing:", depositAmount, "wei");
            
            circle.deposit{value: depositAmount}();
            console.log("Deposited successfully. Shares:", circle.userShares(user));
            
            // Test direct borrow - this will trigger Universal Router swap
            uint256 borrowAmount = 5000000000000; // 0.000005 ETH
            console.log("Direct borrowing:", borrowAmount, "wei");
            console.log("This will test the Universal Router ETH->wstETH swap!");
            
            // Get balances before
            uint256 ethBefore = user.balance;
            IERC20 wsteth = IERC20(0x76D8de471F54aAA87784119c60Df1bbFc852C415);
            uint256 wstethBefore = wsteth.balanceOf(address(circle));
            
            bytes32 loanId = circle.borrowDirectly(borrowAmount, "Universal Router test");
            
            // Check balances after
            uint256 ethAfter = user.balance;
            uint256 wstethAfter = wsteth.balanceOf(address(circle));
            
            console.log("SUCCESS: Direct borrow completed!");
            console.log("Loan ID:");
            console.logBytes32(loanId);
            console.log("ETH received:", ethAfter > ethBefore ? ethAfter - ethBefore : 0);
            console.log("wstETH collateral:", wstethAfter > wstethBefore ? wstethAfter - wstethBefore : 0);
            
            if (wstethAfter > wstethBefore) {
                console.log("CONFIRMED: Universal Router ETH->wstETH swap SUCCESS!");
                console.log("Velodrome integration working perfectly!");
            }
            
        } catch Error(string memory reason) {
            console.log("FAILED: Circle deployment failed -", reason);
        } catch (bytes memory lowLevelData) {
            console.log("FAILED: Circle deployment failed with low-level error");
            console.logBytes(lowLevelData);
        }
        
        console.log("\n=== DIRECT BORROW TEST COMPLETE ===");
        
        vm.stopBroadcast();
    }
}
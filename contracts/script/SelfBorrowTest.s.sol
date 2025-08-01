// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircle.sol";

contract SelfBorrowTest is Script {
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
        console.log("=== SELF-BORROW UNIVERSAL ROUTER TEST ===");
        console.log("User address:", user);
        console.log("Initial balance:", user.balance, "wei");
        
        // Use the deployed Universal Router circle
        address contractAddress = 0xE9ce006Ed0006623e1E18E0fcf5C34eD65A89b0c;
        HorizonCircle circle = HorizonCircle(payable(contractAddress));
        
        console.log("Circle:", contractAddress);
        console.log("Is user a member:", circle.isCircleMember(user));
        
        // Check current deposits
        uint256 currentShares = circle.userShares(user);
        console.log("Current user shares:", currentShares);
        
        // If no shares, make a deposit first
        if (currentShares == 0) {
            uint256 depositAmount = user.balance / 3; // Use 1/3 of balance
            console.log("Making initial deposit:", depositAmount, "wei");
            
            try circle.deposit{value: depositAmount}() {
                currentShares = circle.userShares(user);
                console.log("SUCCESS: Deposited. New shares:", currentShares);
            } catch Error(string memory reason) {
                console.log("FAILED: Deposit failed -", reason);
                vm.stopBroadcast();
                return;
            }
        }
        
        // Step 1: Create a self-borrow request
        console.log("\n=== STEP 1: CREATE SELF-BORROW REQUEST ===");
        
        uint256 minContribution = 1000000000000; // 0.000001 ETH minimum
        uint256 borrowAmount = minContribution * 10; // Borrow 0.00001 ETH
        uint256 collateralAmount = borrowAmount; // 100% collateralization from own deposits
        
        console.log("Borrow amount:", borrowAmount, "wei");
        console.log("Collateral from own deposits:", collateralAmount, "wei");
        
        // Self-contribute: user is both borrower and contributor
        address[] memory contributors = new address[](1);
        contributors[0] = user; // Self-contribute
        uint256[] memory contributorAmounts = new uint256[](1);
        contributorAmounts[0] = collateralAmount;
        
        bytes32 requestId;
        try circle.requestCollateral(
            borrowAmount,
            collateralAmount,
            contributors,
            contributorAmounts,
            "Self-borrow Universal Router test"
        ) returns (bytes32 _requestId) {
            requestId = _requestId;
            console.log("SUCCESS: Self-borrow request created");
            console.log("Request ID:");
            console.logBytes32(requestId);
        } catch Error(string memory reason) {
            console.log("FAILED: Request creation failed -", reason);
            vm.stopBroadcast();
            return;
        }
        
        // Wait a moment for the request to be processed
        console.log("\n=== STEP 2: SELF-CONTRIBUTE ===");
        
        try circle.contributeToRequest(requestId) {
            console.log("SUCCESS: Self-contribution completed");
        } catch Error(string memory reason) {
            console.log("FAILED: Self-contribution failed -", reason);
            console.log("This might indicate the request system needs debugging");
            vm.stopBroadcast();
            return;
        }
        
        // Step 3: Execute the request - this should trigger Universal Router swap
        console.log("\n=== STEP 3: EXECUTE LOAN (Universal Router Test) ===");
        console.log("This will test ETH -> wstETH swap via Universal Router");
        
        uint256 ethBalanceBefore = user.balance;
        IERC20 wsteth = IERC20(0x76D8de471F54aAA87784119c60Df1bbFc852C415);
        uint256 wstethBalanceBefore = wsteth.balanceOf(address(circle));
        
        console.log("ETH balance before:", ethBalanceBefore);
        console.log("Circle wstETH balance before:", wstethBalanceBefore);
        
        try circle.executeRequest(requestId) {
            console.log("SUCCESS: Loan executed with Universal Router!");
            
            // Check balances after
            uint256 ethBalanceAfter = user.balance;
            uint256 wstethBalanceAfter = wsteth.balanceOf(address(circle));
            
            console.log("ETH balance after:", ethBalanceAfter);
            console.log("Circle wstETH balance after:", wstethBalanceAfter);
            console.log("ETH borrowed:", ethBalanceAfter > ethBalanceBefore ? ethBalanceAfter - ethBalanceBefore : 0);
            console.log("wstETH collateral:", wstethBalanceAfter > wstethBalanceBefore ? wstethBalanceAfter - wstethBalanceBefore : 0);
            
            if (wstethBalanceAfter > wstethBalanceBefore) {
                console.log("CONFIRMED: Universal Router ETH->wstETH swap working!");
                console.log("Velodrome concentrated liquidity integration successful");
            }
            
        } catch Error(string memory reason) {
            console.log("FAILED: Loan execution failed -", reason);
        } catch (bytes memory lowLevelData) {
            console.log("FAILED: Loan execution failed with low-level error");
            console.logBytes(lowLevelData);
        }
        
        console.log("\n=== SELF-BORROW TEST COMPLETE ===");
        
        vm.stopBroadcast();
    }
}
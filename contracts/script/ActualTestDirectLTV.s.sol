// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleCore.sol";
import "../src/HorizonCircleModularFactory.sol";
import "../src/CircleRegistry.sol";

interface IFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

interface ITestCircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function directLTVWithdraw(uint256 borrowAmount) external returns (bytes32 loanId);
    function isMember(address user) external view returns (bool);
}

contract ActualTestDirectLTV is Script {
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        console.log("=== ACTUAL TEST: Deploy & Test Direct LTV Withdrawal ===");
        console.log("User:", USER);
        console.log("User balance:", USER.balance, "wei");
        
        vm.startBroadcast();
        
        // Step 1: Deploy the system
        console.log("1. Deploying contracts...");
        HorizonCircleCore coreImplementation = new HorizonCircleCore();
        CircleRegistry registry = new CircleRegistry();
        HorizonCircleModularFactory factory = new HorizonCircleModularFactory(
            address(registry),
            address(coreImplementation)
        );
        
        console.log("- Core Implementation:", address(coreImplementation));
        console.log("- Registry:", address(registry));
        console.log("- Factory:", address(factory));
        
        vm.stopBroadcast();
        
        // Step 2: Test as user
        vm.startPrank(USER);
        
        console.log("\n2. Creating circle as user...");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        string memory circleName = string(abi.encodePacked("DirectLTVTest_", vm.toString(block.timestamp)));
        address circleAddress = factory.createCircle(circleName, members);
        console.log("Circle created:", circleAddress);
        
        // Verify user is member
        bool isMember = ITestCircle(circleAddress).isMember(USER);
        console.log("Is user member:", isMember);
        
        // Step 3: Deposit
        console.log("\n3. Depositing 0.00003 ETH...");
        uint256 depositAmount = 0.00003 ether;
        
        // Check if user has enough balance
        if (USER.balance < depositAmount) {
            console.log("ERROR: User doesn't have enough ETH");
            console.log("- Required:", depositAmount);
            console.log("- Available:", USER.balance);
            vm.stopPrank();
            return;
        }
        
        ITestCircle(circleAddress).deposit{value: depositAmount}();
        
        uint256 userBalance = ITestCircle(circleAddress).getUserBalance(USER);
        console.log("User balance after deposit:", userBalance, "wei");
        
        // Step 4: Calculate and test direct LTV withdrawal
        console.log("\n4. Testing Direct LTV Withdrawal...");
        uint256 maxWithdraw = (userBalance * 8500) / 10000; // 85% LTV
        console.log("Max withdrawable (85% LTV):", maxWithdraw, "wei");
        
        if (maxWithdraw == 0) {
            console.log("ERROR: No withdrawable amount");
            vm.stopPrank();
            return;
        }
        
        uint256 testAmount = maxWithdraw / 2; // Test with 50% of max
        console.log("Testing withdrawal of:", testAmount, "wei");
        
        uint256 ethBalanceBefore = USER.balance;
        console.log("ETH balance before:", ethBalanceBefore, "wei");
        
        // Step 5: Execute the direct withdrawal
        try ITestCircle(circleAddress).directLTVWithdraw(testAmount) returns (bytes32 loanId) {
            console.log("\\nSUCCESS: Direct LTV withdrawal completed!");
            console.log("Loan ID:", vm.toString(loanId));
            
            uint256 ethBalanceAfter = USER.balance;
            uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;
            console.log("ETH balance after:", ethBalanceAfter, "wei");
            console.log("ETH received:", ethReceived, "wei");
            console.log("Expected:", testAmount, "wei");
            
            if (ethReceived >= testAmount * 99 / 100) { // Allow 1% tolerance
                console.log("PASS: Received expected amount");
            } else {
                console.log("FAIL: Received less than expected");
            }
            
        } catch Error(string memory reason) {
            console.log("\\nFAILED: Direct withdrawal failed:", reason);
        } catch {
            console.log("\\nFAILED: Direct withdrawal failed with unknown error");
        }
        
        vm.stopPrank();
        
        console.log("\n=== ACTUAL TEST COMPLETE ===");
        console.log("Factory deployed:", address(factory));
        console.log("Test circle:", circleAddress);
    }
}
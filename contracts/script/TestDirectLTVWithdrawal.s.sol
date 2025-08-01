// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

interface IHorizonCircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function directLTVWithdraw(uint256 borrowAmount) external returns (bytes32 loanId);
}

contract TestDirectLTVWithdrawal is Script {
    address constant FACTORY = 0x34A1D3fff3958843C43aD80F30b94c510645C316; // New factory with direct LTV
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        console.log("=== Testing Direct 85% LTV Withdrawal (No Social Lending) ===");
        console.log("User:", USER);
        console.log("User balance:", USER.balance, "wei");
        
        vm.startPrank(USER);
        
        // Step 1: Create Circle
        console.log("\n1. Creating Circle...");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        string memory circleName = string(abi.encodePacked("DirectLTV_", vm.toString(block.timestamp)));
        address circleAddress = IFactory(FACTORY).createCircle(circleName, members);
        console.log("Circle created at:", circleAddress);
        
        // Step 2: Deposit user's collateral
        console.log("\n2. Depositing 0.00003000 ETH...");
        uint256 depositAmount = 0.00003 ether;
        IHorizonCircle(circleAddress).deposit{value: depositAmount}();
        
        uint256 userBalance = IHorizonCircle(circleAddress).getUserBalance(USER);
        console.log("User balance after deposit:", userBalance, "wei");
        
        // Step 3: Calculate 85% LTV withdrawal
        console.log("\n3. Direct LTV Withdrawal Calculation:");
        uint256 ltvBasisPoints = 8500; // 85% LTV
        uint256 maxBorrowAmount = (depositAmount * ltvBasisPoints) / 10000;
        console.log("- Deposit amount:", depositAmount, "wei (0.00003000 ETH)");
        console.log("- At 85% LTV can withdraw:", maxBorrowAmount, "wei (0.00002550 ETH)");
        
        // Step 4: Direct LTV withdrawal (bypasses social lending)
        console.log("\n4. Executing Direct 85% LTV Withdrawal...");
        console.log("What will happen:");
        console.log("- Step 1: Withdraw 85% of user's deposit from Morpho vault");
        console.log("- Step 2: Swap WETH to wstETH via Velodrome CL pool");
        console.log("- Step 3: Supply wstETH to Morpho lending market");
        console.log("- Step 4: Borrow WETH against wstETH collateral");
        console.log("- Step 5: Convert WETH to ETH and send to user");
        
        uint256 ethBalanceBefore = USER.balance;
        console.log("\nUser ETH balance before withdrawal:", ethBalanceBefore, "wei");
        
        // Execute direct withdrawal
        try IHorizonCircle(circleAddress).directLTVWithdraw(maxBorrowAmount) returns (bytes32 loanId) {
            console.log("\nSUCCESS: Direct LTV withdrawal executed!");
            console.log("Loan ID:", vm.toString(loanId));
            
            uint256 ethBalanceAfter = USER.balance;
            uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;
            console.log("User ETH balance after withdrawal:", ethBalanceAfter, "wei");
            console.log("ETH received from direct withdrawal:", ethReceived, "wei");
            console.log("Expected:", maxBorrowAmount, "wei (0.00002550 ETH)");
            
        } catch Error(string memory reason) {
            console.log("\nFAILED: Direct withdrawal failed:", reason);
        } catch {
            console.log("\nFAILED: Direct withdrawal failed with unknown error");
        }
        
        vm.stopPrank();
        
        console.log("\n=== Test Complete ===");
        console.log("This approach bypasses social lending and uses only user's own deposit as collateral");
    }
}
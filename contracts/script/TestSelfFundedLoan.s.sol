// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

interface ICircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function requestCollateral(
        uint256 borrowAmount,
        uint256 collateralAmount, 
        address[] memory contributors,
        uint256[] memory amounts,
        string memory purpose
    ) external returns (bytes32 requestId);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32 loanId);
    function isMember(address user) external view returns (bool);
}

contract TestSelfFundedLoan is Script {
    address constant FACTORY = 0x1F8Ca9330DBfB36059c91ac2E6A503C9F533DA0D; // Working factory
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        console.log("=== TESTING SELF-FUNDED LOAN (Using Existing executeRequest) ===");
        console.log("Factory:", FACTORY);
        console.log("User:", USER);
        console.log("User balance:", USER.balance, "wei");
        
        vm.startPrank(USER);
        
        // Step 1: Create circle with working factory
        console.log("\n1. Creating circle with WORKING factory...");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        string memory circleName = string(abi.encodePacked("SelfFunded_", vm.toString(block.timestamp)));
        address circleAddress = IFactory(FACTORY).createCircle(circleName, members);
        console.log("Circle created:", circleAddress);
        
        // Verify membership
        bool isMember = ICircle(circleAddress).isMember(USER);
        console.log("Is user member:", isMember);
        
        // Step 2: Deposit
        console.log("\n2. Depositing 0.00003 ETH...");
        uint256 depositAmount = 0.00003 ether;
        ICircle(circleAddress).deposit{value: depositAmount}();
        
        uint256 userBalance = ICircle(circleAddress).getUserBalance(USER);
        console.log("User balance after deposit:", userBalance, "wei");
        
        // Step 3: Self-funded loan request
        console.log("\n3. Creating SELF-FUNDED loan request...");
        uint256 borrowAmount = (userBalance * 85) / 100; // 85% of deposit
        console.log("Borrow amount:", borrowAmount, "wei");
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER; // User contributes to own loan
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount; // User provides full collateral
        
        bytes32 requestId = ICircle(circleAddress).requestCollateral(
            borrowAmount,
            borrowAmount, // Collateral = borrow amount for self-funded
            contributors,
            amounts,
            "Self-funded direct withdrawal"
        );
        console.log("Request ID:", vm.toString(requestId));
        
        // Step 4: Contribute to own request
        console.log("\n4. Contributing to own request...");
        ICircle(circleAddress).contributeToRequest(requestId);
        console.log("Contribution completed");
        
        // Step 5: Execute the loan (existing function!)
        console.log("\n5. Executing loan with EXISTING executeRequest()...");
        uint256 ethBalanceBefore = USER.balance;
        console.log("ETH balance before:", ethBalanceBefore, "wei");
        
        try ICircle(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS: Self-funded loan executed!");
            console.log("Loan ID:", vm.toString(loanId));
            
            uint256 ethBalanceAfter = USER.balance;
            uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;
            console.log("ETH balance after:", ethBalanceAfter, "wei");
            console.log("ETH received:", ethReceived, "wei");
            console.log("Expected:", borrowAmount, "wei");
            
        } catch Error(string memory reason) {
            console.log("FAILED: Execute request failed:", reason);
        } catch {
            console.log("FAILED: Execute request failed with unknown error");
        }
        
        vm.stopPrank();
        
        console.log("\n=== SELF-FUNDED LOAN TEST COMPLETE ===");
        console.log("Used existing executeRequest() - no new function needed!");
    }
}
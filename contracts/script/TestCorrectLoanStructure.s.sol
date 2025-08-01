// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

interface IHorizonCircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function requestCollateral(
        uint256 borrowAmount,
        uint256 collateralAmount,
        address[] memory contributors,
        uint256[] memory amounts,
        string memory purpose
    ) external returns (bytes32);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32);
    function requests(bytes32) external view returns (
        address borrower,
        uint256 borrowAmount,
        uint256 collateralNeeded,
        uint256 totalContributed,
        uint256 deadline,
        bool fulfilled,
        bool executed,
        string memory purpose,
        uint256 createdAt
    );
}

contract TestCorrectLoanStructure is Script {
    address constant FACTORY = 0x1F8Ca9330DBfB36059c91ac2E6A503C9F533DA0D;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        console.log("=== Testing Correct Loan Structure ===");
        console.log("User:", USER);
        console.log("User balance:", USER.balance, "wei");
        
        vm.startPrank(USER);
        
        // Step 1: Create Circle
        console.log("\n1. Creating Circle...");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        string memory circleName = string(abi.encodePacked("CorrectLoan_", vm.toString(block.timestamp)));
        address circleAddress = IFactory(FACTORY).createCircle(circleName, members);
        console.log("Circle created at:", circleAddress);
        
        // Step 2: Deposit (user's own collateral)
        console.log("\n2. Depositing user's collateral: 0.00003000 ETH...");
        uint256 userCollateral = 0.00003 ether;
        IHorizonCircle(circleAddress).deposit{value: userCollateral}();
        
        uint256 userBalance = IHorizonCircle(circleAddress).getUserBalance(USER);
        console.log("User balance after deposit:", userBalance, "wei");
        
        // Step 3: Calculate loan structure
        console.log("\n3. Loan Structure Calculation:");
        uint256 borrowAmount = 0.00003 ether;
        console.log("- Borrower wants:", borrowAmount, "wei (0.00003000 ETH)");
        console.log("- Borrower's collateral:", userCollateral, "wei (0.00003000 ETH)");
        
        uint256 ltvBasisPoints = 8500; // 85% LTV
        uint256 maxBorrowFromUserCollateral = (userCollateral * ltvBasisPoints) / 10000;
        console.log("- At 85% LTV can borrow:", maxBorrowFromUserCollateral, "wei (0.00002550 ETH)");
        
        uint256 shortfall = borrowAmount - maxBorrowFromUserCollateral;
        console.log("- Shortfall:", shortfall, "wei (0.00000450 ETH)");
        
        // Calculate needed contribution to reach 85% LTV for full borrow amount
        uint256 totalCollateralNeeded = (borrowAmount * 10000) / ltvBasisPoints;
        uint256 contributionNeeded = totalCollateralNeeded - userCollateral;
        console.log("- Contribution needed:", contributionNeeded, "wei");
        console.log("- Total collateral:", totalCollateralNeeded, "wei");
        
        // Step 4: Request with social collateral
        console.log("\n4. Requesting loan with social collateral...");
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER; // Self-contribution for testing
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = totalCollateralNeeded; // Contract expects full collateral amount, not just the additional
        
        bytes32 requestId = IHorizonCircle(circleAddress).requestCollateral(
            borrowAmount,
            totalCollateralNeeded,
            contributors,
            amounts,
            "Social collateral loan with correct LTV calculation"
        );
        console.log("Request created with ID:", vm.toString(requestId));
        
        // Step 5: Check if user has enough balance for contribution
        uint256 currentBalance = USER.balance;
        console.log("\n5. Balance check for contribution:");
        console.log("- Current ETH balance:", currentBalance, "wei");
        console.log("- Contribution needed:", contributionNeeded, "wei");
        console.log("- Has sufficient balance:", currentBalance >= contributionNeeded);
        
        if (currentBalance < contributionNeeded) {
            console.log("INSUFFICIENT BALANCE - Cannot complete contribution");
            vm.stopPrank();
            return;
        }
        
        // Step 6: Contribute (self-contribute the shortfall)
        console.log("\n6. Contributing social collateral...");
        IHorizonCircle(circleAddress).contributeToRequest(requestId);
        console.log("Contribution completed");
        
        console.log("\n7. Request Status:");
        console.log("Contribution completed - checking request status...");
        
        // Step 7: Execute loan (assume fulfilled after contribution)
        console.log("\n8. Executing loan...");
        console.log("What will happen:");
        console.log("- Withdraw WETH from Morpho vault");
        console.log("- Swap WETH to wstETH via Velodrome CL pool");
        console.log("- Supply wstETH to Morpho lending market");
        console.log("- Borrow WETH against wstETH collateral");
        console.log("- Convert WETH to ETH and send to borrower");
        
        uint256 ethBalanceBefore = USER.balance;
        console.log("User ETH balance before execution:", ethBalanceBefore, "wei");
        
        try IHorizonCircle(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
            console.log("\nSUCCESS: Loan executed!");
            console.log("Loan ID:", vm.toString(loanId));
            
            uint256 ethBalanceAfter = USER.balance;
            console.log("User ETH balance after execution:", ethBalanceAfter, "wei");
            
        } catch Error(string memory reason) {
            console.log("\nFAILED: Execute request failed:", reason);
        } catch {
            console.log("\nFAILED: Execute request failed with unknown error");
        }
        
        vm.stopPrank();
        
        console.log("\n=== Test Complete ===");
    }
}
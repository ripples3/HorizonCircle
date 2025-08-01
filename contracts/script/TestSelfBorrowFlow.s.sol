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

contract TestSelfBorrowFlow is Script {
    address constant FACTORY = 0x1F8Ca9330DBfB36059c91ac2E6A503C9F533DA0D;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        console.log("=== Testing Self-Borrow Flow for User ===");
        console.log("User:", USER);
        console.log("User balance:", USER.balance, "wei");
        console.log("Factory:", FACTORY);
        
        // Simulate the flow
        vm.startPrank(USER);
        
        // Step 1: Create Circle
        console.log("\n1. Creating Circle...");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        string memory circleName = string(abi.encodePacked("SelfBorrowTest_", vm.toString(block.timestamp)));
        address circleAddress = IFactory(FACTORY).createCircle(circleName, members);
        console.log("Circle created at:", circleAddress);
        
        // Step 2: Deposit 0.00003 ETH
        console.log("\n2. Depositing 0.00003 ETH...");
        uint256 depositAmount = 0.00003 ether;
        IHorizonCircle(circleAddress).deposit{value: depositAmount}();
        
        uint256 userBalance = IHorizonCircle(circleAddress).getUserBalance(USER);
        console.log("User balance after deposit:", userBalance, "wei");
        console.log("Expected:", depositAmount - 1, "wei (minus 1 wei for precision)");
        
        // Step 3: Request Self-Borrow
        console.log("\n3. Requesting Self-Borrow...");
        console.log("Loan Structure:");
        console.log("- Borrower wants: 0.00003000 ETH");
        console.log("- Borrower's collateral: 0.00003000 ETH");
        console.log("- At 85% LTV can borrow: 0.00002550 ETH");
        console.log("- But using full collateral for self-borrow");
        
        uint256 borrowAmount = 0.00003 ether;
        uint256 collateralAmount = 0.00003 ether;
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = collateralAmount;
        
        bytes32 requestId = IHorizonCircle(circleAddress).requestCollateral(
            borrowAmount,
            collateralAmount,
            contributors,
            amounts,
            "Self-borrow test at 85% LTV"
        );
        console.log("Request created with ID:", vm.toString(requestId));
        
        // Step 4: Contribute to Own Request
        console.log("\n4. Contributing to own request...");
        IHorizonCircle(circleAddress).contributeToRequest(requestId);
        console.log("Contribution completed");
        
        // Check request status
        (
            address borrower,
            uint256 reqBorrowAmount,
            uint256 collateralNeeded,
            uint256 totalContributed,
            ,
            bool fulfilled,
            bool executed,
            ,
        ) = IHorizonCircle(circleAddress).requests(requestId);
        
        console.log("\nRequest Status:");
        console.log("- Borrower:", borrower);
        console.log("- Borrow amount:", reqBorrowAmount, "wei");
        console.log("- Collateral needed:", collateralNeeded, "wei");
        console.log("- Total contributed:", totalContributed, "wei");
        console.log("- Fulfilled:", fulfilled);
        console.log("- Executed:", executed);
        
        // Step 5: Execute Request
        console.log("\n5. Executing loan request...");
        console.log("\nWhat will happen during execution:");
        console.log("- Step 1: Withdraw 0.00003000 WETH from Morpho vault");
        console.log("- Step 2: Swap WETH to wstETH via Velodrome CL pool");
        console.log("- Step 3: Supply wstETH to Morpho lending market");
        console.log("- Step 4: Borrow 0.00003000 WETH against collateral");
        console.log("- Step 5: Convert WETH to ETH and send to borrower");
        
        // Check user's ETH balance before
        uint256 ethBalanceBefore = USER.balance;
        console.log("\nUser ETH balance before execution:", ethBalanceBefore, "wei");
        
        // Execute the loan
        try IHorizonCircle(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
            console.log("\nSUCCESS: Loan executed!");
            console.log("Loan ID:", vm.toString(loanId));
            
            uint256 ethBalanceAfter = USER.balance;
            uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;
            console.log("User ETH balance after execution:", ethBalanceAfter, "wei");
            console.log("ETH received from loan:", ethReceived, "wei");
            console.log("Expected ~0.00003000 ETH minus gas");
            
        } catch Error(string memory reason) {
            console.log("\nFAILED: Execute request failed:", reason);
        } catch {
            console.log("\nFAILED: Execute request failed with unknown error");
        }
        
        vm.stopPrank();
    }
}
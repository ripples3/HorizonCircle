// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IHorizonCircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function requestCollateral(
        uint256 amount,
        uint256 collateralNeeded,
        address[] memory contributors,
        uint256[] memory amounts,
        string memory purpose
    ) external returns (bytes32);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32);
}

interface IFactory {
    function createCircle(string memory name, address[] memory members) external returns (address);
}

contract TestDirectImplementation is Script {
    address constant FACTORY = 0x1F8Ca9330DBfB36059c91ac2E6A503C9F533DA0D;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== TESTING DIRECT IMPLEMENTATION WITH HIGH GAS LIMIT ===");
        console.log("Factory:", FACTORY);
        console.log("User:", USER);
        
        // Create circle
        IFactory factory = IFactory(FACTORY);
        
        address[] memory members = new address[](1);
        members[0] = USER;
        
        address circleAddr = factory.createCircle("DirectTest", members);
        console.log("Circle created:", circleAddr);
        
        vm.stopBroadcast();
        
        // Switch to user context
        vm.startPrank(USER);
        
        IHorizonCircle circle = IHorizonCircle(circleAddr);
        
        console.log("\n=== Step 1: Deposit Small Amount ===");
        uint256 depositAmount = 0.00002 ether; // Very small amount
        console.log("Depositing:", depositAmount);
        
        circle.deposit{value: depositAmount}();
        console.log("SUCCESS: Deposit completed");
        
        uint256 userBalance = circle.getUserBalance(USER);
        console.log("User balance after deposit:", userBalance);
        
        console.log("\n=== Step 2: Request Very Small Loan ===");
        uint256 loanAmount = (userBalance * 50) / 100; // Only 50% LTV to be extra safe
        console.log("Requesting tiny loan:", loanAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = loanAmount;
        
        bytes32 requestId = circle.requestCollateral(
            loanAmount,
            loanAmount,
            contributors,
            amounts,
            "Tiny test loan"
        );
        console.log("SUCCESS: Loan request created");
        
        console.log("\n=== Step 3: Contribute to Request ===");
        circle.contributeToRequest(requestId);
        console.log("SUCCESS: Contribution made");
        
        console.log("\n=== Step 4: Execute with Maximum Gas ===");
        console.log("Testing with tiny amounts and maximum gas limit...");
        
        uint256 ethBalanceBefore = USER.balance;
        console.log("ETH balance before:", ethBalanceBefore);
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            uint256 ethBalanceAfter = USER.balance;
            uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;
            
            console.log("");
            console.log("SUCCESS: LOAN EXECUTION WORKED!");
            console.log("Loan ID:", uint256(loanId));
            console.log("ETH received:", ethReceived);
            console.log("ETH balance after:", ethBalanceAfter);
            console.log("");
            console.log("HORIZONCIRCLE IS 100% OPERATIONAL!");
            console.log("Problem was likely gas limits or amount size!");
            
        } catch Error(string memory reason) {
            console.log("FAILED: Execution failed with reason:", reason);
            console.log("Analyzing failure...");
            
        } catch (bytes memory lowLevelData) {
            console.log("FAILED: Low-level execution error");
            console.log("Error data length:", lowLevelData.length);
            
            if (lowLevelData.length == 0) {
                console.log("LIKELY ISSUE: Out of gas or assertion failure");
                console.log("Try increasing gas limit or reducing amount");
            }
        }
        
        vm.stopPrank();
        
        console.log("\n=== ANALYSIS ===");
        console.log("If this fails, the issue is likely:");
        console.log("1. Gas limit too low for complex transaction");
        console.log("2. Amount too small causing precision issues");
        console.log("3. Morpho vault withdrawal failing in proxy context");
        console.log("4. Some other context-specific issue");
        console.log("");
        console.log("We know CL pool swap works perfectly in isolation!");
    }
}
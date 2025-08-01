// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IDebugFactory {
    function createCircle(string memory name, address[] memory members) external returns (address);
}

interface IDebugCircle {
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

contract TestDebugImplementation is Script {
    address constant DEBUG_FACTORY = 0xeC14F30b4b606ab57537BA5de5392b13029FB860;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== TESTING DEBUG IMPLEMENTATION ===");
        console.log("Debug Factory:", DEBUG_FACTORY);
        console.log("User:", USER);
        
        // Create circle with debug implementation
        IDebugFactory factory = IDebugFactory(DEBUG_FACTORY);
        
        address[] memory members = new address[](1);
        members[0] = USER;
        
        address circleAddr = factory.createCircle("DebugCLPoolTest", members);
        console.log("Circle created:", circleAddr);
        
        vm.stopBroadcast();
        
        // Switch to user context for testing
        vm.startPrank(USER);
        
        IDebugCircle circle = IDebugCircle(circleAddr);
        
        console.log("\n=== Step 1: Deposit ETH ===");
        uint256 depositAmount = 0.00005 ether;
        console.log("Depositing:", depositAmount);
        
        circle.deposit{value: depositAmount}();
        console.log("SUCCESS: Deposit completed");
        
        uint256 userBalance = circle.getUserBalance(USER);
        console.log("User balance after deposit:", userBalance);
        
        console.log("\n=== Step 2: Request Self-Loan ===");
        uint256 loanAmount = (userBalance * 80) / 100; // 80% LTV
        console.log("Requesting loan:", loanAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = loanAmount;
        
        bytes32 requestId = circle.requestCollateral(
            loanAmount,
            loanAmount,
            contributors,
            amounts,
            "Debug test loan"
        );
        console.log("SUCCESS: Loan request created");
        
        console.log("\n=== Step 3: Contribute to Own Request ===");
        circle.contributeToRequest(requestId);
        console.log("SUCCESS: Self-contribution made");
        
        console.log("\n=== Step 4: Execute Loan WITH DEBUG INFO ===");
        console.log("This will show detailed debug info about the CL pool swap...");
        
        uint256 ethBalanceBefore = USER.balance;
        console.log("ETH balance before loan execution:", ethBalanceBefore);
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            uint256 ethBalanceAfter = USER.balance;
            uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;
            
            console.log("");
            console.log("SUCCESS: LOAN EXECUTION WORKED WITH DEBUG IMPL!");
            console.log("Loan ID created:", uint256(loanId));
            console.log("ETH received:", ethReceived);
            console.log("ETH balance after:", ethBalanceAfter);
            console.log("");
            console.log("CL POOL SWAP IS NOW WORKING!");
            
        } catch Error(string memory reason) {
            console.log("FAILED: Loan execution failed:", reason);
            console.log("Check the debug logs above for detailed swap info");
            
        } catch (bytes memory lowLevelData) {
            console.log("FAILED: Loan execution failed with low-level error");
            console.log("Data length:", lowLevelData.length);
            console.log("Check the debug logs above for detailed swap info");
        }
        
        vm.stopPrank();
        
        console.log("\n=== DEBUG TEST COMPLETE ===");
        console.log("This debug implementation will show us exactly where the swap fails");
    }
}
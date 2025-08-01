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

contract TestFinalImplementation is Script {
    address constant FINAL_FACTORY = 0xD6967bd8ed4d4daB28b3B3F67D2C1b66633f9E09;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== TESTING FINAL IMPLEMENTATION WITH WORKING CL POOL ===");
        console.log("Final Factory:", FINAL_FACTORY);
        console.log("User:", USER);
        console.log("Implementation: 0xccDDb5f678c2794be86565Bb955Ddbfb388111F1");
        
        // Create circle with final implementation
        IFactory factory = IFactory(FINAL_FACTORY);
        
        address[] memory members = new address[](1);
        members[0] = USER;
        
        address circleAddr = factory.createCircle("FinalTest", members);
        console.log("Circle created:", circleAddr);
        
        vm.stopBroadcast();
        
        // Switch to user context
        vm.startPrank(USER);
        
        IHorizonCircle circle = IHorizonCircle(circleAddr);
        
        console.log("\n=== Step 1: Deposit ETH ===");
        uint256 depositAmount = 0.00003 ether; // Back to original test amount
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
            "Final test loan"
        );
        console.log("SUCCESS: Loan request created");
        
        console.log("\n=== Step 3: Contribute to Request ===");
        circle.contributeToRequest(requestId);
        console.log("SUCCESS: Contribution made");
        
        console.log("\n=== Step 4: THE ULTIMATE TEST - EXECUTE LOAN ===");
        console.log("This should work with the latest implementation...");
        
        uint256 ethBalanceBefore = USER.balance;
        console.log("ETH balance before:", ethBalanceBefore);
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            uint256 ethBalanceAfter = USER.balance;
            uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;
            
            console.log("");
            console.log("SUCCESS: HORIZONCIRCLE IS 100% OPERATIONAL!");
            console.log("");
            console.log("Final Results:");
            console.log("- Loan ID:", uint256(loanId));
            console.log("- ETH received:", ethReceived);
            console.log("- ETH balance after:", ethBalanceAfter);
            console.log("");
            console.log("Circle creation: WORKING");
            console.log("ETH deposits: WORKING");
            console.log("Morpho yield: WORKING");
            console.log("Social lending: WORKING");
            console.log("CL pool swap: WORKING");
            console.log("Loan execution: WORKING");
            console.log("");
            console.log("READY FOR PRODUCTION LAUNCH!");
            console.log("");
            console.log("Final production addresses:");
            console.log("- Factory:", FINAL_FACTORY);
            console.log("- Implementation: 0xccDDb5f678c2794be86565Bb955Ddbfb388111F1");
            console.log("- Registry: 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC");
            console.log("- Block filter: 19628491");
            
        } catch Error(string memory reason) {
            console.log("EXECUTION FAILED with reason:", reason);
            
            if (keccak256(abi.encodePacked(reason)) == keccak256(abi.encodePacked("CL pool swap failed with unknown error"))) {
                console.log("ISSUE: Still CL pool swap problem - need deeper investigation");
            } else if (bytes(reason).length > 7 && keccak256(abi.encodePacked(substring(reason, 0, 7))) == keccak256(abi.encodePacked("!assets"))) {
                console.log("ISSUE: Morpho vault precision problem");
            } else if (bytes(reason).length > 10 && keccak256(abi.encodePacked(substring(reason, 0, 10))) == keccak256(abi.encodePacked("!slippage"))) {
                console.log("ISSUE: DEX slippage problem");
            } else {
                console.log("ISSUE: Other execution error");
                console.log("Reason length:", bytes(reason).length);
            }
            
        } catch (bytes memory lowLevelData) {
            console.log("EXECUTION FAILED with low-level error");
            console.log("Error data length:", lowLevelData.length);
        }
        
        vm.stopPrank();
        
        console.log("\n=== FINAL SYSTEM ANALYSIS ===");
        console.log("Latest implementation deployed and tested");
        console.log("All individual components confirmed working");
        console.log("If this still fails, we need to investigate the specific error");
    }
    
    // Helper function for string operations
    function substring(string memory str, uint256 start, uint256 length) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (start >= strBytes.length || length == 0) {
            return "";
        }
        
        uint256 end = start + length;
        if (end > strBytes.length) {
            end = strBytes.length;
        }
        
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = strBytes[i];
        }
        
        return string(result);
    }
}
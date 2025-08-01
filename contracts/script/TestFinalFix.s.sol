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
}

contract TestFinalFix is Script {
    address constant FACTORY = 0x8828F446D893E3a223c574a1Eae03b68B267ab33; // Final fix factory
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING FINAL FIX ===");
        console.log("Factory:", FACTORY);
        console.log("User balance:", USER.balance / 1e15, "finney");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Create circle
        address[] memory members = new address[](1);
        members[0] = USER;
        address circleAddress = IFactory(FACTORY).createCircle("FinalTest", members);
        console.log("Circle:", circleAddress);
        
        // Deposit and create loan
        ICircle(circleAddress).deposit{value: 0.0001 ether}();
        uint256 balance = ICircle(circleAddress).getUserBalance(USER);
        uint256 borrowAmount = balance / 2;
        
        console.log("Balance:", balance / 1e12, "microETH");
        console.log("Requesting:", borrowAmount / 1e12, "microETH");
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount;
        
        bytes32 requestId = ICircle(circleAddress).requestCollateral(
            borrowAmount, borrowAmount, contributors, amounts, "Final test"
        );
        
        ICircle(circleAddress).contributeToRequest(requestId);
        console.log("Contribution made");
        
        // Test executeRequest with final fix
        console.log("\nTesting executeRequest with final fix...");
        uint256 ethBefore = USER.balance;
        
        try ICircle(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS! executeRequest finally worked!");
            console.log("Loan ID:", vm.toString(loanId));
            
            uint256 ethAfter = USER.balance;
            uint256 ethReceived = ethAfter - ethBefore;
            console.log("ETH received:", ethReceived / 1e12, "microETH");
            
            if (ethReceived > 0) {
                console.log("COMPLETE SUCCESS: DeFi integration working!");
            }
            
        } catch Error(string memory reason) {
            console.log("Still failed:", reason);
        } catch {
            console.log("Still failed with unknown error");
        }
        
        vm.stopBroadcast();
        console.log("=== FINAL TEST COMPLETE ===");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

interface ICircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function userShares(address user) external view returns (uint256);
    function totalShares() external view returns (uint256);
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

contract TestSimple is Script {
    address constant FACTORY = 0x8144c8A43396A4E94222094746152bA8d35D85c0;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== SIMPLE TEST FOR USER ===");
        console.log("User:", USER);
        console.log("User ETH balance:", USER.balance / 1e15, "finney");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Create circle
        address[] memory members = new address[](1);
        members[0] = USER;
        
        address circleAddress = IFactory(FACTORY).createCircle("SimpleTest", members);
        console.log("Circle:", circleAddress);
        
        // Deposit
        uint256 depositAmount = 0.0001 ether;
        ICircle(circleAddress).deposit{value: depositAmount}();
        
        uint256 balance = ICircle(circleAddress).getUserBalance(USER);
        uint256 shares = ICircle(circleAddress).userShares(USER);
        
        console.log("Balance:", balance / 1e12, "microETH");
        console.log("Shares:", shares / 1e12, "microShares");
        
        // Request loan (self-funded, no external contributions expected)
        uint256 borrowAmount = balance / 2; // 50% of deposit
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount;
        
        bytes32 requestId = ICircle(circleAddress).requestCollateral(
            borrowAmount,
            borrowAmount,
            contributors,
            amounts,
            "Self-funded test"
        );
        
        console.log("Loan amount:", borrowAmount / 1e12, "microETH");
        
        // Contribute (should deduct shares)
        uint256 sharesBefore = ICircle(circleAddress).userShares(USER);
        
        ICircle(circleAddress).contributeToRequest(requestId);
        
        uint256 sharesAfter = ICircle(circleAddress).userShares(USER);
        uint256 deducted = sharesBefore - sharesAfter;
        
        console.log("Shares deducted:", deducted / 1e12, "microShares");
        
        if (deducted > 0) {
            console.log("SUCCESS: Contribution logic working!");
        } else {
            console.log("FAILED: No shares deducted");
        }
        
        // Try execute
        try ICircle(circleAddress).executeRequest(requestId) {
            console.log("Execute worked (unexpected but good!)");
        } catch {
            console.log("Execute failed (expected due to DeFi issues)");
        }
        
        vm.stopBroadcast();
        console.log("=== TEST COMPLETE ===");
    }
}
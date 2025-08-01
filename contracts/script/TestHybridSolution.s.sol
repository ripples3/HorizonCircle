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

contract TestHybridSolution is Script {
    // HYBRID: Fixed contribution logic + Working DeFi integration
    address constant FACTORY = 0x6b51Cb6Cc611b7415b951186E9641aFc87Df77DB;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING HYBRID SOLUTION ===");
        console.log("Fixed Contribution + Working DeFi");
        console.log("Factory:", FACTORY);
        console.log("User:", USER);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Test 1: Create circle
        address[] memory members = new address[](1);
        members[0] = USER;
        
        address circleAddress = IFactory(FACTORY).createCircle("HybridTest", members);
        console.log("Circle created:", circleAddress);
        
        // Test 2: Deposit (should work with fixed logic)
        uint256 depositAmount = 0.0001 ether;
        ICircle(circleAddress).deposit{value: depositAmount}();
        
        uint256 balance = ICircle(circleAddress).getUserBalance(USER);
        console.log("Balance:", balance / 1e12, "microETH");
        
        // Test 3: Self-funded loan
        uint256 borrowAmount = balance / 2;
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount;
        
        bytes32 requestId = ICircle(circleAddress).requestCollateral(
            borrowAmount, borrowAmount, contributors, amounts, "Hybrid test"
        );
        
        // Test 4: Fixed contribution logic
        uint256 sharesBefore = ICircle(circleAddress).userShares(USER);
        ICircle(circleAddress).contributeToRequest(requestId);
        uint256 sharesAfter = ICircle(circleAddress).userShares(USER);
        
        console.log("Shares deducted:", (sharesBefore - sharesAfter) / 1e12, "microShares");
        
        if (sharesAfter < sharesBefore) {
            console.log("SUCCESS: Fixed contribution logic working!");
        }
        
        // Test 5: Complete loan execution with DeFi
        console.log("\nTesting COMPLETE loan execution...");
        uint256 ethBefore = USER.balance;
        
        try ICircle(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
            console.log("AMAZING: Complete loan execution successful!");
            console.log("Loan ID:", vm.toString(loanId));
            
            uint256 ethAfter = USER.balance;
            uint256 ethReceived = ethAfter - ethBefore;
            
            console.log("ETH received:", ethReceived / 1e12, "microETH");
            console.log("Expected:", borrowAmount / 1e12, "microETH");
            
            if (ethReceived > 0) {
                console.log("PERFECT: User received loan proceeds!");
                console.log("DeFi integration working!");
            }
            
        } catch Error(string memory reason) {
            console.log("executeRequest failed:", reason);
        } catch {
            console.log("executeRequest failed (unknown error)");
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== HYBRID TEST COMPLETE ===");
        console.log("This should combine:");
        console.log("- Fixed contribution logic (shares actually deducted)");
        console.log("- Working DeFi integration (Morpho + Velodrome)");
    }
}
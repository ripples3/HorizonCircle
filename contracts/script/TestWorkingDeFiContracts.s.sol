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

contract TestWorkingDeFiContracts is Script {
    // Use the WORKING contracts with DeFi integration (Jul 31, 2025)
    address constant FACTORY = 0xae5CdD2f24F90D04993DA9E13e70586Ab7281E7b; // WORKING FACTORY with DeFi
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING WORKING DEFI CONTRACTS ===");
        console.log("Factory (with working DeFi):", FACTORY);
        console.log("User:", USER);
        console.log("User ETH balance:", USER.balance / 1e15, "finney");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Create circle using WORKING factory
        address[] memory members = new address[](1);
        members[0] = USER;
        
        address circleAddress = IFactory(FACTORY).createCircle("DeFiTest", members);
        console.log("Circle created:", circleAddress);
        
        // Deposit
        uint256 depositAmount = 0.0001 ether;
        ICircle(circleAddress).deposit{value: depositAmount}();
        
        uint256 balance = ICircle(circleAddress).getUserBalance(USER);
        console.log("Balance:", balance / 1e12, "microETH");
        
        // Request self-funded loan
        uint256 borrowAmount = balance / 2; // 50%
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount;
        
        bytes32 requestId = ICircle(circleAddress).requestCollateral(
            borrowAmount,
            borrowAmount,
            contributors,
            amounts,
            "Testing WORKING DeFi integration"
        );
        
        console.log("Loan amount:", borrowAmount / 1e12, "microETH");
        
        // Contribute
        ICircle(circleAddress).contributeToRequest(requestId);
        console.log("Contribution made");
        
        // Execute with WORKING DeFi integration
        console.log("\nTesting executeRequest with WORKING DeFi contracts...");
        uint256 ethBefore = USER.balance;
        
        try ICircle(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS: executeRequest worked with DeFi integration!");
            console.log("Loan ID:", vm.toString(loanId));
            
            uint256 ethAfter = USER.balance;
            uint256 ethReceived = ethAfter - ethBefore;
            console.log("ETH received:", ethReceived / 1e12, "microETH");
            
            if (ethReceived > 0) {
                console.log("PERFECT: User received actual loan proceeds!");
            }
            
        } catch Error(string memory reason) {
            console.log("Failed:", reason);
        } catch {
            console.log("Failed with unknown error");
        }
        
        vm.stopBroadcast();
        console.log("\n=== TEST COMPLETE ===");
        console.log("Using contracts that previously had working DeFi integration");
    }
}
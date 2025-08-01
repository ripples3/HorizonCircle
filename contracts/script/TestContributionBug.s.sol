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
    
    // Debug functions to inspect request state
    function collateralRequests(bytes32 requestId) external view returns (
        address borrower,
        uint256 amount,
        uint256 collateralNeeded,
        uint256 totalContributed,
        bool executed,
        string memory purpose
    );
    function isMember(address user) external view returns (bool);
}

contract TestContributionBug is Script {
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant TEST_CIRCLE = 0x5810e8015eDA0E02be333a9D1F381C4157269D0a; // Known working circle
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== TESTING CONTRIBUTION BUG ===");
        console.log("User:", USER);
        console.log("Test Circle:", TEST_CIRCLE);
        
        IHorizonCircle circle = IHorizonCircle(TEST_CIRCLE);
        
        // Check if user is member
        bool isMember = circle.isMember(USER);
        console.log("Is user member:", isMember);
        
        if (!isMember) {
            console.log("User is not a member - this will cause issues");
            vm.stopBroadcast();
            return;
        }
        
        // Get current balance
        uint256 userBalance = circle.getUserBalance(USER);
        console.log("User balance:", userBalance);
        
        if (userBalance == 0) {
            console.log("User has no balance - making small deposit");
            circle.deposit{value: 0.00003 ether}();
            userBalance = circle.getUserBalance(USER);
            console.log("User balance after deposit:", userBalance);
        }
        
        // Create request with detailed logging
        uint256 loanAmount = (userBalance * 80) / 100;
        console.log("Requesting loan amount:", loanAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER; // This is key - we're setting USER as the contributor
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = loanAmount;
        
        console.log("Contributors array:");
        console.log("- contributors[0]:", contributors[0]);
        console.log("- amounts[0]:", amounts[0]);
        console.log("- msg.sender (transaction sender):", msg.sender);
        console.log("- USER constant:", USER);
        console.log("- Are they equal?", msg.sender == USER);
        
        bytes32 requestId = circle.requestCollateral(
            loanAmount, 
            loanAmount, 
            contributors, 
            amounts,
            "TESTING: Contribution bug identification"
        );
        console.log("Request created");
        
        // Check request state
        (
            address borrower,
            uint256 amount,
            uint256 collateralNeeded,
            uint256 totalContributed,
            bool executed,
            string memory purpose
        ) = circle.collateralRequests(requestId);
        
        console.log("=== REQUEST STATE ===");
        console.log("Borrower:", borrower);
        console.log("Amount:", amount);
        console.log("Collateral needed:", collateralNeeded);
        console.log("Total contributed:", totalContributed);
        console.log("Executed:", executed);
        
        // The KEY TEST: Try contribution
        console.log("=== ATTEMPTING CONTRIBUTION ===");
        console.log("This should work if msg.sender == USER");
        console.log("msg.sender:", msg.sender);
        console.log("Expected contributor (USER):", USER);
        
        try circle.contributeToRequest(requestId) {
            console.log("SUCCESS: Contribution worked!");
            
            // Check state after contribution
            (, , , uint256 newTotalContributed, ,) = circle.collateralRequests(requestId);
            console.log("Total contributed after:", newTotalContributed);
            
        } catch Error(string memory reason) {
            console.log("FAILED: Contribution error:", reason);
            console.log("");
            console.log("DIAGNOSIS:");
            console.log("The error 'No contribution assigned' means:");
            console.log("1. The contributor lookup loop failed");
            console.log("2. msg.sender was not found in contributors array");
            console.log("3. OR contributionAmount was 0 for this contributor");
            console.log("");
            console.log("LIKELY CAUSE:");
            if (msg.sender != USER) {
                console.log("- msg.sender != USER (private key mismatch)");
            } else {
                console.log("- Array lookup logic bug in contract");
            }
            
        } catch (bytes memory lowLevelData) {
            console.log("FAILED: Low-level error");
            console.log("Error length:", lowLevelData.length);
        }
        
        vm.stopBroadcast();
    }
}
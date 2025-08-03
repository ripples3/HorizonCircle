// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/HorizonCircleNoSwap.sol";

contract TestDirectNoSwap is Script {
    // Test user
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant LENDING_MODULE = 0xE843cCdBd4F9694208F06AFf3cB5bc8f228C7D48;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DIRECT NO-SWAP TEST ===");
        console.log("Deploy circle directly and test");
        console.log("Test User:", TEST_USER);
        
        // Check initial user balance
        uint256 initialBalance = TEST_USER.balance;
        console.log("Initial ETH Balance:", initialBalance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Deploy Circle Directly
        console.log("\\n=== STEP 1: DEPLOY CIRCLE DIRECTLY ===");
        HorizonCircleNoSwap circle = new HorizonCircleNoSwap();
        console.log("Circle deployed:", address(circle));
        
        // Initialize
        address[] memory members = new address[](1);
        members[0] = TEST_USER;
        circle.initialize(
            "DirectNoSwapCircle",
            members,
            address(0),
            address(0),
            LENDING_MODULE
        );
        console.log("Circle initialized");
        
        // Authorize circle in lending module
        console.log("Authorizing circle in lending module...");
        ILendingModuleNoSwap lendingModule = ILendingModuleNoSwap(LENDING_MODULE);
        lendingModule.authorizeUser(address(circle));
        console.log("Circle authorized");
        
        // Step 2: Deposit ETH to Circle
        console.log("\\n=== STEP 2: DEPOSIT ETH ===");
        uint256 depositAmount = 0.00003 ether;
        console.log("Depositing:", depositAmount);
        
        circle.deposit{value: depositAmount}();
        
        uint256 userBalance = circle.getUserBalance(TEST_USER);
        console.log("User Circle Balance (shares):", userBalance);
        
        // Step 3: Request Loan
        console.log("\\n=== STEP 3: REQUEST LOAN ===");
        uint256 loanAmount = 0.00001 ether;
        console.log("Requesting loan:", loanAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0.000012 ether;
        
        bytes32 requestId = circle.requestCollateral(loanAmount, contributors, amounts, "Direct test loan");
        console.log("Request ID:", vm.toString(requestId));
        
        // Step 4: Contribute
        console.log("\\n=== STEP 4: CONTRIBUTE ===");
        circle.contributeToRequest(requestId);
        console.log("Contribution made");
        
        // Step 5: Execute (No-Swap)
        console.log("\\n=== STEP 5: EXECUTE LOAN ===");
        bytes32 loanId = circle.executeRequest(requestId);
        console.log("Loan ID:", vm.toString(loanId));
        
        vm.stopBroadcast();
        
        // Step 6: Verify
        console.log("\\n=== STEP 6: VERIFY ===");
        console.log("Final ETH Balance:", TEST_USER.balance);
        
        if (TEST_USER.balance > 580000000000000) {
            console.log("SUCCESS: User received borrowed ETH!");
        } else {
            console.log("ISSUE: User did not receive ETH");
        }
        
        console.log("\\n=== NO-SWAP TEST COMPLETE ===");
        console.log("Circle Address:", address(circle));
    }
}
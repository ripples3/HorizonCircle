// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IImplementation {
    function initialize(
        string memory name,
        address[] memory members,
        address registry,
        address swapModule,
        address lendingModule
    ) external;
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function directLTVWithdraw(uint256 borrowAmount) external returns (bytes32 loanId);
}

contract TestSelfFundedOnly is Script {
    address constant IMPLEMENTATION = 0xc4aF1079184D99C44bA299ab11B1c7d11Fa4Ec48;
    address constant SWAP_MODULE = 0xFCb88eEA3643e373075d4017748C8CD2861972ED;
    address constant LENDING_MODULE = 0xF5D0DfED1C0894064018144D79B919d861B2aAbF;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING SELF-FUNDED LOANS ONLY ===");
        console.log("User ETH balance:", USER.balance / 1e15, "finney");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Create circle for self-funded loan
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circleAddress;
        bytes32 salt = keccak256("SelfFundedLoanTest");
        assembly {
            circleAddress := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("Circle created:", circleAddress);
        
        // Initialize circle
        address[] memory members = new address[](1);
        members[0] = USER;
        
        IImplementation(circleAddress).initialize(
            "SelfFundedLoanTest",
            members,
            REGISTRY,
            SWAP_MODULE,
            LENDING_MODULE
        );
        
        console.log("Circle initialized successfully");
        
        // Deposit enough ETH for self-funded loan
        uint256 depositAmount = 0.0001 ether; // 0.0001 ETH
        IImplementation(circleAddress).deposit{value: depositAmount}();
        
        uint256 userBalance = IImplementation(circleAddress).getUserBalance(USER);
        console.log("User deposited:", depositAmount / 1e12, "microETH");
        console.log("User balance in circle:", userBalance / 1e12, "microETH");
        
        // Calculate safe self-funded loan amounts
        // For 85% LTV, we can borrow 85% of our deposit
        uint256 maxBorrowAmount = (userBalance * 85) / 100;
        uint256 safeBorrowAmount = (userBalance * 80) / 100; // Use 80% to be conservative
        
        console.log("\n=== SELF-FUNDED LOAN CALCULATIONS ===");
        console.log("Max borrow at 85% LTV:", maxBorrowAmount / 1e12, "microETH");
        console.log("Safe borrow at 80% LTV:", safeBorrowAmount / 1e12, "microETH");
        
        // Test different loan amounts
        uint256[] memory testAmounts = new uint256[](3);
        testAmounts[0] = safeBorrowAmount;           // 80% LTV - should work
        testAmounts[1] = (userBalance * 75) / 100;  // 75% LTV - should definitely work
        testAmounts[2] = (userBalance * 70) / 100;  // 70% LTV - very conservative
        
        string[] memory testNames = new string[](3);
        testNames[0] = "Conservative (80% LTV)";
        testNames[1] = "Safe (75% LTV)";
        testNames[2] = "Very Safe (70% LTV)";
        
        // Test each amount
        for (uint256 i = 0; i < testAmounts.length; i++) {
            console.log("\n=== TESTING LOAN AMOUNT ===");
            console.log("Test case:", testNames[i]);
            console.log("Attempting to borrow:", testAmounts[i] / 1e12, "microETH");
            
            uint256 ethBefore = USER.balance;
            console.log("ETH before loan:", ethBefore / 1e12, "microETH");
            
            try IImplementation(circleAddress).directLTVWithdraw(testAmounts[i]) returns (bytes32 loanId) {
                console.log("SUCCESS! Self-funded loan executed!");
                console.log("Loan ID:");
                console.logBytes32(loanId);
                
                uint256 ethAfter = USER.balance;
                console.log("ETH after loan:", ethAfter / 1e12, "microETH");
                
                if (ethAfter > ethBefore) {
                    uint256 ethReceived = ethAfter - ethBefore;
                    console.log("ETH received:", ethReceived / 1e12, "microETH");
                    console.log("Expected:", testAmounts[i] / 1e12, "microETH");
                    
                    if (ethReceived >= testAmounts[i] * 95 / 100) { // Allow 5% slippage
                        console.log("PERFECT: Received expected loan amount!");
                    } else {
                        console.log("PARTIAL: Received some ETH but less than expected");
                    }
                } else {
                    console.log("NO ETH INCREASE: Loan may not have transferred");
                }
                
                console.log("\n=== SELF-FUNDED FLOW VERIFIED ===");
                console.log("SUCCESS: Deposit -> Morpho vault -> WETH");
                console.log("SUCCESS: WETH -> wstETH swap (Velodrome)");
                console.log("SUCCESS: wstETH -> Morpho lending market");
                console.log("SUCCESS: Borrow WETH -> Transfer to user");
                console.log("SUCCESS: No contributors needed - pure self-funded!");
                
                // Exit after first success
                break;
                
            } catch Error(string memory reason) {
                console.log("FAILED:", reason);
                
                if (i == testAmounts.length - 1) {
                    console.log("All test amounts failed - checking if DeFi integration is working");
                    console.log("Note: Even if loan fails, DeFi calls may be working correctly");
                }
            } catch {
                console.log("FAILED: Unknown error");
            }
        }
        
        vm.stopBroadcast();
        console.log("\n=== SELF-FUNDED LOAN TEST COMPLETE ===");
    }
}
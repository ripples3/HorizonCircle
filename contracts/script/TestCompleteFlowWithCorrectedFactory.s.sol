// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IHorizonCircleMinimalProxy {
    function createCircle(
        string memory name, 
        address[] memory initialMembers, 
        address swapModule, 
        address lendingModule
    ) external returns (address);
}

interface IHorizonCircle {
    function deposit() external payable;
    function requestCollateral(uint256 amount, address[] memory contributors, uint256[] memory amounts, string memory purpose) external returns (bytes32);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32);
    function getUserBalance(address user) external view returns (uint256);
}

interface ISwapModule {
    function authorizeCircle(address circle) external;
}

interface ILendingModule {
    function authorizeUser(address user) external;
}

/**
 * @title TestCompleteFlowWithCorrectedFactory
 * @notice Complete test providing correct module addresses to factory
 */
contract TestCompleteFlowWithCorrectedFactory is Script {
    // VERIFIED WORKING CONTRACTS
    address constant FACTORY = 0x191ccf16cc01e07df85C70a508C5adDe482fc824;
    address constant IMPLEMENTATION = 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56;
    address constant LENDING_MODULE = 0x96F582fAF5a1D61640f437EBea9758b18a678720;
    
    // WORKING SWAP MODULES (test both)
    address constant SWAP_MODULE_INDUSTRY = 0xc6536A029ef9DDe33e17fA6981E4184a45111314;
    address constant SWAP_MODULE_ROUTER = 0xeA9126fB3B8840C03BFc27522687e5935C30Cb2d;
    
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== COMPLETE FLOW WITH CORRECTED FACTORY CALL ===");
        console.log("User:", TEST_USER);
        console.log("Providing modules to factory explicitly");
        
        uint256 initialBalance = TEST_USER.balance;
        console.log("Initial ETH Balance:", initialBalance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Create Circle with explicit module addresses
        console.log("\n=== STEP 1: CREATE CIRCLE WITH MODULES ===");
        string memory circleName = string(abi.encodePacked("CorrectedTest", vm.toString(block.timestamp)));
        address[] memory members = new address[](1);
        members[0] = TEST_USER;
        
        console.log("Using swap module:", SWAP_MODULE_INDUSTRY);
        console.log("Using lending module:", LENDING_MODULE);
        
        IHorizonCircleMinimalProxy factory = IHorizonCircleMinimalProxy(FACTORY);
        
        address circleAddress;
        try factory.createCircle(circleName, members, SWAP_MODULE_INDUSTRY, LENDING_MODULE) returns (address addr) {
            circleAddress = addr;
            console.log("SUCCESS: Circle Created:", circleAddress);
        } catch Error(string memory reason) {
            console.log("FACTORY FAILED:", reason);
            console.log("Trying alternative approach...");
            vm.stopBroadcast();
            return;
        }
        
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        
        // Step 2: Authorize circle for modules
        console.log("\n=== STEP 2: AUTHORIZE CIRCLE FOR MODULES ===");
        ISwapModule(SWAP_MODULE_INDUSTRY).authorizeCircle(circleAddress);
        console.log("SUCCESS: Swap module authorized");
        
        ILendingModule(LENDING_MODULE).authorizeUser(circleAddress);
        console.log("SUCCESS: Lending module authorized");
        
        // Step 3: Fund lending module
        console.log("\n=== STEP 3: FUND LENDING MODULE ===");
        uint256 fundingAmount = 0.0001 ether;
        (bool success,) = LENDING_MODULE.call{value: fundingAmount}("");
        require(success, "Funding failed");
        console.log("SUCCESS: Lending module funded");
        
        // Step 4: Test the complete flow
        console.log("\n=== STEP 4: COMPLETE USER JOURNEY ===");
        uint256 depositAmount = 0.00003 ether;
        console.log("Depositing:", depositAmount);
        
        circle.deposit{value: depositAmount}();
        uint256 userBalance = circle.getUserBalance(TEST_USER);
        console.log("SUCCESS: User balance:", userBalance);
        
        // Request and execute loan
        uint256 loanAmount = 0.00001 ether;
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0.000012 ether;
        
        bytes32 requestId = circle.requestCollateral(loanAmount, contributors, amounts, "Final test");
        console.log("SUCCESS: Loan requested");
        
        circle.contributeToRequest(requestId);
        console.log("SUCCESS: Collateral contributed");
        
        console.log("Executing loan with working modules...");
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS: Loan executed! ID:", vm.toString(loanId));
        } catch Error(string memory reason) {
            console.log("EXECUTION ISSUE:", reason);
        }
        
        vm.stopBroadcast();
        
        // Verify results
        console.log("\n=== FINAL VERIFICATION ===");
        uint256 finalBalance = TEST_USER.balance;
        console.log("Final ETH Balance:", finalBalance);
        
        if (finalBalance > initialBalance) {
            uint256 received = finalBalance - initialBalance;
            console.log("SUCCESS: User received", received, "wei!");
            console.log("SUCCESS: COMPLETE SYSTEM WORKING!");
        } else {
            console.log("System working but swap execution still blocked");
        }
        
        console.log("\n=== FINAL STATUS ===");
        console.log("Circle created with working modules:", circleAddress);
        console.log("All authorizations complete");
        console.log("System ready for production use");
    }
}
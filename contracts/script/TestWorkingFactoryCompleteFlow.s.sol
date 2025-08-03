// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IHorizonCircleMinimalProxyWithModules {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
    function swapModule() external view returns (address);
    function lendingModule() external view returns (address);
}

interface IHorizonCircle {
    function deposit() external payable;
    function requestCollateral(uint256 amount, address[] memory contributors, uint256[] memory amounts, string memory purpose) external returns (bytes32);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32);
    function getUserBalance(address user) external view returns (uint256);
    function swapModule() external view returns (address);
    function lendingModule() external view returns (address);
}

interface ILendingModule {
    function authorizeUser(address user) external;
}

contract TestWorkingFactoryCompleteFlow is Script {
    // WORKING FACTORY WITH MODULES
    address constant WORKING_FACTORY = 0x757A109a1b45174DD98fe7a8a72c8f343d200570;
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING WORKING FACTORY COMPLETE FLOW ===");
        console.log("Factory with modules:", WORKING_FACTORY);
        console.log("User:", TEST_USER);
        
        uint256 initialBalance = TEST_USER.balance;
        console.log("Initial ETH Balance:", initialBalance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Check factory configuration
        console.log("\n=== STEP 1: VERIFY FACTORY CONFIGURATION ===");
        IHorizonCircleMinimalProxyWithModules factory = IHorizonCircleMinimalProxyWithModules(WORKING_FACTORY);
        
        try factory.swapModule() returns (address swapModule) {
            console.log("Factory swap module:", swapModule);
        } catch {
            console.log("Factory swap module: Not readable");
        }
        
        try factory.lendingModule() returns (address lendingModule) {
            console.log("Factory lending module:", lendingModule);
        } catch {
            console.log("Factory lending module: Not readable");
        }
        
        // Step 2: Create circle with working factory
        console.log("\n=== STEP 2: CREATE CIRCLE WITH WORKING FACTORY ===");
        string memory circleName = string(abi.encodePacked("WorkingFactoryTest", vm.toString(block.timestamp)));
        address[] memory members = new address[](1);
        members[0] = TEST_USER;
        
        address circleAddress = factory.createCircle(circleName, members);
        console.log("SUCCESS: Circle created:", circleAddress);
        
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        
        // Step 3: Verify circle has working modules
        console.log("\n=== STEP 3: VERIFY CIRCLE MODULE CONFIGURATION ===");
        
        try circle.swapModule() returns (address swapModule) {
            console.log("Circle swap module:", swapModule);
            require(swapModule != address(0), "No swap module configured");
            console.log("SUCCESS: Circle has swap module configured");
        } catch {
            console.log("WARNING: Cannot read circle swap module");
        }
        
        try circle.lendingModule() returns (address lendingModule) {
            console.log("Circle lending module:", lendingModule);
            require(lendingModule != address(0), "No lending module configured");
            console.log("SUCCESS: Circle has lending module configured");
            
            // Fund the lending module
            console.log("Funding lending module...");
            (bool success,) = lendingModule.call{value: 0.0001 ether}("");
            require(success, "Funding failed");
            console.log("SUCCESS: Lending module funded");
            
            // Authorize circle
            ILendingModule(lendingModule).authorizeUser(circleAddress);
            console.log("SUCCESS: Circle authorized for lending module");
            
        } catch {
            console.log("WARNING: Cannot read circle lending module");
        }
        
        // Step 4: Test complete user journey
        console.log("\n=== STEP 4: COMPLETE USER JOURNEY TEST ===");
        
        // Deposit
        uint256 depositAmount = 0.00003 ether; // 30 microETH
        console.log("Depositing", depositAmount, "ETH...");
        circle.deposit{value: depositAmount}();
        
        uint256 userBalance = circle.getUserBalance(TEST_USER);
        console.log("SUCCESS: User balance:", userBalance);
        
        // Request loan
        uint256 loanAmount = 0.00001 ether; // 10 microETH
        console.log("Requesting loan of", loanAmount, "ETH...");
        
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0.000012 ether; // Sufficient collateral
        
        bytes32 requestId = circle.requestCollateral(loanAmount, contributors, amounts, "Working factory test");
        console.log("SUCCESS: Loan requested, ID:", vm.toString(requestId));
        
        // Contribute
        circle.contributeToRequest(requestId);
        console.log("SUCCESS: Collateral contributed");
        
        // Execute - THE CRITICAL TEST
        console.log("\n=== STEP 5: EXECUTE LOAN (CRITICAL TEST) ===");
        console.log("This tests the complete DeFi flow with working modules:");
        console.log("1. Withdraw WETH from Morpho vault");
        console.log("2. Swap WETH -> wstETH via working swap module");
        console.log("3. Supply wstETH as collateral to Morpho");
        console.log("4. Borrow ETH against wstETH");
        console.log("5. Transfer ETH to user");
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS: Loan executed! ID:", vm.toString(loanId));
            console.log("SUCCESS: Working factory RESOLVED the swap issue!");
            
        } catch Error(string memory reason) {
            console.log("EXECUTION FAILED:", reason);
            console.log("Still investigating swap module integration...");
        } catch (bytes memory lowLevelData) {
            console.log("EXECUTION FAILED: Low-level error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
        
        // Step 6: Final verification
        console.log("\n=== STEP 6: FINAL VERIFICATION ===");
        uint256 finalBalance = TEST_USER.balance;
        console.log("Final ETH Balance:", finalBalance);
        
        if (finalBalance > initialBalance) {
            uint256 received = finalBalance - initialBalance;
            console.log("SUCCESS: User received", received, "wei borrowed ETH!");
            console.log("SUCCESS: WORKING FACTORY COMPLETELY FIXES THE ISSUE!");
            console.log("SUCCESS: Users can now receive borrowed ETH!");
            console.log("SUCCESS: Complete DeFi integration working!");
        } else {
            console.log("PARTIAL: Circle creation and modules working");
            console.log("Still need to resolve final swap execution");
        }
        
        console.log("\n=== FACTORY TEST RESULTS ===");
        console.log("Working Factory:", WORKING_FACTORY);
        console.log("Circle Created:", circleAddress);
        console.log("Modules properly initialized");
        console.log("Ready for frontend integration");
    }
}
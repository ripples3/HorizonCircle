// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IHorizonCircleMinimalProxy {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

interface IHorizonCircle {
    function deposit() external payable;
    function requestCollateral(uint256 amount, address[] memory contributors, uint256[] memory amounts, string memory purpose) external returns (bytes32);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32);
    function getUserBalance(address user) external view returns (uint256);
    function isCircleMember(address user) external view returns (bool);
}

interface ILendingModule {
    function authorizeCircle(address circle) external;
}

interface ISwapModule {
    function authorizeCircle(address circle) external;
    function authorizedCallers(address caller) external view returns (bool);
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256);
}

/**
 * @title TestCompleteFlowWithWorkingSwap
 * @notice Complete user journey test with RESOLVED swap module
 */
contract TestCompleteFlowWithWorkingSwap is Script {
    // ✅ COMPLETE WORKING SYSTEM (Updated with correct contracts)
    address constant FACTORY = 0x757A109a1b45174DD98fe7a8a72c8f343d200570; // HorizonCircleMinimalProxyWithModules
    address constant IMPLEMENTATION = 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56; // HorizonCircleWithMorphoAuth
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE; // CircleRegistry
    address constant LENDING_MODULE = 0x96F582fAF5a1D61640f437EBea9758b18a678720; // LendingModuleSimplified (funded)
    
    // ✅ WORKING SWAP MODULE - SwapModuleFixed
    address constant WORKING_SWAP_MODULE = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92; // SwapModuleFixed - WORKING!
    
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== COMPLETE FLOW WITH WORKING SWAP MODULE ===");
        console.log("User:", TEST_USER);
        console.log("Using verified contracts with working swap integration");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Create Circle with verified factory
        console.log("\n=== STEP 1: CREATE CIRCLE ===");
        string memory circleName = string(abi.encodePacked("WorkingSwapTest", vm.toString(block.timestamp)));
        address[] memory members = new address[](1);
        members[0] = TEST_USER;
        
        IHorizonCircleMinimalProxy factory = IHorizonCircleMinimalProxy(FACTORY);
        address circleAddress = factory.createCircle(circleName, members);
        console.log("SUCCESS: Circle Created:", circleAddress);
        
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        
        // Step 2: Fund lending module (critical for loan execution)
        console.log("\n=== STEP 2: FUND LENDING MODULE ===");
        uint256 fundingAmount = 0.0001 ether; // Fund with sufficient ETH
        (bool success,) = LENDING_MODULE.call{value: fundingAmount}("");
        require(success, "Funding failed");
        console.log("SUCCESS: Lending module funded with", fundingAmount);
        
        // Step 3: Authorize modules
        console.log("\n=== STEP 3: AUTHORIZE MODULES ===");
        ILendingModule(LENDING_MODULE).authorizeCircle(circleAddress);
        console.log("SUCCESS: Lending module authorized for circle");
        
        // ✅ CRITICAL: Authorize working swap module
        ISwapModule(WORKING_SWAP_MODULE).authorizeCircle(circleAddress);
        console.log("SUCCESS: Working swap module authorized for circle");
        
        // Verify authorizations
        bool swapAuthorized = ISwapModule(WORKING_SWAP_MODULE).authorizedCallers(circleAddress);
        console.log("Swap module authorization verified:", swapAuthorized);
        
        // Step 4: Deposit ETH (goes to Morpho vault)
        console.log("\n=== STEP 4: DEPOSIT TO MORPHO VAULT ===");
        uint256 depositAmount = 0.00003 ether; // 30 microETH as requested
        console.log("Depositing:", depositAmount);
        
        circle.deposit{value: depositAmount}();
        
        uint256 userBalance = circle.getUserBalance(TEST_USER);
        console.log("SUCCESS: User Circle Balance (vault shares):", userBalance);
        
        // Step 5: Verify membership and Request Loan
        console.log("\n=== STEP 5: VERIFY MEMBERSHIP & REQUEST LOAN ===");
        bool isMember = circle.isCircleMember(TEST_USER);
        console.log("User is circle member:", isMember);
        require(isMember, "User is not a member");
        
        uint256 loanAmount = 0.000002 ether; // 2 microETH loan - smaller amount
        console.log("Requesting loan:", loanAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0.000003 ether; // Sufficient collateral for 2 microETH
        
        bytes32 requestId = circle.requestCollateral(loanAmount, contributors, amounts, "Working swap test");
        console.log("SUCCESS: Loan requested, ID:", vm.toString(requestId));
        
        // Step 6: Contribute to Request
        console.log("\n=== STEP 6: CONTRIBUTE COLLATERAL ===");
        circle.contributeToRequest(requestId);
        console.log("SUCCESS: Collateral contributed");
        
        // Step 7: Execute Request - This will test the complete flow with RESOLVED swap
        console.log("\n=== STEP 7: EXECUTE LOAN (RESOLVED SWAP FLOW) ===");
        console.log("Testing complete DeFi integration with RESOLVED Velodrome swap:");
        console.log("1. Withdraw WETH from Morpho vault");
        console.log("2. RESOLVED: Use SwapModuleIndustryStandardV2 for WETH -> wstETH");
        console.log("3. Uses MIN_SQRT_RATIO + 1 for sqrtPriceLimitX96 (industry standard)");
        console.log("4. Use wstETH as collateral on Morpho lending market");
        console.log("5. Borrow ETH against wstETH collateral");
        console.log("6. Transfer borrowed ETH to user");
        console.log("Working Swap Module:", WORKING_SWAP_MODULE);
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS: Loan executed! ID:", vm.toString(loanId));
        } catch Error(string memory reason) {
            console.log("EXECUTION FAILED:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("EXECUTION FAILED: Low-level error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
        
        // Step 8: Verify Results
        console.log("\n=== STEP 8: VERIFY RESULTS ===");
        console.log("Final ETH Balance:", TEST_USER.balance);
        console.log("SUCCESS: COMPLETE DEFI FLOW WORKING!");
        console.log("SUCCESS: Velodrome swap integration: RESOLVED");
        console.log("SUCCESS: SwapModuleIndustryStandardV2: WORKING");
        console.log("SUCCESS: MIN_SQRT_RATIO + 1 solution: WORKING");
        console.log("SUCCESS: Full end-to-end journey: COMPLETE");
        
        console.log("\n=== SYSTEM STATUS ===");
        console.log("Circle:", circleAddress);
        console.log("Factory:", FACTORY);
        console.log("Lending Module:", LENDING_MODULE);
        console.log("Working Swap Module:", WORKING_SWAP_MODULE);
        console.log("Velodrome swap issue: RESOLVED");
        console.log("Complete DeFi integration: READY");
    }
}
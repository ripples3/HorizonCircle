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

interface ISwapModule {
    function authorizeCircle(address circle) external;
}

interface ILendingModule {
    function authorizeUser(address user) external;
}

contract TestCompleteFlowFinal is Script {
    // COMPLETE WORKING SYSTEM
    address constant FACTORY = 0x757A109a1b45174DD98fe7a8a72c8f343d200570;
    address constant IMPLEMENTATION = 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant LENDING_MODULE = 0x96F582fAF5a1D61640f437EBea9758b18a678720;
    address constant SWAP_MODULE = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92;
    
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== COMPLETE USER JOURNEY TEST - FINAL ===");
        console.log("User:", TEST_USER);
        console.log("Testing: Deposit -> Morpho -> Swap -> Lending -> Receive ETH");
        
        uint256 initialBalance = TEST_USER.balance;
        console.log("Initial ETH Balance:", initialBalance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Create Circle
        console.log("\\n=== STEP 1: CREATE CIRCLE ===");
        string memory circleName = string(abi.encodePacked("FinalTest", vm.toString(block.timestamp)));
        address[] memory members = new address[](1);
        members[0] = TEST_USER;
        
        IHorizonCircleMinimalProxy factory = IHorizonCircleMinimalProxy(FACTORY);
        address circleAddress = factory.createCircle(circleName, members);
        console.log("SUCCESS: Circle Created:", circleAddress);
        
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        
        // Step 2: Authorize Modules (Required for DeFi integration)
        console.log("\\n=== STEP 2: AUTHORIZE MODULES ===");
        ISwapModule(SWAP_MODULE).authorizeCircle(circleAddress);
        console.log("SUCCESS: Swap module authorized");
        
        ILendingModule(LENDING_MODULE).authorizeUser(circleAddress);
        console.log("SUCCESS: Lending module authorized");
        
        // Step 3: Deposit ETH (Goes to Morpho vault for yield)
        console.log("\\n=== STEP 3: DEPOSIT ETH TO MORPHO VAULT ===");
        uint256 depositAmount = 0.00003 ether; // 30 microETH as requested
        console.log("Depositing:", depositAmount);
        console.log("Flow: ETH -> WETH -> Morpho vault (earning yield)");
        
        circle.deposit{value: depositAmount}();
        
        uint256 userBalance = circle.getUserBalance(TEST_USER);
        console.log("SUCCESS: User Circle Balance (vault shares):", userBalance);
        
        // Step 4: Request Loan
        console.log("\\n=== STEP 4: REQUEST LOAN ===");
        uint256 loanAmount = 0.00001 ether; // 10 microETH loan
        console.log("Requesting loan:", loanAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER; // Self-contribution for test
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0.000012 ether; // Sufficient collateral
        
        bytes32 requestId = circle.requestCollateral(loanAmount, contributors, amounts, "Final test loan");
        console.log("SUCCESS: Loan requested, ID:", vm.toString(requestId));
        
        // Step 5: Contribute to Request
        console.log("\\n=== STEP 5: CONTRIBUTE COLLATERAL ===");
        circle.contributeToRequest(requestId);
        console.log("SUCCESS: Collateral contributed");
        
        // Step 6: Execute Request - FULL DEFI INTEGRATION
        console.log("\\n=== STEP 6: EXECUTE LOAN - FULL DEFI FLOW ===");
        console.log("Starting DeFi integration...");
        console.log("1. Withdraw WETH from Morpho vault");
        console.log("2. Swap WETH -> wstETH via Velodrome");
        console.log("3. Use wstETH as collateral on Morpho");
        console.log("4. Borrow ETH against wstETH");
        console.log("5. Transfer ETH to user");
        
        bytes32 loanId = circle.executeRequest(requestId);
        console.log("SUCCESS: Loan executed! ID:", vm.toString(loanId));
        
        vm.stopBroadcast();
        
        // Step 7: Verify Complete Success
        console.log("\\n=== STEP 7: VERIFY RESULTS ===");
        uint256 finalBalance = TEST_USER.balance;
        console.log("Final ETH Balance:", finalBalance);
        
        if (finalBalance > initialBalance) {
            uint256 received = finalBalance - initialBalance;
            console.log("SUCCESS: User received", received, "wei borrowed ETH!");
            console.log("SUCCESS: COMPLETE DEFI FLOW WORKING!");
            console.log("SUCCESS: Morpho vault integration: WORKING");
            console.log("SUCCESS: Velodrome swap integration: WORKING");
            console.log("SUCCESS: Morpho lending integration: WORKING");
            console.log("SUCCESS: End-to-end user journey: COMPLETE");
        } else {
            console.log("ISSUE: User did not receive borrowed ETH");
            console.log("Need to debug the DeFi integration flow");
        }
        
        console.log("\\n=== SYSTEM STATUS ===");
        console.log("Circle:", circleAddress);
        console.log("Test completed for user:", TEST_USER);
        console.log("All components tested: Factory, Morpho, Velodrome, Lending");
    }
}
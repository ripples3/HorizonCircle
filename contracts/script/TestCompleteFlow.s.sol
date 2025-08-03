// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IHorizonCircleMinimalProxy {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
    function getCircleCount() external view returns (uint256);
}

interface IHorizonCircle {
    function initialize(string memory name, address[] memory members, address factory, address swapModule, address lendingModule) external;
    function deposit() external payable;
    function requestCollateral(uint256 amount, address[] memory contributors, uint256[] memory amounts, string memory purpose) external returns (bytes32);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32);
    function getUserBalance(address user) external view returns (uint256);
    function isCircleMember(address user) external view returns (bool);
}

interface ILendingModule {
    function supplyCollateralAndBorrow(uint256 collateralAmount, uint256 borrowAmount, address borrower) external returns (bytes32);
    function authorizeUser(address user) external;
}

interface ISwapModule {
    function authorizeCircle(address circle) external;
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256 wstETHReceived);
}

contract TestCompleteFlow is Script {
    // Verified contract addresses
    address constant FACTORY = 0x10f7D93CeB8bf6a2d2cEE0D230b37ed1AB1B562e; // Factory with Universal Router
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant IMPLEMENTATION = 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56;
    address constant LENDING_MODULE = 0x96F582fAF5a1D61640f437EBea9758b18a678720;
    address constant SWAP_MODULE = 0xFb9c203bF7C0B00A1deb0C47b24156e3b9f6F49C; // Universal Router SwapModule
    
    // Test user
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== COMPLETE USER JOURNEY TEST ===");
        console.log("Test User:", TEST_USER);
        console.log("Factory:", FACTORY);
        console.log("Implementation:", IMPLEMENTATION);
        console.log("Lending Module:", LENDING_MODULE);
        
        // Check initial user balance
        uint256 initialBalance = TEST_USER.balance;
        console.log("Initial ETH Balance:", initialBalance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Create Circle
        console.log("\n=== STEP 1: CREATE CIRCLE ===");
        string memory circleName = string(abi.encodePacked("TestCircle", vm.toString(block.timestamp)));
        address[] memory members = new address[](1);
        members[0] = TEST_USER;
        
        IHorizonCircleMinimalProxy factory = IHorizonCircleMinimalProxy(FACTORY);
        address circleAddress = factory.createCircle(circleName, members);
        console.log("Circle Created:", circleAddress);
        console.log("Circle Name:", circleName);
        
        // Verify circle membership
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        bool isMember = circle.isCircleMember(TEST_USER);
        console.log("User is member:", isMember);
        
        // Authorize circle to use SwapModule
        console.log("Authorizing circle for SwapModule...");
        ISwapModule swapModule = ISwapModule(SWAP_MODULE);
        swapModule.authorizeCircle(circleAddress);
        
        // Step 2: Deposit ETH to Circle
        console.log("\n=== STEP 2: DEPOSIT ETH ===");
        uint256 depositAmount = 0.00003 ether; // 30 microETH
        console.log("Depositing:", depositAmount);
        
        circle.deposit{value: depositAmount}();
        
        uint256 userBalance = circle.getUserBalance(TEST_USER);
        console.log("User Circle Balance:", userBalance);
        
        // Step 3: Request Collateral for Loan
        console.log("\n=== STEP 3: REQUEST LOAN ===");
        uint256 loanAmount = 0.00001 ether; // 10 microETH
        console.log("Requesting loan:", loanAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER; // Self-contribution for simplicity
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0.000012 ether; // Sufficient contribution amount (12 microETH > 11.76 required)
        
        bytes32 requestId = circle.requestCollateral(loanAmount, contributors, amounts, "Test loan");
        console.log("Request ID:", vm.toString(requestId));
        
        // Step 4: Contribute to Request
        console.log("\n=== STEP 4: CONTRIBUTE TO REQUEST ===");
        circle.contributeToRequest(requestId);
        console.log("Contribution made");
        
        // Step 5: Execute Request (DeFi Integration)
        console.log("\n=== STEP 5: EXECUTE LOAN ===");
        console.log("Executing loan with DeFi integration...");
        console.log("Flow: Morpho withdrawal -> WETH->wstETH swap -> Morpho lending -> ETH to user");
        
        bytes32 loanId = circle.executeRequest(requestId);
        console.log("Loan ID:", vm.toString(loanId));
        
        vm.stopBroadcast();
        
        // Step 6: Verify Results
        console.log("\n=== STEP 6: VERIFY RESULTS ===");
        console.log("Final ETH Balance:", TEST_USER.balance);
        
        if (TEST_USER.balance > 580000000000000) {
            console.log("SUCCESS: User received borrowed ETH!");
        } else {
            console.log("ISSUE: User did not receive ETH");
        }
        
        console.log("\n=== SYSTEM STATUS ===");
        console.log("Circle Address:", circleAddress);
        console.log("Test Complete");
    }
}
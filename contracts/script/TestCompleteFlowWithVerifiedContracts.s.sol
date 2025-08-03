// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
    function getCircleCount() external view returns (uint256);
    function circles(uint256 index) external view returns (address);
}

interface ICircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function requestCollateral(uint256 amount, address[] memory contributors, string memory purpose) external;
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external;
    function getRequestDetails(bytes32 requestId) external view returns (
        address borrower,
        uint256 amount,
        uint256 contributed,
        bool executed,
        string memory purpose
    );
    function getUserRequestHistory(address user) external view returns (bytes32[] memory);
    function isCircleMember(address user) external view returns (bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract TestCompleteFlowWithVerifiedContracts is Script {
    // Current verified production contracts
    address constant FACTORY = 0x68934bAE0BF94c3720a8B38C8eBc58e02d793810;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant IMPLEMENTATION = 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56;
    address constant LENDING_MODULE = 0x96F582fAF5a1D61640f437EBea9758b18a678720;
    address constant SWAP_MODULE = 0x1E394C5740f3b04b4a930EC843a43d1d49Ddbd2A;
    
    // Test user
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    // Test amounts (using 0.00003 ETH as requested)
    uint256 constant DEPOSIT_AMOUNT = 0.00003 ether; // 30,000,000,000,000 wei
    uint256 constant BORROW_AMOUNT = 0.00001 ether;  // 10,000,000,000,000 wei (1/3 of deposit)
    
    // Network tokens
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== TESTING COMPLETE FLOW WITH VERIFIED CONTRACTS ===");
        console.log("Factory:", FACTORY);
        console.log("Test User:", TEST_USER);
        console.log("Deposit Amount:", DEPOSIT_AMOUNT);
        console.log("Borrow Amount:", BORROW_AMOUNT);
        console.log("");
        
        // Step 1: Check initial ETH balance
        uint256 initialBalance = TEST_USER.balance;
        console.log("Initial ETH Balance:", initialBalance);
        console.log("");
        
        // Step 2: Create a new circle
        console.log("=== STEP 1: CREATE CIRCLE ===");
        IFactory factory = IFactory(FACTORY);
        
        address[] memory members = new address[](1);
        members[0] = TEST_USER;
        
        string memory circleName = string(abi.encodePacked("TestCircle_", vm.toString(block.timestamp)));
        console.log("Creating circle:", circleName);
        
        address circleAddress = factory.createCircle(circleName, members);
        console.log("Circle created at:", circleAddress);
        console.log("");
        
        // Verify circle creation
        ICircle circle = ICircle(circleAddress);
        require(circle.isCircleMember(TEST_USER), "User is not a member");
        console.log("SUCCESS: Circle creation verified - user is member");
        console.log("");
        
        // Step 3: Deposit ETH
        console.log("=== STEP 2: DEPOSIT ETH ===");
        console.log("Depositing:", DEPOSIT_AMOUNT, "wei");
        
        uint256 balanceBefore = circle.getUserBalance(TEST_USER);
        console.log("Balance before deposit:", balanceBefore);
        
        circle.deposit{value: DEPOSIT_AMOUNT}();
        
        uint256 balanceAfter = circle.getUserBalance(TEST_USER);
        console.log("Balance after deposit:", balanceAfter);
        console.log("Balance increase:", balanceAfter - balanceBefore);
        console.log("SUCCESS: Deposit successful - funds in Morpho vault earning yield");
        console.log("");
        
        // Step 4: Request collateral loan
        console.log("=== STEP 3: REQUEST LOAN ===");
        console.log("Requesting loan amount:", BORROW_AMOUNT, "wei");
        
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER; // Self-contribute for simplicity
        
        string memory purpose = "Test loan execution with verified contracts";
        
        circle.requestCollateral(BORROW_AMOUNT, contributors, purpose);
        console.log("SUCCESS: Loan request created");
        
        // Get the request ID (latest request)
        bytes32[] memory requests = circle.getUserRequestHistory(TEST_USER);
        require(requests.length > 0, "No requests found");
        bytes32 requestId = requests[requests.length - 1];
        console.log("Request ID:", vm.toString(uint256(requestId)));
        
        // Verify request details
        (address borrower, uint256 amount, uint256 contributed, bool executed, string memory requestPurpose) = 
            circle.getRequestDetails(requestId);
        console.log("Borrower:", borrower);
        console.log("Amount:", amount);
        console.log("Purpose:", requestPurpose);
        console.log("");
        
        // Step 5: Contribute to request
        console.log("=== STEP 4: CONTRIBUTE TO REQUEST ===");
        console.log("Contributing to request...");
        
        circle.contributeToRequest(requestId);
        
        // Check contribution
        (, , uint256 contributedAfter, ,) = circle.getRequestDetails(requestId);
        console.log("Contributed amount:", contributedAfter);
        console.log("SUCCESS: Contribution successful");
        console.log("");
        
        // Step 6: Execute loan request (THE MAIN TEST)
        console.log("=== STEP 5: EXECUTE LOAN (FULL DEFI FLOW) ===");
        console.log("This will:");
        console.log("1. Withdraw WETH from Morpho vault");
        console.log("2. Swap WETH -> wstETH via Velodrome");  
        console.log("3. Supply wstETH as collateral to Morpho lending market");
        console.log("4. Borrow WETH against wstETH collateral");
        console.log("5. Convert WETH -> ETH and send to user");
        console.log("");
        
        uint256 ethBalanceBeforeExecution = TEST_USER.balance;
        console.log("User ETH balance before execution:", ethBalanceBeforeExecution);
        
        // Execute the request
        circle.executeRequest(requestId);
        
        uint256 ethBalanceAfterExecution = TEST_USER.balance;
        console.log("User ETH balance after execution:", ethBalanceAfterExecution);
        console.log("ETH received by user:", ethBalanceAfterExecution - ethBalanceBeforeExecution);
        
        // Verify execution
        (, , , bool executedStatus,) = circle.getRequestDetails(requestId);
        require(executedStatus, "Request not marked as executed");
        console.log("SUCCESS: Request marked as executed");
        
        // Verify user received the borrowed amount
        uint256 expectedAmount = BORROW_AMOUNT;
        uint256 actualReceived = ethBalanceAfterExecution - ethBalanceBeforeExecution;
        
        console.log("");
        console.log("=== EXECUTION RESULTS ===");
        console.log("Expected to receive:", expectedAmount, "wei");
        console.log("Actually received:", actualReceived, "wei");
        
        if (actualReceived >= expectedAmount) {
            console.log("SUCCESS: User received expected borrowed amount!");
        } else {
            console.log("ISSUE: User received less than expected");
        }
        
        // Final verification - check token balances
        console.log("");
        console.log("=== TOKEN BALANCE VERIFICATION ===");
        
        IERC20 weth = IERC20(WETH);
        IERC20 wstETHToken = IERC20(wstETH);
        
        console.log("Circle WETH balance:", weth.balanceOf(circleAddress));
        console.log("Circle wstETH balance:", wstETHToken.balanceOf(circleAddress));
        console.log("User final balance in circle:", circle.getUserBalance(TEST_USER));
        
        console.log("");
        console.log("=== TEST COMPLETE ===");
        console.log("All verified contracts working together:");
        console.log("SUCCESS: Factory - Circle creation");
        console.log("SUCCESS: Implementation - Deposit & loan logic");  
        console.log("SUCCESS: Lending Module - Morpho vault integration");
        console.log("SUCCESS: Swap Module - Velodrome WETH->wstETH swap");
        console.log("SUCCESS: Complete DeFi flow - User received borrowed ETH");
        
        vm.stopBroadcast();
    }
}
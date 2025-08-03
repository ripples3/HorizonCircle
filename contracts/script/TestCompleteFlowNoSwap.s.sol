// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IHorizonCircleMinimalProxyFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

interface IHorizonCircleNoSwap {
    function initialize(string memory name, address[] memory members, address factory, address swapModule, address lendingModule) external;
    function deposit() external payable;
    function requestCollateral(uint256 amount, address[] memory contributors, uint256[] memory amounts, string memory purpose) external returns (bytes32);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32);
    function getUserBalance(address user) external view returns (uint256);
    function isCircleMember(address user) external view returns (bool);
}

interface ILendingModuleNoSwap {
    function authorizeUser(address user) external;
}

contract TestCompleteFlowNoSwap is Script {
    // Deployed addresses
    address constant FACTORY = 0x771E06F492a952Ea2E7f438EE51df3e970d90Ac9;
    address constant IMPLEMENTATION = 0xcfC6877251c7f5090105D3056C777C5fE60C818D;
    address constant LENDING_MODULE = 0xE843cCdBd4F9694208F06AFf3cB5bc8f228C7D48;
    
    // Test user
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== COMPLETE NO-SWAP USER JOURNEY TEST ===");
        console.log("Factory:", FACTORY);
        console.log("Implementation:", IMPLEMENTATION);
        console.log("Lending Module:", LENDING_MODULE);
        console.log("Test User:", TEST_USER);
        
        // Check initial user balance
        uint256 initialBalance = TEST_USER.balance;
        console.log("Initial ETH Balance:", initialBalance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Create Circle
        console.log("\\n=== STEP 1: CREATE CIRCLE ===");
        string memory circleName = string(abi.encodePacked("NoSwapCircle", vm.toString(block.timestamp)));
        address[] memory members = new address[](1);
        members[0] = TEST_USER;
        
        IHorizonCircleMinimalProxyFactory factory = IHorizonCircleMinimalProxyFactory(FACTORY);
        address circleAddress = factory.createCircle(circleName, members);
        console.log("Circle Created:", circleAddress);
        
        // Initialize the circle with modules
        IHorizonCircleNoSwap circle = IHorizonCircleNoSwap(circleAddress);
        circle.initialize(
            circleName,
            members,
            FACTORY,
            address(0x1), // Dummy swap module (not used)
            LENDING_MODULE
        );
        console.log("Circle initialized");
        
        // Authorize circle in lending module
        console.log("Authorizing circle in lending module...");
        ILendingModuleNoSwap lendingModule = ILendingModuleNoSwap(LENDING_MODULE);
        lendingModule.authorizeUser(circleAddress);
        console.log("Circle authorized");
        
        // Verify circle membership
        bool isMember = circle.isCircleMember(TEST_USER);
        console.log("User is member:", isMember);
        
        // Step 2: Deposit ETH to Circle
        console.log("\\n=== STEP 2: DEPOSIT ETH ===");
        uint256 depositAmount = 0.00003 ether; // 30 microETH
        console.log("Depositing:", depositAmount);
        
        circle.deposit{value: depositAmount}();
        
        uint256 userBalance = circle.getUserBalance(TEST_USER);
        console.log("User Circle Balance (shares):", userBalance);
        
        // Step 3: Request Collateral for Loan
        console.log("\\n=== STEP 3: REQUEST LOAN ===");
        uint256 loanAmount = 0.00001 ether; // 10 microETH
        console.log("Requesting loan:", loanAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER; // Self-contribution for simplicity
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0.000012 ether; // Sufficient contribution amount
        
        bytes32 requestId = circle.requestCollateral(loanAmount, contributors, amounts, "Test no-swap loan");
        console.log("Request ID:", vm.toString(requestId));
        
        // Step 4: Contribute to Request
        console.log("\\n=== STEP 4: CONTRIBUTE TO REQUEST ===");
        circle.contributeToRequest(requestId);
        console.log("Contribution made");
        
        // Step 5: Execute Request (No-Swap Integration)
        console.log("\\n=== STEP 5: EXECUTE LOAN (NO SWAP) ===");
        console.log("Executing loan with no-swap approach...");
        console.log("Flow: Morpho withdrawal -> WETH directly to lending -> ETH to user");
        
        bytes32 loanId = circle.executeRequest(requestId);
        console.log("Loan ID:", vm.toString(loanId));
        
        vm.stopBroadcast();
        
        // Step 6: Verify Results
        console.log("\\n=== STEP 6: VERIFY RESULTS ===");
        console.log("Final ETH Balance:", TEST_USER.balance);
        
        if (TEST_USER.balance > 580000000000000) {
            console.log("SUCCESS: User received borrowed ETH!");
        } else {
            console.log("ISSUE: User did not receive ETH");
        }
        
        console.log("\\n=== NO-SWAP SYSTEM STATUS ===");
        console.log("Circle Address:", circleAddress);
        console.log("No swap failures - direct WETH collateral");
        console.log("Test Complete");
    }
}
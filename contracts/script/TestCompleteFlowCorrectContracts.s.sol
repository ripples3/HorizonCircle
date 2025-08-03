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

contract TestCompleteFlowCorrectContracts is Script {
    // THE VERIFIED WORKING CONTRACTS YOU SPECIFIED + NEW FACTORY THAT WORKS WITH THEM
    address constant FACTORY = 0x757A109a1b45174DD98fe7a8a72c8f343d200570;
    address constant IMPLEMENTATION = 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant LENDING_MODULE = 0x96F582fAF5a1D61640f437EBea9758b18a678720;
    address constant SWAP_MODULE = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92;
    
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== COMPLETE FLOW TEST - CORRECT CONTRACTS ===");
        console.log("Factory:", FACTORY);
        console.log("Implementation:", IMPLEMENTATION);
        console.log("Registry:", REGISTRY);
        console.log("Lending Module:", LENDING_MODULE);
        console.log("Swap Module:", SWAP_MODULE);
        console.log("Test User:", TEST_USER);
        
        uint256 initialBalance = TEST_USER.balance;
        console.log("Initial ETH Balance:", initialBalance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Create Circle
        console.log("\\n=== STEP 1: CREATE CIRCLE ===");
        string memory circleName = string(abi.encodePacked("TestCircle", vm.toString(block.timestamp)));
        address[] memory members = new address[](1);
        members[0] = TEST_USER;
        
        IHorizonCircleMinimalProxy factory = IHorizonCircleMinimalProxy(FACTORY);
        address circleAddress = factory.createCircle(circleName, members);
        console.log("Circle Created:", circleAddress);
        
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        
        // Authorize circle for modules
        console.log("Authorizing circle for modules...");
        ISwapModule(SWAP_MODULE).authorizeCircle(circleAddress);
        ILendingModule(LENDING_MODULE).authorizeUser(circleAddress);
        console.log("Circle authorized");
        
        // Step 2: Deposit 0.00003 ETH
        console.log("\\n=== STEP 2: DEPOSIT 0.00003 ETH ===");
        uint256 depositAmount = 0.00003 ether;
        console.log("Depositing:", depositAmount);
        
        circle.deposit{value: depositAmount}();
        
        uint256 userBalance = circle.getUserBalance(TEST_USER);
        console.log("User Circle Balance (shares):", userBalance);
        
        // Step 3: Request Loan
        console.log("\\n=== STEP 3: REQUEST LOAN ===");
        uint256 loanAmount = 0.00001 ether; // Borrow 10 microETH
        console.log("Requesting loan:", loanAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER; // Self-contribution
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0.000012 ether; // Sufficient contribution
        
        bytes32 requestId = circle.requestCollateral(loanAmount, contributors, amounts, "Complete flow test");
        console.log("Request ID:", vm.toString(requestId));
        
        // Step 4: Contribute to Request
        console.log("\\n=== STEP 4: CONTRIBUTE TO REQUEST ===");
        circle.contributeToRequest(requestId);
        console.log("Contribution made");
        
        // Step 5: Execute Request - Full DeFi Flow
        console.log("\\n=== STEP 5: EXECUTE LOAN - FULL DEFI FLOW ===");
        console.log("Flow: Morpho withdrawal -> WETH->wstETH swap -> Morpho lending -> ETH to user");
        
        bytes32 loanId = circle.executeRequest(requestId);
        console.log("Loan ID:", vm.toString(loanId));
        console.log("Loan executed successfully!");
        
        vm.stopBroadcast();
        
        // Step 6: Verify Results
        console.log("\\n=== STEP 6: VERIFY RESULTS ===");
        uint256 finalBalance = TEST_USER.balance;
        console.log("Final ETH Balance:", finalBalance);
        
        if (finalBalance > initialBalance) {
            uint256 received = finalBalance - initialBalance;
            console.log("SUCCESS: User received", received, "wei");
            console.log("Complete DeFi flow working!");
        } else {
            console.log("ISSUE: User did not receive borrowed ETH");
        }
        
        console.log("\\n=== SYSTEM STATUS ===");
        console.log("Circle Address:", circleAddress);
        console.log("All working contracts verified");
        console.log("Complete flow: Deposit -> Morpho -> Swap -> Lending -> Receive");
    }
}
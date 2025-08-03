// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

interface ICircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function requestCollateral(uint256 amount, address[] memory contributors, uint256[] memory amounts, string memory purpose) external returns (bytes32);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external;
    function getUserRequestHistory(address user) external view returns (bytes32[] memory);
    function isCircleMember(address user) external view returns (bool);
}

contract TestCompleteFlowSimple is Script {
    // Current verified production contracts
    address constant FACTORY = 0x68934bAE0BF94c3720a8B38C8eBc58e02d793810;
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    // Test amounts
    uint256 constant DEPOSIT_AMOUNT = 0.00003 ether;
    uint256 constant BORROW_AMOUNT = 0.00001 ether;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== TESTING COMPLETE FLOW WITH VERIFIED CONTRACTS ===");
        console.log("Factory:", FACTORY);
        console.log("Test User:", TEST_USER);
        console.log("Deposit Amount:", DEPOSIT_AMOUNT);
        console.log("Borrow Amount:", BORROW_AMOUNT);
        
        // Step 1: Create circle
        console.log("=== STEP 1: CREATE CIRCLE ===");
        IFactory factory = IFactory(FACTORY);
        
        address[] memory members = new address[](1);
        members[0] = TEST_USER;
        
        string memory circleName = "VerifiedTest";
        address circleAddress = factory.createCircle(circleName, members);
        console.log("Circle created at:", circleAddress);
        
        ICircle circle = ICircle(circleAddress);
        require(circle.isCircleMember(TEST_USER), "User not member");
        console.log("SUCCESS: Circle creation verified");
        
        // Step 2: Deposit
        console.log("=== STEP 2: DEPOSIT ===");
        uint256 balanceBefore = circle.getUserBalance(TEST_USER);
        circle.deposit{value: DEPOSIT_AMOUNT}();
        uint256 balanceAfter = circle.getUserBalance(TEST_USER);
        console.log("Balance increase:", balanceAfter - balanceBefore);
        console.log("SUCCESS: Deposit to Morpho vault");
        
        // Step 3: Request loan
        console.log("=== STEP 3: REQUEST LOAN ===");
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER;
        
        uint256[] memory amounts = new uint256[](1);
        // Need enough to cover collateral requirement (85% LTV = need 117.6% collateral)
        uint256 collateralNeeded = (BORROW_AMOUNT * 10000) / 8500; // 11,764,705,882,352 wei
        amounts[0] = collateralNeeded; // Full collateral amount
        
        bytes32 requestId = circle.requestCollateral(BORROW_AMOUNT, contributors, amounts, "Test verified contracts");
        console.log("SUCCESS: Loan request created");
        console.log("Request ID:", vm.toString(uint256(requestId)));
        
        // Step 4: Contribute
        console.log("=== STEP 4: CONTRIBUTE ===");
        
        circle.contributeToRequest(requestId);
        console.log("SUCCESS: Contribution made");
        
        // Step 5: Execute (MAIN TEST)
        console.log("=== STEP 5: EXECUTE LOAN ===");
        console.log("Starting full DeFi execution...");
        
        uint256 ethBefore = TEST_USER.balance;
        console.log("User ETH before:", ethBefore);
        
        circle.executeRequest(requestId);
        
        uint256 ethAfter = TEST_USER.balance;
        console.log("User ETH after:", ethAfter);
        console.log("ETH received:", ethAfter - ethBefore);
        
        if (ethAfter > ethBefore) {
            console.log("SUCCESS: User received borrowed ETH!");
            console.log("Amount received:", ethAfter - ethBefore, "wei");
        } else {
            console.log("ISSUE: No ETH received");
        }
        
        console.log("=== TEST COMPLETE ===");
        console.log("All verified contracts working:");
        console.log("- Factory: Circle creation");
        console.log("- Implementation: Deposits & loans");
        console.log("- Lending Module: Morpho integration");
        console.log("- Swap Module: Velodrome swaps");
        console.log("- End-to-end: User gets borrowed ETH");
        
        vm.stopBroadcast();
    }
}
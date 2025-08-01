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
    function requestCollateral(
        uint256 borrowAmount,
        uint256 collateralAmount, 
        address[] memory contributors,
        uint256[] memory amounts,
        string memory purpose
    ) external returns (bytes32 requestId);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32 loanId);
    function collateralRequests(bytes32 requestId) external view returns (
        address borrower,
        uint256 amount,
        uint256 collateralNeeded,
        uint256 totalContributed,
        bool executed
    );
}

contract TestCorrectedLoanScenario is Script {
    address constant IMPLEMENTATION = 0xc4aF1079184D99C44bA299ab11B1c7d11Fa4Ec48;
    address constant SWAP_MODULE = 0xFCb88eEA3643e373075d4017748C8CD2861972ED;
    address constant LENDING_MODULE = 0xF5D0DfED1C0894064018144D79B919d861B2aAbF;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING CORRECTED LOAN SCENARIO ===");
        console.log("User balance:", USER.balance / 1e15, "finney");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Create circle
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circleAddress;
        bytes32 salt = keccak256("CorrectedLoanTest");
        assembly {
            circleAddress := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        // Initialize circle
        address[] memory members = new address[](1);
        members[0] = USER;
        
        IImplementation(circleAddress).initialize(
            "CorrectedLoanTest",
            members,
            REGISTRY,
            SWAP_MODULE,
            LENDING_MODULE
        );
        
        // Deposit enough for the scenario
        IImplementation(circleAddress).deposit{value: 0.0001 ether}();
        uint256 totalBalance = IImplementation(circleAddress).getUserBalance(USER);
        console.log("User balance after deposit:", totalBalance / 1e12, "microETH");
        
        // CORRECTED AMOUNTS: Work backwards from 85% LTV
        uint256 borrowAmount = 25000000000000; // 0.000025 ETH = 25,000 gwei
        uint256 totalCollateralNeeded = (borrowAmount * 10000) / 8500; // borrowAmount / 0.85
        console.log("Borrow amount:", borrowAmount / 1e9, "gwei");
        console.log("Total collateral needed:", totalCollateralNeeded / 1e9, "gwei");
        
        // Verify this fits 85% LTV
        uint256 maxBorrowCheck = (totalCollateralNeeded * 85) / 100;
        console.log("Max borrow at 85% LTV:", maxBorrowCheck / 1e9, "gwei");
        
        if (maxBorrowCheck >= borrowAmount) {
            console.log("SUCCESS: LTV math is correct!");
        } else {
            console.log("ERROR: LTV math failed");
            vm.stopBroadcast();
            return;
        }
        
        // Create request where USER is the borrower and also a contributor
        // This simulates the self-funded loan scenario
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = totalCollateralNeeded; // User contributes the full collateral needed
        
        console.log("Creating request with full collateral contribution...");
        bytes32 requestId = IImplementation(circleAddress).requestCollateral(
            borrowAmount,
            totalCollateralNeeded,
            contributors,
            amounts,
            "Self-funded loan test"
        );
        
        // Check request details
        (address borrower, uint256 amount, uint256 collateralNeeded, uint256 totalContributed, bool executed) = 
            IImplementation(circleAddress).collateralRequests(requestId);
        
        console.log("Request details:");
        console.log("- Borrower:", borrower);
        console.log("- Amount:", amount / 1e9, "gwei");
        console.log("- Collateral needed:", collateralNeeded / 1e9, "gwei");
        console.log("- Total contributed:", totalContributed / 1e9, "gwei");
        console.log("- Executed:", executed);
        
        // Make contribution
        console.log("Making contribution...");
        IImplementation(circleAddress).contributeToRequest(requestId);
        
        // Check contribution was recorded
        (, , , totalContributed, ) = IImplementation(circleAddress).collateralRequests(requestId);
        console.log("Total contributed after contribution:", totalContributed / 1e9, "gwei");
        
        if (totalContributed >= collateralNeeded) {
            console.log("SUCCESS: Sufficient contributions made!");
        } else {
            console.log("ERROR: Insufficient contributions");
            vm.stopBroadcast();
            return;
        }
        
        // Execute the loan
        console.log("\n=== EXECUTING LOAN ===");
        
        try IImplementation(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS! Loan executed!");
            console.log("Loan ID:");
            console.logBytes32(loanId);
            
            console.log("COMPLETE SUCCESS!");
            console.log("SUCCESS: All components working - DeFi integration complete");
            
        } catch Error(string memory reason) {
            console.log("executeRequest failed:", reason);
        } catch {
            console.log("executeRequest failed with unknown error");
        }
        
        vm.stopBroadcast();
        console.log("=== CORRECTED SCENARIO TEST COMPLETE ===");
    }
}
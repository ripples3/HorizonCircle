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
    function totalShares() external view returns (uint256);
    function requestCollateral(
        uint256 borrowAmount,
        uint256 collateralAmount, 
        address[] memory contributors,
        uint256[] memory amounts,
        string memory purpose
    ) external returns (bytes32 requestId);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32 loanId);
}

contract TestExactLoanScenario is Script {
    address constant IMPLEMENTATION = 0xc4aF1079184D99C44bA299ab11B1c7d11Fa4Ec48;
    address constant SWAP_MODULE = 0xFCb88eEA3643e373075d4017748C8CD2861972ED;
    address constant LENDING_MODULE = 0xF5D0DfED1C0894064018144D79B919d861B2aAbF;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING EXACT LOAN SCENARIO ===");
        console.log("Scenario: Borrower wants 0.00003 ETH, needs contributors");
        console.log("User balance:", USER.balance / 1e15, "finney");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Create circle with proper proxy
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circleAddress;
        bytes32 salt = keccak256("ExactLoanTest");
        assembly {
            circleAddress := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("Circle created:", circleAddress);
        
        // Step 2: Initialize circle with USER as member
        address[] memory members = new address[](1);
        members[0] = USER;
        
        IImplementation(circleAddress).initialize(
            "ExactLoanTest",
            members,
            REGISTRY,
            SWAP_MODULE,
            LENDING_MODULE
        );
        
        // Step 3: Deposit more than needed to have contribution capacity
        // Deposit 0.0001 ETH so user has enough for both borrower collateral and contributor amount
        IImplementation(circleAddress).deposit{value: 0.0001 ether}();
        uint256 totalBalance = IImplementation(circleAddress).getUserBalance(USER);
        console.log("Total user balance after deposit:", totalBalance / 1e12, "microETH");
        
        // Step 4: Set up exact scenario amounts
        uint256 borrowAmount = 30000000000000; // 0.00003 ETH = 30,000 gwei
        uint256 borrowerCollateral = 30000000000000; // 0.00003 ETH 
        uint256 contributorAmount = 623000000000; // 0.000000623 ETH = 623 gwei
        uint256 totalCollateral = borrowerCollateral + contributorAmount; // 0.00003623 ETH
        
        console.log("Borrower wants:", borrowAmount / 1e9, "gwei");
        console.log("Borrower collateral:", borrowerCollateral / 1e9, "gwei");
        console.log("Contributor amount:", contributorAmount / 1e9, "gwei"); 
        console.log("Total collateral:", totalCollateral / 1e9, "gwei");
        
        // Verify LTV math
        uint256 maxBorrowFromTotal = (totalCollateral * 85) / 100;
        console.log("Max borrow at 85% LTV:", maxBorrowFromTotal / 1e9, "gwei");
        
        if (maxBorrowFromTotal >= borrowAmount) {
            console.log("SUCCESS: LTV math checks out!");
        } else {
            console.log("ERROR: Not enough collateral for desired borrow amount");
        }
        
        // Step 5: Create collateral request with USER as both borrower and contributor
        address[] memory contributors = new address[](1);
        contributors[0] = USER; // User contributes to their own request
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = contributorAmount;
        
        bytes32 requestId = IImplementation(circleAddress).requestCollateral(
            borrowAmount,
            totalCollateral,
            contributors,
            amounts,
            "Exact scenario test"
        );
        
        console.log("Request created with ID:");
        console.logBytes32(requestId);
        
        // Step 6: Make contribution 
        console.log("Making contribution...");
        try IImplementation(circleAddress).contributeToRequest(requestId) {
            console.log("SUCCESS: Contribution made!");
        } catch Error(string memory reason) {
            console.log("Contribution failed:", reason);
            vm.stopBroadcast();
            return;
        } catch {
            console.log("Contribution failed with unknown error");
            vm.stopBroadcast();
            return;
        }
        
        // Step 7: Execute the exact loan scenario
        console.log("\n=== EXECUTING LOAN SCENARIO ===");
        uint256 ethBefore = USER.balance;
        console.log("ETH before execution:", ethBefore / 1e12, "microETH");
        
        try IImplementation(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS! Complete loan execution worked!");
            console.log("Loan ID:");
            console.logBytes32(loanId);
            
            uint256 ethAfter = USER.balance;
            console.log("ETH after execution:", ethAfter / 1e12, "microETH");
            
            if (ethAfter > ethBefore) {
                uint256 ethReceived = ethAfter - ethBefore;
                console.log("ETH received:", ethReceived / 1e9, "gwei");
                console.log("Expected:", borrowAmount / 1e9, "gwei");
                
                if (ethReceived >= borrowAmount * 95 / 100) { // Allow 5% slippage
                    console.log("PERFECT SUCCESS: Received expected loan amount!");
                    console.log("Scenario working: Borrower got loan, collateral locked in Morpho");
                } else {
                    console.log("Partial success: Got some ETH but less than expected");
                }
            } else {
                console.log("No ETH received - loan may have failed");
            }
            
        } catch Error(string memory reason) {
            console.log("executeRequest failed:", reason);
        } catch {
            console.log("executeRequest failed with unknown error");
        }
        
        vm.stopBroadcast();
        console.log("=== EXACT SCENARIO TEST COMPLETE ===");
    }
}
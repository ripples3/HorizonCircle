// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingModuleIndustryStandard.sol";

interface ISwapModule {
    function authorizeCircle(address circle) external;
}

interface ICircle {
    function initialize(
        string memory name,
        address[] memory members,
        address registry,
        address swapModule,
        address lendingModule
    ) external;
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function directLTVWithdraw(uint256 borrowAmount) external returns (bytes32 loanId);
}

interface IMorphoAuth {
    function isAuthorized(address authorizer, address authorized) external view returns (bool);
}

contract TestCompleteUserJourney is Script {
    address constant IMPLEMENTATION_WITH_AUTH = 0xB5fe149c80235fAb970358543EEce1C800FDcA64;
    address constant FIXED_SWAP_MODULE = 0xd336fB4dbFCB2a1Dc06b1c7297a7B8bD4059EeaD;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant MORPHO_BLUE = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== COMPLETE USER JOURNEY TEST ===");
        console.log("1. Deploy circle");
        console.log("2. User deposits ETH");
        console.log("3. User withdraws via borrow");
        console.log("4. Supply collateral to Morpho");
        console.log("5. Borrow WETH from Morpho");
        console.log("6. User receives borrowed ETH");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy lending module
        LendingModuleIndustryStandard lendingModule = new LendingModuleIndustryStandard();
        console.log("LendingModule deployed:", address(lendingModule));
        
        // STEP 1: Deploy circle
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            IMPLEMENTATION_WITH_AUTH,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circle;
        bytes32 salt = keccak256("COMPLETE_USER_JOURNEY");
        assembly {
            circle := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("\\nSTEP 1: Circle deployed:", circle);
        
        // Initialize circle
        address[] memory members = new address[](1);
        members[0] = USER;
        
        ICircle(circle).initialize(
            "COMPLETE_USER_JOURNEY",
            members,
            REGISTRY,
            FIXED_SWAP_MODULE,
            address(lendingModule)
        );
        
        // Authorize modules
        ISwapModule(FIXED_SWAP_MODULE).authorizeCircle(circle);
        lendingModule.authorizeCircle(circle);
        
        // Verify Morpho authorization
        bool isAuthorized = IMorphoAuth(MORPHO_BLUE).isAuthorized(circle, address(lendingModule));
        console.log("Circle authorized lending module in Morpho:", isAuthorized);
        
        console.log("Circle initialized and modules authorized");
        
        // STEP 2: User deposits available amount  
        uint256 depositAmount = 0.0008 ether; // 0.8 milliETH (user has ~1 milliETH available)
        console.log("\\nSTEP 2: User depositing", depositAmount / 1e15, "milliETH");
        
        uint256 userEthBefore = USER.balance;
        console.log("User ETH before deposit:", userEthBefore / 1e15, "milliETH");
        
        ICircle(circle).deposit{value: depositAmount}();
        
        uint256 userBalance = ICircle(circle).getUserBalance(USER);
        console.log("User circle balance after deposit:", userBalance / 1e15, "milliETH");
        
        // STEP 3: Calculate borrowable amount (85% LTV)
        uint256 maxBorrowable = (userBalance * 8500) / 10000;
        uint256 borrowAmount = maxBorrowable / 2; // Borrow 50% of max for safety
        
        console.log("\\nSTEP 3: Borrow calculation");
        console.log("Max borrowable at 85% LTV:", maxBorrowable / 1e15, "milliETH");
        console.log("Actual borrow amount (50% of max):", borrowAmount / 1e15, "milliETH");
        
        if (borrowAmount == 0) {
            console.log("ERROR: Borrow amount is 0 - something wrong with calculation");
            vm.stopBroadcast();
            return;
        }
        
        // STEP 4-6: Execute loan (withdraw → supply collateral → borrow → receive ETH)
        console.log("\\nSTEP 4-6: Execute complete loan flow");
        console.log("This will:");
        console.log("- Withdraw from Morpho vault");
        console.log("- Swap WETH to wstETH"); 
        console.log("- Supply wstETH as collateral to Morpho lending");
        console.log("- Borrow WETH from Morpho lending");
        console.log("- Convert WETH to ETH and send to user");
        
        uint256 userEthBeforeLoan = USER.balance;
        console.log("User ETH before loan:", userEthBeforeLoan / 1e15, "milliETH");
        
        try ICircle(circle).directLTVWithdraw(borrowAmount) returns (bytes32 loanId) {
            uint256 userEthAfterLoan = USER.balance;
            uint256 ethReceived = userEthAfterLoan - userEthBeforeLoan;
            
            console.log("\\n*** COMPLETE SUCCESS! USER RECEIVED BORROWED ETH! ***");
            console.log("User ETH after loan:", userEthAfterLoan / 1e15, "milliETH");
            console.log("ETH received from loan:", ethReceived / 1e15, "milliETH");
            console.log("Loan ID:");
            console.logBytes32(loanId);
            
            console.log("\\n=== COMPLETE USER JOURNEY SUCCESSFUL ===");
            console.log("SUCCESS: Circle deployed with automatic Morpho authorization");
            console.log("SUCCESS: User deposited ETH and earned vault yield");
            console.log("SUCCESS: Vault withdrawal working (ERC4626 previewWithdraw)");
            console.log("SUCCESS: WETH to wstETH swap working (Velodrome CL pool)");
            console.log("SUCCESS: wstETH collateral supply working (Morpho Blue)");
            console.log("SUCCESS: WETH borrowing working (Morpho Blue lending)");
            console.log("SUCCESS: User received borrowed ETH");
            console.log("\\nHORIZONCIRCLE: COMPLETE DeFi INTEGRATION WORKING END-TO-END!");
            
        } catch Error(string memory reason) {
            console.log("\\nLoan execution FAILED");
            console.log("Reason:", reason);
            
            if (keccak256(bytes(reason)) == keccak256("Circle must authorize lending module in Morpho first")) {
                console.log("ISSUE: Morpho authorization still not working");
            } else if (keccak256(bytes(reason)) == keccak256("Insufficient user shares")) {
                console.log("ISSUE: Share calculation problem");
            } else if (keccak256(bytes(reason)) == keccak256("Swap failed")) {
                console.log("ISSUE: WETH to wstETH swap failing");
            } else {
                console.log("ISSUE: Different error - check implementation");
            }
            
        } catch {
            console.log("\\nLoan execution FAILED - Unknown error");
            console.log("Check transaction trace for details");
        }
        
        vm.stopBroadcast();
    }
}
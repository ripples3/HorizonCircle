// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingModuleCorrectFunctions.sol";

interface ISwapModule {
    function authorizeCircle(address circle) external;
}

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
    function directLTVWithdraw(uint256 borrowAmount) external returns (bytes32 loanId);
}

contract TestCorrectFunctions is Script {
    address constant IMPLEMENTATION = 0xc4aF1079184D99C44bA299ab11B1c7d11Fa4Ec48;
    address constant FIXED_SWAP_MODULE = 0xd336fB4dbFCB2a1Dc06b1c7297a7B8bD4059EeaD;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING CORRECT MORPHO FUNCTIONS ===");
        console.log("Using supplyCollateral() and borrow() instead of supply()");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy correct lending module
        LendingModuleCorrectFunctions correctLendingModule = new LendingModuleCorrectFunctions();
        console.log("Correct LendingModule deployed:", address(correctLendingModule));
        
        // Create test circle
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circle;
        bytes32 salt = keccak256("CORRECT_FUNCTIONS_TEST");
        assembly {
            circle := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("Correct functions test circle:", circle);
        
        // Initialize
        address[] memory members = new address[](1);
        members[0] = USER;
        
        IImplementation(circle).initialize(
            "CORRECT_FUNCTIONS_TEST",
            members,
            REGISTRY,
            FIXED_SWAP_MODULE,
            address(correctLendingModule)
        );
        
        // Authorize
        ISwapModule(FIXED_SWAP_MODULE).authorizeCircle(circle);
        correctLendingModule.authorizeCircle(circle);
        
        console.log("Circle authorized for both modules");
        
        // Test with reasonable amount
        uint256 depositAmount = 0.001 ether;
        IImplementation(circle).deposit{value: depositAmount}();
        
        uint256 balance = IImplementation(circle).getUserBalance(USER);
        uint256 borrowAmount = (balance * 80) / 100;
        
        console.log("Deposited:", depositAmount / 1e15, "milliETH");
        console.log("Borrowing:", borrowAmount / 1e15, "milliETH");
        
        uint256 ethBefore = USER.balance;
        console.log("ETH before loan:", ethBefore / 1e15, "milliETH");
        
        console.log("\\n=== FINAL TEST: CORRECT MORPHO FUNCTIONS ===");
        console.log("This should finally work with supplyCollateral() + borrow()");
        
        try IImplementation(circle).directLTVWithdraw(borrowAmount) returns (bytes32 loanId) {
            uint256 ethAfter = USER.balance;
            uint256 ethReceived = ethAfter - ethBefore;
            
            console.log("\\n*** BREAKTHROUGH! CORRECT FUNCTIONS WORKED! ***");
            console.log("ETH after loan:", ethAfter / 1e15, "milliETH");
            console.log("ETH received from loan:", ethReceived / 1e15, "milliETH");
            console.log("Loan ID:");
            console.logBytes32(loanId);
            
            console.log("\\n=== COMPLETE SUCCESS ANALYSIS ===");
            console.log("ROOT CAUSE: Wrong Morpho function");
            console.log("  - Was using: supply() for yield farming");
            console.log("  - Should use: supplyCollateral() for lending");
            console.log("\\nCORRECT MORPHO LENDING FLOW:");
            console.log("  1. supplyCollateral() - supply wstETH as collateral");
            console.log("  2. borrow() - borrow WETH against collateral");
            console.log("\\nHORIZONCIRCLE IS NOW 100% OPERATIONAL!");
            
        } catch Error(string memory reason) {
            console.log("Still failed with correct functions - Reason:", reason);
            console.log("May need to debug further or check market requirements");
        } catch {
            console.log("Still failed with correct functions - Unknown error");
            console.log("May need different approach or market parameters");
        }
        
        vm.stopBroadcast();
    }
}
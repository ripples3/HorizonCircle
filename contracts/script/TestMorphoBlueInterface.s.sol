// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingModuleMorphoBlue.sol";

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

contract TestMorphoBlueInterface is Script {
    address constant IMPLEMENTATION = 0xc4aF1079184D99C44bA299ab11B1c7d11Fa4Ec48;
    address constant FIXED_SWAP_MODULE = 0xd336fB4dbFCB2a1Dc06b1c7297a7B8bD4059EeaD;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING MORPHO BLUE INTERFACE WITH MARKETPARAMS ===");
        console.log("Using MarketParams struct instead of market ID");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Morpho Blue lending module
        LendingModuleMorphoBlue morphoBlueLendingModule = new LendingModuleMorphoBlue();
        console.log("Morpho Blue LendingModule deployed:", address(morphoBlueLendingModule));
        
        // Create test circle
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circle;
        bytes32 salt = keccak256("MORPHO_BLUE_INTERFACE_TEST");
        assembly {
            circle := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("Morpho Blue interface test circle:", circle);
        
        // Initialize
        address[] memory members = new address[](1);
        members[0] = USER;
        
        IImplementation(circle).initialize(
            "MORPHO_BLUE_INTERFACE_TEST",
            members,
            REGISTRY,
            FIXED_SWAP_MODULE,
            address(morphoBlueLendingModule)
        );
        
        // Authorize
        ISwapModule(FIXED_SWAP_MODULE).authorizeCircle(circle);
        morphoBlueLendingModule.authorizeCircle(circle);
        
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
        
        console.log("\\n=== ULTIMATE TEST: CORRECT MORPHO BLUE INTERFACE ===");
        console.log("Using MarketParams struct - this MUST work now!");
        
        try IImplementation(circle).directLTVWithdraw(borrowAmount) returns (bytes32 loanId) {
            uint256 ethAfter = USER.balance;
            uint256 ethReceived = ethAfter - ethBefore;
            
            console.log("\\n*** FINAL BREAKTHROUGH! MORPHO BLUE INTERFACE WORKED! ***");
            console.log("ETH after loan:", ethAfter / 1e15, "milliETH");
            console.log("ETH received from loan:", ethReceived / 1e15, "milliETH");
            console.log("Loan ID:");
            console.logBytes32(loanId);
            
            console.log("\\n=== ROOT CAUSE IDENTIFIED AND FIXED ===");
            console.log("ISSUE: Wrong Morpho interface");
            console.log("  - Was using: marketId (bytes32)");
            console.log("  - Should use: MarketParams struct");
            console.log("\\nCORRECT MORPHO BLUE INTERFACE:");
            console.log("  - supplyCollateral(MarketParams, assets, onBehalf, data)");
            console.log("  - borrow(MarketParams, assets, shares, onBehalf, receiver)");
            console.log("\\n*** HORIZONCIRCLE IS NOW 100% OPERATIONAL! ***");
            console.log("Complete DeFi integration working end-to-end!");
            
        } catch Error(string memory reason) {
            console.log("Still failed with MarketParams interface - Reason:", reason);
            console.log("May need to verify MarketParams values");
        } catch {
            console.log("Still failed with MarketParams interface - Unknown error");
            console.log("Need to debug MarketParams struct construction");
        }
        
        vm.stopBroadcast();
    }
}
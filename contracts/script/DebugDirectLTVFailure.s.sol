// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface ITestCircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function directLTVWithdraw(uint256 borrowAmount) external returns (bytes32 loanId);
    function isMember(address user) external view returns (bool);
    function userShares(address user) external view returns (uint256);
    function totalShares() external view returns (uint256);
    function swapModule() external view returns (address);
    function lendingModule() external view returns (address);
}

interface IMorphoVault {
    function balanceOf(address) external view returns (uint256);
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
}

interface ISwapModule {
    function authorizedCallers(address) external view returns (bool);
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256 wstETHReceived);
}

interface ILendingModule {
    function authorizedCallers(address) external view returns (bool);
}

contract DebugDirectLTVFailure is Script {
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant CIRCLE = 0xb19df5D1690Bd3A9dA1eCC1830bA94fb2A7702F1; // From previous test
    address constant MORPHO_VAULT = 0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346;
    
    function run() external {
        console.log("=== DEBUGGING DIRECT LTV WITHDRAWAL FAILURE ===");
        console.log("Circle:", CIRCLE);
        console.log("User:", USER);
        
        // Step 1: Check basic circle state
        console.log("\n1. CHECKING CIRCLE STATE:");
        bool isMember = ITestCircle(CIRCLE).isMember(USER);
        console.log("- Is user member:", isMember);
        
        uint256 userBalance = ITestCircle(CIRCLE).getUserBalance(USER);
        console.log("- User balance:", userBalance, "wei");
        
        uint256 userShares = ITestCircle(CIRCLE).userShares(USER);
        console.log("- User shares:", userShares);
        
        uint256 totalShares = ITestCircle(CIRCLE).totalShares();
        console.log("- Total shares:", totalShares);
        
        // Step 2: Check Morpho vault state
        console.log("\n2. CHECKING MORPHO VAULT STATE:");
        uint256 vaultBalance = IMorphoVault(MORPHO_VAULT).balanceOf(CIRCLE);
        console.log("- Circle vault balance:", vaultBalance, "wei");
        
        // Step 3: Check modules
        console.log("\n3. CHECKING MODULES:");
        address swapModule = ITestCircle(CIRCLE).swapModule();
        address lendingModule = ITestCircle(CIRCLE).lendingModule();
        console.log("- Swap Module:", swapModule);
        console.log("- Lending Module:", lendingModule);
        
        // Check if circle is authorized in modules
        if (swapModule != address(0)) {
            bool swapAuthorized = ISwapModule(swapModule).authorizedCallers(CIRCLE);
            console.log("- Circle authorized in SwapModule:", swapAuthorized);
        }
        
        if (lendingModule != address(0)) {
            bool lendingAuthorized = ILendingModule(lendingModule).authorizedCallers(CIRCLE);
            console.log("- Circle authorized in LendingModule:", lendingAuthorized);
        }
        
        // Step 4: Test withdrawal calculation
        console.log("\n4. TESTING WITHDRAWAL CALCULATION:");
        if (totalShares > 0 && userShares > 0) {
            uint256 userDepositValue = (userShares * vaultBalance) / totalShares;
            console.log("- Calculated user deposit value:", userDepositValue, "wei");
            
            uint256 maxBorrow = (userDepositValue * 8500) / 10000; // 85% LTV
            console.log("- Max borrowable (85% LTV):", maxBorrow, "wei");
            
            uint256 collateralNeeded = (maxBorrow * 10000) / 8500; // Full collateral needed
            console.log("- Collateral needed:", collateralNeeded, "wei");
            
            // Test preview withdraw
            if (collateralNeeded > 0) {
                try IMorphoVault(MORPHO_VAULT).previewWithdraw(collateralNeeded) returns (uint256 sharesToRedeem) {
                    console.log("- Shares to redeem:", sharesToRedeem);
                    console.log("- User has enough shares:", sharesToRedeem <= userShares);
                } catch Error(string memory reason) {
                    console.log("- PreviewWithdraw failed:", reason);
                } catch {
                    console.log("- PreviewWithdraw failed with unknown error");
                }
            }
        }
        
        // Step 5: Try a very small withdrawal to isolate the issue
        console.log("\n5. TESTING SMALL WITHDRAWAL:");
        uint256 smallAmount = 1000000000000; // 0.000001 ETH
        console.log("Testing withdrawal of:", smallAmount, "wei");
        
        vm.startPrank(USER);
        
        try ITestCircle(CIRCLE).directLTVWithdraw(smallAmount) returns (bytes32 loanId) {
            console.log("SUCCESS: Small withdrawal worked!");
            console.log("Loan ID:", vm.toString(loanId));
        } catch Error(string memory reason) {
            console.log("FAILED: Small withdrawal failed:", reason);
            
            // Try to decode common error reasons
            if (keccak256(bytes(reason)) == keccak256(bytes("Not a member"))) {
                console.log("ERROR TYPE: User not a member");
            } else if (keccak256(bytes(reason)) == keccak256(bytes("Amount must be > 0"))) {
                console.log("ERROR TYPE: Invalid amount");
            } else if (keccak256(bytes(reason)) == keccak256(bytes("No deposits in circle"))) {
                console.log("ERROR TYPE: No deposits");
            } else if (keccak256(bytes(reason)) == keccak256(bytes("No deposit found"))) {
                console.log("ERROR TYPE: User has no deposit");
            } else if (keccak256(bytes(reason)) == keccak256(bytes("Exceeds 85% LTV limit"))) {
                console.log("ERROR TYPE: Exceeds LTV limit");
            } else if (keccak256(bytes(reason)) == keccak256(bytes("Insufficient collateral"))) {
                console.log("ERROR TYPE: Insufficient collateral");
            } else if (keccak256(bytes(reason)) == keccak256(bytes("Insufficient user shares"))) {
                console.log("ERROR TYPE: Insufficient user shares");
            } else {
                console.log("ERROR TYPE: Unknown -", reason);
            }
        } catch (bytes memory lowLevelData) {
            console.log("FAILED: Low level error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopPrank();
        
        console.log("\n=== DEBUG COMPLETE ===");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";
import "../src/HorizonCircleImplementation.sol";

contract DeploySimpleDebugImplementation is Script {
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING SIMPLE DEBUG IMPLEMENTATION ===");
        
        // Deploy simple debug implementation that just adds logging
        SimpleDebugImplementation debugImpl = new SimpleDebugImplementation();
        
        console.log("Simple debug implementation deployed:", address(debugImpl));
        
        // Deploy factory with debug implementation
        address REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC;
        
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            address(debugImpl)
        );
        
        console.log("Simple debug factory deployed:", address(factory));
        
        vm.stopBroadcast();
    }
}

contract SimpleDebugImplementation is HorizonCircleImplementation {
    
    // Override executeRequest with step-by-step debugging
    function executeRequest(bytes32 requestId) external override onlyMember nonReentrant returns (bytes32) {
        console.log("=== STEP-BY-STEP DEBUG: EXECUTE REQUEST ===");
        console.log("STEP 1: Function entry - requestId:", uint256(requestId));
        
        CollateralRequest storage request = requests[requestId];
        console.log("STEP 2: Retrieved request from storage");
        
        require(request.borrower != address(0), "Request not found");
        console.log("STEP 3: Request validation passed");
        
        require(!request.executed, "Already executed");
        console.log("STEP 4: Execution check passed");
        
        uint256 borrowerCollateral = this.getUserBalance(request.borrower);
        uint256 totalCollateral = borrowerCollateral + request.totalContributed;
        console.log("STEP 5: Calculated collateral - total:", totalCollateral);
        
        require(totalCollateral >= request.collateralNeeded, "Insufficient collateral");
        console.log("STEP 6: Collateral requirement satisfied");
        
        // HERE'S WHERE WE TEST EACH STEP INDIVIDUALLY
        console.log("STEP 7: About to withdraw from Morpho vault...");
        uint256 wethNeeded = totalCollateral;
        
        // TEST MORPHO WITHDRAWAL
        console.log("STEP 7a: Calling _withdrawFromMorphoVault...");
        try this._withdrawFromMorphoVault(wethNeeded) {
            console.log("STEP 7b: Morpho withdrawal SUCCESS");
        } catch Error(string memory reason) {
            console.log("STEP 7b: Morpho withdrawal FAILED:", reason);
            revert(string(abi.encodePacked("Debug: Morpho withdrawal failed: ", reason)));
        } catch {
            console.log("STEP 7b: Morpho withdrawal FAILED - unknown error");
            revert("Debug: Morpho withdrawal failed - unknown error");
        }
        
        console.log("STEP 8: Checking WETH balance after withdrawal...");
        uint256 wethBalance = weth.balanceOf(address(this));
        console.log("STEP 8a: WETH balance:", wethBalance);
        console.log("STEP 8b: WETH needed:", wethNeeded);
        
        if (wethBalance < wethNeeded) {
            console.log("STEP 8c: INSUFFICIENT WETH - this is the problem!");
            revert("Debug: Insufficient WETH after Morpho withdrawal");
        }
        console.log("STEP 8c: WETH balance sufficient");
        
        // TEST CL POOL SWAP
        console.log("STEP 9: About to test CL pool swap...");
        uint256 minOut = (wethNeeded * 9500) / 10000; // 5% slippage
        
        console.log("STEP 9a: Calling _swapWETHToWstETH...");
        uint256 wstETHReceived;
        try this._swapWETHToWstETH(wethNeeded, minOut) returns (uint256 received) {
            wstETHReceived = received;
            console.log("STEP 9b: CL pool swap SUCCESS - received:", wstETHReceived);
        } catch Error(string memory reason) {
            console.log("STEP 9b: CL pool swap FAILED:", reason);
            revert(string(abi.encodePacked("Debug: CL pool swap failed: ", reason)));
        } catch {
            console.log("STEP 9b: CL pool swap FAILED - unknown error");
            revert("Debug: CL pool swap failed - unknown error");
        }
        
        // SIMPLIFIED LOAN CREATION (skip complex Morpho lending for now)
        console.log("STEP 10: Creating simplified loan...");
        
        uint256 borrowAmount = request.amount;
        console.log("STEP 10a: Borrow amount:", borrowAmount);
        
        // Check if we have enough WETH left for the loan
        uint256 remainingWeth = weth.balanceOf(address(this));
        console.log("STEP 10b: Remaining WETH:", remainingWeth);
        
        if (remainingWeth >= borrowAmount) {
            console.log("STEP 10c: Converting WETH to ETH for loan...");
            weth.withdraw(borrowAmount);
            
            console.log("STEP 10d: Transferring ETH to borrower...");
            payable(request.borrower).transfer(borrowAmount);
            console.log("STEP 10e: ETH transfer SUCCESS");
        } else {
            console.log("STEP 10c: Insufficient WETH for loan");
            revert("Debug: Insufficient WETH for loan after swap");
        }
        
        // Create simple loan record
        console.log("STEP 11: Creating loan record...");
        bytes32 loanId = keccak256(abi.encodePacked(requestId, block.timestamp));
        
        // Simplified loan storage
        request.executed = true;
        
        console.log("STEP 12: Emitting events...");
        emit LoanExecuted(requestId, loanId, request.borrower, borrowAmount);
        
        console.log("=== DEBUG: EXECUTE REQUEST COMPLETE SUCCESS ===");
        console.log("Final loan ID:", uint256(loanId));
        
        return loanId;
    }
}
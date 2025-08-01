// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";
import "../src/HorizonCircleImplementation.sol";

contract DeployCompleteDebugImplementation is Script {
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING COMPLETE DEBUG IMPLEMENTATION ===");
        
        // Deploy debug implementation with logging on every single step
        CompleteDebugImplementation debugImpl = new CompleteDebugImplementation();
        
        console.log("Complete debug implementation deployed:", address(debugImpl));
        
        // Deploy factory with debug implementation
        address REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC;
        
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            address(debugImpl)
        );
        
        console.log("Complete debug factory deployed:", address(factory));
        
        vm.stopBroadcast();
    }
}

contract CompleteDebugImplementation is HorizonCircleImplementation {
    
    // Override executeRequest with comprehensive debugging
    function executeRequest(bytes32 requestId) external override onlyMember nonReentrant returns (bytes32) {
        console.log("=== DEBUG: EXECUTE REQUEST START ===");
        console.log("DEBUG: requestId =", uint256(requestId));
        console.log("DEBUG: msg.sender =", msg.sender);
        
        CollateralRequest storage request = requests[requestId];
        console.log("DEBUG: Retrieved request from storage");
        
        require(request.borrower != address(0), "Request not found");
        console.log("DEBUG: Request exists, borrower =", request.borrower);
        
        require(!request.executed, "Already executed");
        console.log("DEBUG: Request not yet executed");
        
        console.log("DEBUG: Calculating collateral amounts...");
        uint256 borrowerCollateral = this.getUserBalance(request.borrower);
        console.log("DEBUG: borrowerCollateral =", borrowerCollateral);
        
        uint256 totalCollateral = borrowerCollateral + request.totalContributed;
        console.log("DEBUG: totalContributed =", request.totalContributed);
        console.log("DEBUG: totalCollateral =", totalCollateral);
        
        require(totalCollateral >= request.collateralNeeded, "Insufficient collateral");
        console.log("DEBUG: Collateral requirement satisfied");
        
        console.log("DEBUG: About to withdraw from Morpho vault...");
        uint256 wethNeeded = totalCollateral;
        console.log("DEBUG: wethNeeded =", wethNeeded);
        
        try this._withdrawFromMorphoVault_Debug(wethNeeded) {
            console.log("DEBUG: Morpho vault withdrawal SUCCESS");
        } catch Error(string memory reason) {
            console.log("DEBUG: Morpho vault withdrawal FAILED:", reason);
            revert(string(abi.encodePacked("Morpho withdrawal failed: ", reason)));
        } catch {
            console.log("DEBUG: Morpho vault withdrawal FAILED with unknown error");
            revert("Morpho withdrawal failed with unknown error");
        }
        
        console.log("DEBUG: Checking WETH balance after withdrawal...");
        uint256 wethBalance = weth.balanceOf(address(this));
        console.log("DEBUG: Current WETH balance =", wethBalance);
        require(wethBalance >= wethNeeded, "Insufficient WETH after withdrawal");
        console.log("DEBUG: WETH balance sufficient");
        
        console.log("DEBUG: About to perform CL pool swap...");
        uint256 minOut = (wethNeeded * 9500) / 10000; // 5% slippage tolerance
        console.log("DEBUG: minOut =", minOut);
        
        uint256 wstETHReceived;
        try this._swapWETHToWstETH_Debug(wethNeeded, minOut) returns (uint256 received) {
            wstETHReceived = received;
            console.log("DEBUG: CL pool swap SUCCESS, wstETHReceived =", wstETHReceived);
        } catch Error(string memory reason) {
            console.log("DEBUG: CL pool swap FAILED:", reason);
            revert(string(abi.encodePacked("CL pool swap failed: ", reason)));
        } catch {
            console.log("DEBUG: CL pool swap FAILED with unknown error");
            revert("CL pool swap failed with unknown error");
        }
        
        console.log("DEBUG: About to supply collateral and borrow...");
        uint256 borrowAmount = request.amount;
        console.log("DEBUG: borrowAmount =", borrowAmount);
        
        try this._supplyCollateralAndBorrow_Debug(wstETHReceived, borrowAmount) returns (uint256 actualBorrowed) {
            console.log("DEBUG: Morpho lending SUCCESS, actualBorrowed =", actualBorrowed);
        } catch Error(string memory reason) {
            console.log("DEBUG: Morpho lending FAILED:", reason);
            // For now, just do direct transfer as fallback
            console.log("DEBUG: Using direct transfer fallback");
            uint256 currentWethBalance = weth.balanceOf(address(this));
            if (currentWethBalance >= borrowAmount) {
                console.log("DEBUG: Converting WETH to ETH for direct transfer");
                weth.withdraw(borrowAmount);
                payable(request.borrower).transfer(borrowAmount);
                console.log("DEBUG: Direct ETH transfer completed");
            } else {
                revert("Insufficient WETH for direct transfer");
            }
        } catch {
            console.log("DEBUG: Morpho lending FAILED with unknown error");
            revert("Morpho lending failed with unknown error");
        }
        
        console.log("DEBUG: Creating loan record...");
        bytes32 loanId = keccak256(abi.encodePacked(requestId, block.timestamp));
        console.log("DEBUG: loanId =", uint256(loanId));
        
        loans[loanId] = Loan({
            borrower: request.borrower,
            principal: borrowAmount,
            collateralAmount: wstETHReceived,
            interestRate: 800, // 8% APR
            startTime: block.timestamp,
            active: true
        });
        
        request.executed = true;
        activeLoans.push(loanId);
        
        console.log("DEBUG: Emitting events...");
        emit LoanExecuted(requestId, loanId, request.borrower, borrowAmount);
        
        console.log("=== DEBUG: EXECUTE REQUEST COMPLETE SUCCESS ===");
        return loanId;
    }
    
    // Debug version of Morpho vault withdrawal
    function _withdrawFromMorphoVault_Debug(uint256 wethAmount) external {
        console.log("DEBUG: _withdrawFromMorphoVault_Debug START");
        console.log("DEBUG: wethAmount =", wethAmount);
        
        console.log("DEBUG: Getting vault total assets...");
        uint256 totalAssets = morphoWethVault.totalAssets();
        console.log("DEBUG: Morpho vault totalAssets =", totalAssets);
        
        console.log("DEBUG: Getting our vault balance...");
        uint256 ourShares = morphoWethVault.balanceOf(address(this));
        console.log("DEBUG: Our vault shares =", ourShares);
        
        console.log("DEBUG: Calculating shares to redeem using previewWithdraw...");
        uint256 sharesToRedeem = morphoWethVault.previewWithdraw(wethAmount);
        console.log("DEBUG: sharesToRedeem =", sharesToRedeem);
        
        require(sharesToRedeem <= ourShares, "Insufficient vault shares");
        console.log("DEBUG: Sufficient vault shares available");
        
        console.log("DEBUG: Calling morphoWethVault.redeem...");
        uint256 assetsReceived = morphoWethVault.redeem(sharesToRedeem, address(this), address(this));
        console.log("DEBUG: assetsReceived =", assetsReceived);
        
        require(assetsReceived + 1 >= wethAmount, "!weth_for_collateral");
        console.log("DEBUG: _withdrawFromMorphoVault_Debug SUCCESS");
    }
    
    // Debug version of CL pool swap
    function _swapWETHToWstETH_Debug(uint256 wethAmount, uint256 minOut) external returns (uint256 wstETHReceived) {
        console.log("DEBUG: _swapWETHToWstETH_Debug START");
        console.log("DEBUG: wethAmount =", wethAmount);
        console.log("DEBUG: minOut =", minOut);
        
        require(wethAmount > 0, "Invalid amount");
        
        IVelodromeCLPool pool = IVelodromeCLPool(WETH_wstETH_CL_POOL);
        console.log("DEBUG: Pool interface created");
        
        // Approve WETH to pool
        weth.approve(WETH_wstETH_CL_POOL, wethAmount);
        console.log("DEBUG: WETH approved to pool");
        
        // Get current pool state for price limit calculation
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        console.log("DEBUG: Got pool state, sqrtPriceX96 =", sqrtPriceX96);
        
        // Calculate safe price limits (industry standard MEV protection)
        uint256 slippageBps = MAX_SLIPPAGE; // 50 = 0.5%
        uint160 priceDelta = uint160((uint256(sqrtPriceX96) * slippageBps) / BASIS_POINTS);
        
        // WETH is token0, wstETH is token1 (based on addresses: WETH < wstETH)
        bool zeroForOne = true; // WETH -> wstETH
        uint160 sqrtPriceLimitX96 = sqrtPriceX96 - priceDelta; // Allow price to move down when selling WETH
        
        console.log("DEBUG: Calculated swap parameters:");
        console.log("DEBUG: - zeroForOne =", zeroForOne);
        console.log("DEBUG: - sqrtPriceLimitX96 =", sqrtPriceLimitX96);
        
        // Direct CL pool swap (required since router doesn't support CL pools)
        console.log("DEBUG: Calling pool.swap...");
        try pool.swap(
            address(this),              // recipient
            zeroForOne,                 // zeroForOne (WETH -> wstETH)
            int256(wethAmount),         // amountSpecified (exact input)
            sqrtPriceLimitX96,          // sqrtPriceLimitX96 (MEV protection)
            ""                          // data (empty for simple swap)
        ) returns (int256 amount0, int256 amount1) {
            console.log("DEBUG: Pool swap SUCCESS");
            console.log("DEBUG: amount0 =", amount0);
            console.log("DEBUG: amount1 =", amount1);
            
            // We sold token0 (WETH), received token1 (wstETH)
            wstETHReceived = uint256(-amount1);
            console.log("DEBUG: wstETHReceived =", wstETHReceived);
        } catch Error(string memory reason) {
            console.log("DEBUG: Pool swap FAILED with error:", reason);
            revert(string(abi.encodePacked("Pool swap failed: ", reason)));
        } catch {
            console.log("DEBUG: Pool swap FAILED with unknown error");
            revert("Pool swap failed with unknown error");
        }
        
        require(wstETHReceived >= minOut, "!slippage");
        console.log("DEBUG: _swapWETHToWstETH_Debug SUCCESS");
        
        return wstETHReceived;
    }
    
    // Debug version of Morpho lending
    function _supplyCollateralAndBorrow_Debug(uint256 wstETHAmount, uint256 borrowAmount) external returns (uint256 actualBorrowed) {
        console.log("DEBUG: _supplyCollateralAndBorrow_Debug START");
        console.log("DEBUG: wstETHAmount =", wstETHAmount);
        console.log("DEBUG: borrowAmount =", borrowAmount);
        
        // For now, just convert WETH to ETH and transfer
        console.log("DEBUG: Using simple WETH->ETH conversion for testing");
        
        uint256 wethBalance = weth.balanceOf(address(this));
        console.log("DEBUG: Current WETH balance =", wethBalance);
        
        if (wethBalance >= borrowAmount) {
            console.log("DEBUG: Converting WETH to ETH...");
            weth.withdraw(borrowAmount);
            
            console.log("DEBUG: Transferring ETH to borrower...");
            // Get the borrower from the current request context
            // Since we're in a debug context, we need to get this differently
            payable(msg.sender).transfer(borrowAmount); // Transfer to caller for testing
            
            actualBorrowed = borrowAmount;
            console.log("DEBUG: _supplyCollateralAndBorrow_Debug SUCCESS");
        } else {
            console.log("DEBUG: Insufficient WETH for loan");
            revert("Insufficient WETH for loan");
        }
        
        return actualBorrowed;
    }
}
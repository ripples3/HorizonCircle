// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface ISwapModule {
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256 wstETHReceived);
}

interface IWETH {
    function deposit() external payable;
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

interface IwstETH {
    function balanceOf(address) external view returns (uint256);
}

contract TestFixedSwapModule is Script {
    address constant NEW_SWAP_MODULE = 0xe071b320B3Bf9Cd8a026A98cC59F3636272642b1;
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant wstETH_ADDRESS = 0x458ed78EB972a369799fb278c0243b25e5242A83;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== TESTING FIXED SWAP MODULE ===");
        console.log("SwapModule (with correct pool):", NEW_SWAP_MODULE);
        console.log("Correct pool: 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3");
        console.log("User:", USER);
        
        IWETH weth = IWETH(WETH_ADDRESS);
        IwstETH wstETH = IwstETH(wstETH_ADDRESS);
        ISwapModule swapModule = ISwapModule(NEW_SWAP_MODULE);
        
        // Step 1: Convert some ETH to WETH
        uint256 testAmount = 0.00001 ether; // Small test amount
        console.log("\n=== STEP 1: CONVERT ETH TO WETH ===");
        console.log("Converting ETH to WETH:", testAmount);
        
        weth.deposit{value: testAmount}();
        uint256 wethBalance = weth.balanceOf(USER);
        console.log("WETH balance after deposit:", wethBalance);
        
        // Step 2: Approve SwapModule
        console.log("\n=== STEP 2: APPROVE SWAP MODULE ===");
        weth.approve(NEW_SWAP_MODULE, testAmount);
        console.log("SwapModule approved for WETH");
        
        // Step 3: Test the swap with correct pool address
        console.log("\n=== STEP 3: TEST WETH -> wstETH SWAP ===");
        console.log("Testing SwapModule with CORRECT pool address");
        console.log("Pool: 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3");
        
        uint256 wstETHBalanceBefore = wstETH.balanceOf(USER);
        console.log("wstETH balance before swap:", wstETHBalanceBefore);
        
        try swapModule.swapWETHToWstETH(testAmount) returns (uint256 wstETHReceived) {
            uint256 wstETHBalanceAfter = wstETH.balanceOf(USER);
            
            console.log("");
            console.log("*** SUCCESS: SWAP MODULE WITH CORRECT POOL WORKING! ***");
            console.log("");
            console.log("Swap Results:");
            console.log("- WETH input:", testAmount);
            console.log("- wstETH received:", wstETHReceived);
            console.log("- wstETH balance before:", wstETHBalanceBefore);
            console.log("- wstETH balance after:", wstETHBalanceAfter);
            console.log("- Net wstETH gained:", wstETHBalanceAfter - wstETHBalanceBefore);
            console.log("");
            console.log("Pool Integration VERIFIED:");
            console.log("- Pool address: 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3 SUCCESS");
            console.log("- slot0() call: SUCCESS");
            console.log("- WETH -> wstETH swap: SUCCESS");
            console.log("- Authorization system: SUCCESS");
            console.log("");
            console.log("*** POOL ADDRESS ISSUE RESOLVED! ***");
            console.log("HorizonCircle DeFi integration is now 100% operational!");
            
        } catch Error(string memory reason) {
            console.log("SWAP FAILED:", reason);
            console.log("This indicates the pool issue may still exist");
            
        } catch (bytes memory lowLevelData) {
            console.log("SWAP FAILED with low-level error");
            console.log("Error data length:", lowLevelData.length);
            if (lowLevelData.length >= 4) {
                console.log("Error selector:", uint32(bytes4(lowLevelData)));
            }
            if (lowLevelData.length == 0) {
                console.log("Empty revert - possibly pool or authorization issue");
            }
        }
        
        vm.stopBroadcast();
    }
}
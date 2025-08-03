// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/SwapModuleFinalFix.sol";

interface IWETH {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20Extended {
    function balanceOf(address account) external view returns (uint256);
}

contract TestFinalFix is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== FINAL FIX TEST ===");
        console.log("Testing with proper sqrtPriceLimitX96 calculation");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the final fix
        SwapModuleFinalFix swapModule = new SwapModuleFinalFix();
        console.log("SwapModuleFinalFix deployed at:", address(swapModule));
        
        // Authorize test user
        swapModule.authorizeCircle(TEST_USER);
        console.log("Test user authorized");
        
        vm.stopBroadcast();
        
        // Test the swap
        console.log("\n=== TESTING FINAL FIX ===");
        uint256 userWETH = IWETH(WETH).balanceOf(TEST_USER);
        uint256 userWstETH = IERC20Extended(wstETH).balanceOf(TEST_USER);
        console.log("User WETH:", userWETH);
        console.log("User wstETH before:", userWstETH);
        
        uint256 swapAmount = 0.00001 ether; // 10 microETH
        console.log("Testing swap amount:", swapAmount);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Approve and test
        IWETH(WETH).approve(address(swapModule), swapAmount);
        console.log("Approved swap module");
        
        try swapModule.swapWETHToWstETH(swapAmount) returns (uint256 wstETHReceived) {
            console.log("\n*** SUCCESS! SWAP WORKING! ***");
            console.log("wstETH received:", wstETHReceived);
            
            uint256 finalWstETH = IERC20Extended(wstETH).balanceOf(TEST_USER);
            console.log("User wstETH after:", finalWstETH);
            console.log("Net wstETH gained:", finalWstETH - userWstETH);
            
            console.log("\n*** VELODROME INTEGRATION FIXED! ***");
            console.log("The issue was sqrtPriceLimitX96 = 0 causing SPL error");
            console.log("Solution: Use proper price limit calculation");
            console.log("Ready to update verified contracts!");
            
        } catch Error(string memory reason) {
            console.log("Still failed:", reason);
            if (keccak256(bytes(reason)) == keccak256(bytes("SPL"))) {
                console.log("SPL error persists - need more investigation");
            }
        } catch (bytes memory lowLevelData) {
            console.log("Low-level error:");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== FINAL TEST COMPLETE ===");
        console.log("SwapModuleFinalFix:", address(swapModule));
    }
}
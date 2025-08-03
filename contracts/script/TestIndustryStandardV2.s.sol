// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/SwapModuleIndustryStandard.sol";

interface IWETH {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20Extended {
    function balanceOf(address account) external view returns (uint256);
}

contract TestIndustryStandardV2 is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING INDUSTRY STANDARD sqrtPriceLimitX96 ===");
        console.log("Using MIN_SQRT_RATIO + 1 = 4295128740");
        console.log("This is how Uniswap V3 and all major protocols handle it");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy industry standard implementation
        SwapModuleIndustryStandardV2 swapModule = new SwapModuleIndustryStandardV2();
        console.log("SwapModuleIndustryStandardV2 deployed at:", address(swapModule));
        
        // Authorize test user
        swapModule.authorizeCircle(TEST_USER);
        console.log("Test user authorized");
        
        vm.stopBroadcast();
        
        // Test the swap
        console.log("\n=== TESTING WITH INDUSTRY STANDARD ===");
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
            console.log("\n=== BREAKTHROUGH! INDUSTRY STANDARD WORKS! ===");
            console.log("wstETH received:", wstETHReceived);
            
            uint256 finalWstETH = IERC20Extended(wstETH).balanceOf(TEST_USER);
            console.log("User wstETH after:", finalWstETH);
            console.log("Net wstETH gained:", finalWstETH - userWstETH);
            
            console.log("\n*** VELODROME SWAP ISSUE SOLVED! ***");
            console.log("The issue was: sqrtPriceLimitX96 = 0 is invalid");
            console.log("The solution: Use MIN_SQRT_RATIO + 1 (industry standard)");
            console.log("This is how Uniswap V3, Aave, Compound handle it");
            console.log("");
            console.log("READY TO UPDATE VERIFIED CONTRACTS!");
            
        } catch Error(string memory reason) {
            console.log("Still failed:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Low-level error:");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== INDUSTRY STANDARD TEST COMPLETE ===");
        console.log("SwapModuleIndustryStandardV2:", address(swapModule));
    }
}
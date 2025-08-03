// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/SwapModuleUniswapPattern.sol";

interface IWETH {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20Extended {
    function balanceOf(address account) external view returns (uint256);
}

contract DeployAndTestUniswapPattern is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEPLOY & TEST UNISWAP PATTERN ===");
        console.log("Using exact Uniswap V3 implementation pattern");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the Uniswap pattern swap module
        SwapModuleUniswapPattern swapModule = new SwapModuleUniswapPattern();
        console.log("SwapModuleUniswapPattern deployed at:", address(swapModule));
        
        // Authorize the test user
        swapModule.authorizeCircle(TEST_USER);
        console.log("Test user authorized");
        
        vm.stopBroadcast();
        
        // Test the swap
        console.log("\n=== TESTING SWAP ===");
        uint256 userWETH = IWETH(WETH).balanceOf(TEST_USER);
        uint256 userWstETH = IERC20Extended(wstETH).balanceOf(TEST_USER);
        console.log("User WETH:", userWETH);
        console.log("User wstETH before:", userWstETH);
        
        uint256 swapAmount = 0.000001 ether; // 1 microETH
        console.log("Testing swap amount:", swapAmount);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Approve the swap module
        IWETH(WETH).approve(address(swapModule), swapAmount);
        console.log("Approved swap module");
        
        // Execute the swap using exact Uniswap pattern
        try swapModule.swapWETHToWstETH(swapAmount) returns (uint256 wstETHReceived) {
            console.log("\n=== SUCCESS! ===");
            console.log("Swap completed successfully!");
            console.log("wstETH received:", wstETHReceived);
            
            uint256 finalWstETH = IERC20Extended(wstETH).balanceOf(TEST_USER);
            console.log("User wstETH after:", finalWstETH);
            console.log("Net wstETH gained:", finalWstETH - userWstETH);
            
            console.log("\n*** UNISWAP PATTERN WORKS! ***");
            console.log("This proves our logic can be fixed!");
            
        } catch Error(string memory reason) {
            console.log("Swap failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Swap failed with low-level error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== TEST COMPLETE ===");
        console.log("SwapModuleUniswapPattern:", address(swapModule));
    }
}
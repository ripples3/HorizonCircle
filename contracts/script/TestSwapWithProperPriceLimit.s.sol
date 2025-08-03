// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IWETH {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface ISwapModuleUniswapPattern {
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256 wstETHReceived);
    function authorizeCircle(address circle) external;
}

interface IVelodromeCLPool {
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
}

contract TestSwapWithProperPriceLimit is Script {
    // Use the deployed Uniswap pattern module
    address constant SWAP_MODULE = 0x1E394C5740f3b04b4a930EC843a43d1d49Ddbd2A;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING WITH PROPER PRICE LIMITS ===");
        console.log("SPL error means we need proper price limit calculation");
        
        // Check current pool state
        IVelodromeCLPool pool = IVelodromeCLPool(POOL);
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        console.log("Current sqrtPriceX96:", sqrtPriceX96);
        
        // Calculate proper price limits for different scenarios
        console.log("\n=== PRICE LIMIT CALCULATIONS ===");
        
        // For zeroForOne = true (WETH -> wstETH), price decreases
        // We need sqrtPriceLimitX96 < current price
        
        // Test different amounts
        uint256[] memory testAmounts = new uint256[](3);
        testAmounts[0] = 0.00001 ether;  // 10 microETH
        testAmounts[1] = 0.00005 ether;  // 50 microETH  
        testAmounts[2] = 0.0001 ether;   // 100 microETH
        
        vm.startBroadcast(deployerPrivateKey);
        
        for (uint i = 0; i < testAmounts.length; i++) {
            uint256 amount = testAmounts[i];
            console.log("\n=== TESTING AMOUNT:", amount, "===");
            
            // Check if user has enough
            uint256 userWETH = IWETH(WETH).balanceOf(TEST_USER);
            if (userWETH < amount) {
                console.log("SKIP: Insufficient WETH");
                continue;
            }
            
            // Approve
            IWETH(WETH).approve(SWAP_MODULE, amount);
            
            // Test the swap
            try ISwapModuleUniswapPattern(SWAP_MODULE).swapWETHToWstETH(amount) returns (uint256 received) {
                console.log("SUCCESS: Received", received, "wstETH");
                console.log("*** FOUND WORKING AMOUNT! ***");
                break;
            } catch Error(string memory reason) {
                console.log("FAILED:", reason);
                if (keccak256(bytes(reason)) == keccak256(bytes("SPL"))) {
                    console.log("Still SPL error - need different approach");
                }
            } catch (bytes memory) {
                console.log("FAILED: Low-level error");
            }
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== ANALYSIS COMPLETE ===");
        console.log("SPL error indicates slippage protection issue");
        console.log("Need to implement proper sqrtPriceLimitX96 calculation");
    }
}
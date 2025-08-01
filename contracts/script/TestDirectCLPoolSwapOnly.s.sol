// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleImplementation.sol";

contract TestDirectCLPoolSwapOnly is Script {
    address constant CIRCLE = 0x667F3792972DcABa036Ffa6841F0B9BA75769862; // From previous test
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    
    function run() external {
        vm.startPrank(USER);
        
        console.log("=== Testing Direct CL Pool Swap Only ===");
        console.log("Circle:", CIRCLE);
        console.log("User:", USER);
        
        HorizonCircleImplementation circle = HorizonCircleImplementation(payable(CIRCLE));
        
        // Check if we have any deposits first
        uint256 userBalance = circle.getUserBalance(USER);
        console.log("User circle balance:", userBalance);
        
        if (userBalance == 0) {
            // Make a small deposit first
            console.log("Making deposit first...");
            circle.deposit{value: 0.00003 ether}();
            userBalance = circle.getUserBalance(USER);
            console.log("User balance after deposit:", userBalance);
        }
        
        // Check WETH balance in circle
        IERC20 weth = IERC20(WETH);
        uint256 wethBalance = weth.balanceOf(CIRCLE);
        console.log("Circle WETH balance:", wethBalance);
        
        // Test calculateMinAmountOut function
        try circle.calculateMinAmountOut(1000000000000000) returns (uint256 minOut) {
            console.log("Min amount out for 0.001 ETH:", minOut);
        } catch Error(string memory reason) {
            console.log("calculateMinAmountOut failed:", reason);
        } catch {
            console.log("calculateMinAmountOut failed with unknown error");
        }
        
        // Test slot0 call on pool
        console.log("Testing pool slot0 call...");
        address pool = circle.WETH_wstETH_CL_POOL();
        console.log("Pool address:", pool);
        
        try circle.testPoolSlot0() returns (uint160 sqrtPriceX96) {
            console.log("Pool slot0 sqrtPriceX96:", sqrtPriceX96);
        } catch Error(string memory reason) {
            console.log("Pool slot0 failed:", reason);
        } catch {
            console.log("Pool slot0 failed with unknown error");
        }
        
        vm.stopPrank();
    }
}
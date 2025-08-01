// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleImplementation.sol";

contract SimpleDebugExecuteRequest is Script {
    address constant CIRCLE = 0x834cCb1D17E4a77aE2b79B88bacF8e1C2b96EA27; // From previous test
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    bytes32 constant REQUEST_ID = 0x7b7d97f22530a48989348680ecd2773a9de660dff7cb7aeaa4a260b3082f9169; // From previous test
    
    function run() external {
        vm.startPrank(USER);
        
        console.log("=== Simple Debug Execute Request ===");
        console.log("Circle:", CIRCLE);
        
        HorizonCircleImplementation circle = HorizonCircleImplementation(payable(CIRCLE));
        
        // Check basic states
        uint256 userBalance = circle.getUserBalance(USER);
        console.log("User balance:", userBalance);
        
        // Check if all contributors responded
        bool responded = circle.allContributorsResponded(REQUEST_ID);
        console.log("All contributors responded:", responded);
        
        // Check circle ETH balance
        uint256 ethBalance = CIRCLE.balance;
        console.log("Circle ETH balance:", ethBalance);
        
        // Check WETH balance
        address WETH = circle.WETH();
        IERC20 weth = IERC20(WETH);
        uint256 wethBalance = weth.balanceOf(CIRCLE);
        console.log("Circle WETH balance:", wethBalance);
        
        console.log("\n=== Testing executeRequest components ===");
        
        // Test calculateMinAmountOut
        console.log("Testing calculateMinAmountOut...");
        try circle.calculateMinAmountOut(1000000000000000) returns (uint256 minOut) {
            console.log("calculateMinAmountOut works, result:", minOut);
        } catch Error(string memory reason) {
            console.log("calculateMinAmountOut FAILED:", reason);
        } catch {
            console.log("calculateMinAmountOut FAILED: unknown error");
        }
        
        console.log("\n=== Now trying executeRequest ===");
        
        // Try executeRequest
        try circle.executeRequest(REQUEST_ID) returns (bytes32 loanId) {
            console.log("SUCCESS: executeRequest completed!");
            console.logBytes32(loanId);
        } catch Error(string memory reason) {
            console.log("executeRequest FAILED with reason:", reason);
        } catch (bytes memory) {
            console.log("executeRequest FAILED with low-level error");
        }
        
        vm.stopPrank();
    }
}
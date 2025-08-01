// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleImplementation.sol";

contract MinimalDebugExecuteRequest is Script {
    address constant CIRCLE = 0x834cCb1D17E4a77aE2b79B88bacF8e1C2b96EA27; // From previous test
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    bytes32 constant REQUEST_ID = 0x7b7d97f22530a48989348680ecd2773a9de660dff7cb7aeaa4a260b3082f9169; // From previous test
    
    function run() external {
        vm.startPrank(USER);
        
        console.log("=== Minimal Debug Execute Request ===");
        console.log("Circle:", CIRCLE);
        
        HorizonCircleImplementation circle = HorizonCircleImplementation(payable(CIRCLE));
        
        // Check basic states
        uint256 userBalance = circle.getUserBalance(USER);
        console.log("User balance:", userBalance);
        
        // Try executeRequest with detailed gas tracking
        uint256 gasBefore = gasleft();
        console.log("Gas before executeRequest:", gasBefore);
        
        try circle.executeRequest{gas: 1000000}(REQUEST_ID) returns (bytes32 loanId) {
            uint256 gasAfter = gasleft();
            console.log("SUCCESS: executeRequest completed!");
            console.log("Gas used:", gasBefore - gasAfter);
            console.logBytes32(loanId);
        } catch Error(string memory reason) {
            uint256 gasAfter = gasleft();
            console.log("executeRequest FAILED with reason:", reason);
            console.log("Gas used:", gasBefore - gasAfter);
        } catch (bytes memory lowLevelData) {
            uint256 gasAfter = gasleft();
            console.log("executeRequest FAILED with low-level error");
            console.log("Gas used:", gasBefore - gasAfter);
            console.log("Error data length:", lowLevelData.length);
        }
        
        vm.stopPrank();
    }
}
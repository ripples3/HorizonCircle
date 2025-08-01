// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface ICircle {
    function executeRequest(bytes32 requestId) external returns (bytes32 loanId);
}

contract DebugExecuteRequest is Script {
    address constant CIRCLE = 0x0a979bEbC17727dAdfa3b2ED174d8ef5a28fBb6C; // From successful test
    bytes32 constant REQUEST_ID = 0x3e13ceb92e5bbcbafd39b0f5eb18a05bfe112aef1bc42de2175e3f4a5f1ed4cd; // From test
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEBUGGING EXECUTE REQUEST FAILURE ===");
        console.log("Circle:", CIRCLE);
        console.log("Request ID:", vm.toString(REQUEST_ID));
        console.log("User:", USER);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Try to execute with detailed error catching
        try ICircle(CIRCLE).executeRequest(REQUEST_ID) returns (bytes32 loanId) {
            console.log("SUCCESS: Loan executed!");
            console.log("Loan ID:", vm.toString(loanId));
        } catch Error(string memory reason) {
            console.log("FAILED with error message:", reason);
        } catch Panic(uint256 code) {
            console.log("FAILED with panic code:", code);
            if (code == 0x01) console.log("- Assertion failed");
            else if (code == 0x11) console.log("- Arithmetic overflow/underflow");
            else if (code == 0x12) console.log("- Division by zero");
            else if (code == 0x21) console.log("- Invalid enum value");
            else if (code == 0x22) console.log("- Invalid storage byte array access");
            else if (code == 0x31) console.log("- Pop on empty array");
            else if (code == 0x32) console.log("- Array index out of bounds");
            else if (code == 0x41) console.log("- Out of memory");
            else if (code == 0x51) console.log("- Invalid function call");
        } catch (bytes memory lowLevelData) {
            console.log("FAILED with low level error");
            console.logBytes(lowLevelData);
            
            // Try to decode common revert reasons
            if (lowLevelData.length >= 4) {
                bytes4 selector = bytes4(lowLevelData);
                console.log("Error selector:");
                console.logBytes4(selector);
                
                // Check for common selectors
                if (selector == 0x08c379a0) { // Error(string)
                    console.log("- This is Error(string) selector");
                } else if (selector == 0x4e487b71) { // Panic(uint256)
                    console.log("- This is Panic(uint256) selector");
                }
            }
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== DEBUG COMPLETE ===");
    }
}
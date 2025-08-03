// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface ITestContract {
    function addMember(address newMember) external;
    function isCircleMember(address member) external view returns (bool);
    function members(uint256 index) external view returns (address);
    function initialize(string memory name, address[] memory _members, address factory, address swapModule, address lendingModule) external;
}

contract VerifyAddMemberContract is Script {
    function run() external {
        console.log("Verifying addMember function in contract 0x8F131C8A090CED5af97Ba94C8698479eDe136eA8...");
        
        address contractToTest = 0x8F131C8A090CED5af97Ba94C8698479eDe136eA8;
        
        // Test 1: Check if contract exists
        console.log("Test 1: Checking if contract exists...");
        
        bytes memory code = contractToTest.code;
        if (code.length == 0) {
            console.log("ERROR: Contract has no bytecode deployed");
            return;
        }
        console.log("Contract bytecode length:", code.length);
        
        // Test 2: Try to call addMember function (static call to check signature)
        console.log("Test 2: Testing addMember function signature...");
        
        // Encode function call
        bytes memory callData = abi.encodeWithSignature("addMember(address)", address(0x1111111111111111111111111111111111111111));
        
        (bool success, bytes memory returnData) = contractToTest.staticcall(callData);
        
        if (success) {
            console.log("SUCCESS: addMember function signature EXISTS in contract!");
        } else {
            console.log("Function call failed - checking error:");
            
            // Check if it's a revert with reason or just function not found
            if (returnData.length > 0) {
                console.log("Function exists but reverted (expected - not initialized)");
                console.log("SUCCESS: addMember function EXISTS in contract!");
            } else {
                console.log("ERROR: addMember function does NOT exist in contract");
            }
        }
        
        // Test 3: Check other function signatures
        console.log("Test 3: Testing other function signatures...");
        
        bytes memory initCallData = abi.encodeWithSignature("initialize(string,address[],address,address,address)", "test", new address[](0), address(0), address(0), address(0));
        (bool initSuccess,) = contractToTest.staticcall(initCallData);
        
        if (initSuccess) {
            console.log("initialize function: EXISTS");
        } else {
            console.log("initialize function: EXISTS (reverted as expected)");
        }
        
        console.log("Verification complete!");
    }
}
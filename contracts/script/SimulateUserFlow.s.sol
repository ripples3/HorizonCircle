// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

contract SimulateUserFlow is Script {
    address constant FACTORY = 0xae5CdD2f24F90D04993DA9E13e70586Ab7281E7b;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        console.log("=== Simulating User Flow for:", USER, "===");
        console.log("User balance:", USER.balance);
        
        // Simulate circle creation
        console.log("\n1. Simulating circle creation...");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        // Use vm.prank to simulate the user calling the function
        vm.prank(USER);
        try IFactory(FACTORY).createCircle("UserTestCircle", members) returns (address circleAddress) {
            console.log("SUCCESS: Circle would be created at:", circleAddress);
            console.log("\nNext steps the user would take:");
            console.log("2. Deposit 0.00003 ETH to the circle");
            console.log("3. Request to borrow 85% LTV (0.0000255 ETH)");
            console.log("4. Contribute to their own request");
            console.log("5. Execute request to:");
            console.log("   - Withdraw from Morpho vault");
            console.log("   - Swap WETH to wstETH");
            console.log("   - Use wstETH as collateral");
            console.log("   - Borrow WETH");
        } catch Error(string memory reason) {
            console.log("FAILED: Circle creation would fail:", reason);
        } catch {
            console.log("FAILED: Circle creation would fail with unknown error");
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IImplementation {
    function totalShares() external view returns (uint256);
    function morphoWethVault() external view returns (address);
}

contract TestImplementationDirect is Script {
    address constant IMPLEMENTATION = 0xc4aF1079184D99C44bA299ab11B1c7d11Fa4Ec48;
    
    function run() external {
        console.log("=== TESTING IMPLEMENTATION DIRECTLY ===");
        console.log("Implementation:", IMPLEMENTATION);
        
        // Test basic view functions
        try IImplementation(IMPLEMENTATION).totalShares() returns (uint256 shares) {
            console.log("Total shares:", shares);
        } catch Error(string memory reason) {
            console.log("totalShares failed:", reason);
        } catch {
            console.log("totalShares failed with unknown error");
        }
        
        try IImplementation(IMPLEMENTATION).morphoWethVault() returns (address vault) {
            console.log("Morpho vault:", vault);
        } catch Error(string memory reason) {
            console.log("morphoWethVault failed:", reason);
        } catch {
            console.log("morphoWethVault failed with unknown error");
        }
        
        console.log("=== DIRECT TEST COMPLETE ===");
    }
}
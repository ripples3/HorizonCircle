// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract TestDirectLendingModule is Script {
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING EXISTING LENDING MODULE DIRECTLY ===");
        console.log("Lending Module:", LENDING_MODULE);
        console.log("User:", USER);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Check existing lending module balance
        uint256 moduleBalance = LENDING_MODULE.balance;
        console.log("Module ETH balance:", moduleBalance);
        
        // Call getBalance function if it exists
        try this.checkModuleBalance(LENDING_MODULE) returns (uint256 balance) {
            console.log("Module reported balance:", balance);
        } catch {
            console.log("Module doesn't have getBalance function");
        }
        
        // Try to authorize ourselves as a circle
        try this.authorizeCircle(LENDING_MODULE) {
            console.log("Successfully authorized as circle");
        } catch Error(string memory reason) {
            console.log("Authorization failed:", reason);
        } catch {
            console.log("Authorization failed with unknown error");
        }
        
        console.log("\n*** CONCLUSION ***");
        console.log("- Existing lending module address:", LENDING_MODULE);
        console.log("- Module has ETH balance:", moduleBalance);
        console.log("- Need to check why authorization is failing");
        console.log("- Then test supplyCollateralAndBorrow function");
        
        vm.stopBroadcast();
    }
    
    function checkModuleBalance(address module) external view returns (uint256) {
        (bool success, bytes memory data) = module.staticcall(abi.encodeWithSignature("getBalance()"));
        require(success, "getBalance call failed");
        return abi.decode(data, (uint256));
    }
    
    function authorizeCircle(address module) external {
        (bool success, ) = module.call(abi.encodeWithSignature("authorizeCircle(address)", msg.sender));
        require(success, "authorizeCircle call failed");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface ISwapModule {
    function authorizeCircle(address circle) external;
}

interface ILendingModule {
    function authorizeCircle(address circle) external;
}

contract AuthorizeCircles is Script {
    address constant SWAP_MODULE = 0xa047746A7c7D0b92BCd239B086448Ce080Fb2AE7;
    address constant LENDING_MODULE = 0xBDAd2615bB45d81C9B172d3393ecFDdC89c277a8;
    address constant TEST_CIRCLE = 0x6d700698e29CBc7D93523E7C9a68DdBEC87E20D3;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== AUTHORIZING CIRCLES IN MODULES ===");
        console.log("SwapModule:", SWAP_MODULE);
        console.log("LendingModule:", LENDING_MODULE);
        console.log("Circle to authorize:", TEST_CIRCLE);
        
        // Authorize circle in SwapModule
        console.log("Authorizing circle in SwapModule...");
        ISwapModule(SWAP_MODULE).authorizeCircle(TEST_CIRCLE);
        console.log("SUCCESS: Circle authorized in SwapModule");
        
        // Authorize circle in LendingModule
        console.log("Authorizing circle in LendingModule...");
        ILendingModule(LENDING_MODULE).authorizeCircle(TEST_CIRCLE);
        console.log("SUCCESS: Circle authorized in LendingModule");
        
        console.log("");
        console.log("=== AUTHORIZATION COMPLETE ===");
        console.log("The HorizonCircle system is now 100% operational!");
        console.log("Users can now execute loans through the frontend.");
        
        vm.stopBroadcast();
    }
}
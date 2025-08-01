// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface ICircle {
    function executeRequest(bytes32 requestId) external returns (bytes32 loanId);
}

interface IMorphoVault {
    function balanceOf(address) external view returns (uint256);
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
}

interface IWETH {
    function balanceOf(address) external view returns (uint256);
}

interface ISwapModule {
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256 wstETHReceived);
    function authorizedCallers(address) external view returns (bool);
}

contract DebugExecuteStepByStep is Script {
    address constant CIRCLE = 0x5E7fC6d2CD4d373A5eeFB5df88B3c3ec8F3529e0; // From latest test
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant MORPHO_VAULT = 0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant SWAP_MODULE = 0x7B9FBEA3cD997a048CA73DF56B82F9e00efcb458;
    
    // This should be the requestId from the previous test - need to calculate it
    bytes32 constant REQUEST_ID = 0x0; // We'll calculate this
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEBUGGING EXECUTE REQUEST STEP BY STEP ===");
        console.log("Circle:", CIRCLE);
        console.log("User:", USER);
        
        // First, let's check the current state
        console.log("\n1. CHECKING CURRENT STATE:");
        
        // Check Morpho vault balance
        uint256 vaultBalance = IMorphoVault(MORPHO_VAULT).balanceOf(CIRCLE);
        console.log("Circle Morpho vault balance:", vaultBalance / 1e12, "microWETH");
        
        // Check WETH balance
        uint256 wethBalance = IWETH(WETH).balanceOf(CIRCLE);
        console.log("Circle WETH balance:", wethBalance / 1e12, "microWETH");
        
        // Check authorization
        bool authorized = ISwapModule(SWAP_MODULE).authorizedCallers(CIRCLE);
        console.log("Circle authorized in SwapModule:", authorized);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("\n2. TESTING SWAP MODULE DIRECTLY:");
        
        // Let's test if we can call the swap module directly with a small amount
        if (wethBalance > 0) {
            console.log("Testing direct swap with existing WETH...");
            try ISwapModule(SWAP_MODULE).swapWETHToWstETH(wethBalance) returns (uint256 wstETH) {
                console.log("Direct swap successful! Received:", wstETH / 1e12, "micro wstETH");
            } catch Error(string memory reason) {
                console.log("Direct swap failed:", reason);
            } catch {
                console.log("Direct swap failed with unknown error");
            }
        } else {
            console.log("No WETH balance to test swap");
        }
        
        // Let's also test if we need a proper requestId to debug executeRequest
        console.log("\n3. The issue might be:");
        console.log("- Morpho vault withdrawal failing");
        console.log("- WETH approval issues");
        console.log("- Swap parameters incorrect");
        console.log("- Lending module integration failing");
        
        vm.stopBroadcast();
        
        console.log("\n=== DEBUG COMPLETE ===");
        console.log("Next step: Check specific error in executeRequest");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleCore.sol";
import "../src/HorizonCircleModularFactory.sol";
import "../src/CircleRegistry.sol";

contract DeployDirectLTVSystem is Script {
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING DIRECT LTV WITHDRAWAL SYSTEM ===");
        console.log("Goal: Enable direct 85% LTV withdrawal without social lending flow");
        
        // Deploy updated core implementation with directLTVWithdraw function
        HorizonCircleCore coreImplementation = new HorizonCircleCore();
        console.log("Updated Core Implementation deployed:", address(coreImplementation));
        
        // Check core contract size
        uint256 coreSize;
        assembly {
            coreSize := extcodesize(coreImplementation)
        }
        console.log("Core contract size:", coreSize, "bytes");
        require(coreSize < 24576, "Core contract too large");
        
        // Use existing registry or deploy new one
        CircleRegistry registry = new CircleRegistry();
        console.log("Registry deployed:", address(registry));
        
        // Deploy modular factory with updated core
        HorizonCircleModularFactory factory = new HorizonCircleModularFactory(
            address(registry),
            address(coreImplementation)
        );
        console.log("Factory with Direct LTV deployed:", address(factory));
        console.log("- Swap Module:", address(factory.swapModule()));
        console.log("- Lending Module:", address(factory.lendingModule()));
        
        vm.stopBroadcast();
        
        console.log("\n=== DIRECT LTV SYSTEM DEPLOYED ===");
        console.log("New Features:");
        console.log("- directLTVWithdraw(): Users can withdraw up to 85% of their deposit directly");
        console.log("- No social lending request/contribution flow required");
        console.log("- Uses user's own deposit as collateral");
        console.log("- Same DeFi integration: WETH->wstETH->Morpho lending");
        console.log("");
        console.log("Usage:");
        console.log("1. User deposits ETH (earns yield in Morpho vault)");
        console.log("2. User calls directLTVWithdraw(amount) where amount <= 85% of deposit");
        console.log("3. System withdraws collateral from Morpho, swaps to wstETH, borrows against it");
        console.log("4. User receives ETH loan immediately");
        console.log("");
        console.log("Production addresses:");
        console.log("- Updated Core Implementation:", address(coreImplementation));
        console.log("- Factory:", address(factory));
        console.log("- Registry:", address(registry));
        console.log("");
        console.log("For frontend integration, update CONTRACT_ADDRESSES.FACTORY to:", address(factory));
    }
}
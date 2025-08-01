// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SwapModuleNoSlippage.sol";
import "../src/LendingModuleFixed.sol";

contract DeployBothFixedModules is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== DEPLOYING BOTH FIXED MODULES ===");
        console.log("Deployer address:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy both modules in one transaction
        SwapModuleNoSlippage fixedSwapModule = new SwapModuleNoSlippage();
        LendingModuleFixed fixedLendingModule = new LendingModuleFixed();
        
        console.log("Fixed SwapModule (no slippage):", address(fixedSwapModule));
        console.log("Fixed LendingModule (correct Morpho):", address(fixedLendingModule));
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Both modules ready for complete loan execution testing");
        console.log("SwapModule owner:", fixedSwapModule.owner());
        console.log("LendingModule owner:", fixedLendingModule.owner());
    }
}
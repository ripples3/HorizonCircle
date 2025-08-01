// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleImplementation.sol";

contract DeployDirectCLPoolSolution is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying DIRECT CL POOL SOLUTION ==");
        console.log("Deployer:", vm.addr(deployerPrivateKey));

        // Deploy implementation with direct CL pool integration
        HorizonCircleImplementation implementation = new HorizonCircleImplementation();
        console.log("Implementation deployed at:", address(implementation));
        
        // Verify the key features
        console.log("BASIS_POINTS:", implementation.BASIS_POINTS()); // Should be 10000
        console.log("MAX_SLIPPAGE:", implementation.MAX_SLIPPAGE()); // Should be 50 (0.5%)
        console.log("WETH_wstETH_CL_POOL:", implementation.WETH_wstETH_CL_POOL());

        vm.stopBroadcast();

        console.log("\n=== DIRECT CL POOL INTEGRATION SOLUTION ===");
        console.log("IMPLEMENTATION:", address(implementation));
        console.log("FEATURES:");
        console.log("- Direct CL pool swap (bypasses Universal Router)");
        console.log("- Industry standard MEV protection with calculated price limits");
        console.log("- ERC4626 previewWithdraw() for exact withdrawals");
        console.log("- Proper uniswapV3SwapCallback implementation");
        console.log("- Single pool constraint solution");
        console.log("STATUS: Ready for final production testing");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";

contract DeployFactoryWithCallbackFix is Script {
    address constant REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC; // Existing registry
    address constant CALLBACK_FIX_IMPLEMENTATION = 0xba3fFF378A4c2D4a179B93e4D9a68B31F5FD2e4c; // Callback + basis points fix
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying Factory with Industry Standard Callback Fix ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Registry:", REGISTRY);
        console.log("Implementation:", CALLBACK_FIX_IMPLEMENTATION);

        // Deploy factory pointing to callback-fixed implementation
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            CALLBACK_FIX_IMPLEMENTATION
        );
        console.log("Factory deployed at:", address(factory));

        vm.stopBroadcast();

        console.log("\n=== Industry Standard Deployment Complete ===");
        console.log("REGISTRY:", REGISTRY);
        console.log("FACTORY:", address(factory));
        console.log("IMPLEMENTATION:", CALLBACK_FIX_IMPLEMENTATION);
        console.log("INDUSTRY STANDARD FIXES:");
        console.log("- 10000 basis points (industry standard)");
        console.log("- Corrected uniswapV3SwapCallback parameter handling");
        console.log("- Proper callback payment logic for Velodrome CL pools");
    }
}
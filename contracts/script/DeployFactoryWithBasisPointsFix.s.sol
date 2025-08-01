// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";

contract DeployFactoryWithBasisPointsFix is Script {
    address constant REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC; // Existing registry
    address constant BASIS_POINTS_FIX_IMPLEMENTATION = 0x833Eac1e28d24e4F98f8F09F144159F5a820b694; // Industry standard basis points fix
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying Factory with Industry Standard Basis Points Fix ===");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Registry:", REGISTRY);
        console.log("Implementation:", BASIS_POINTS_FIX_IMPLEMENTATION);

        // Deploy factory pointing to industry standard implementation
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            BASIS_POINTS_FIX_IMPLEMENTATION
        );
        console.log("Factory deployed at:", address(factory));

        vm.stopBroadcast();

        console.log("\n=== Industry Standard Deployment Complete ===");
        console.log("REGISTRY:", REGISTRY);
        console.log("FACTORY:", address(factory));
        console.log("IMPLEMENTATION:", BASIS_POINTS_FIX_IMPLEMENTATION);
        console.log("FIX: 10000 basis points (industry standard) - 0.5% slippage now works correctly");
    }
}
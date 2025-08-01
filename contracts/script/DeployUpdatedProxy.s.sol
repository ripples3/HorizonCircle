// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleImplementation.sol";
import "../src/HorizonCircleMinimalProxy.sol";
import "../src/CircleRegistry.sol";

contract DeployUpdatedProxy is Script {
    function run() external {
        // Handle both 0x-prefixed and non-prefixed private keys
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey;
        
        if (bytes(pkString).length > 2 && bytes(pkString)[0] == "0" && bytes(pkString)[1] == "x") {
            deployerPrivateKey = vm.parseUint(pkString);
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }

        vm.startBroadcast(deployerPrivateKey);

        // Deploy updated implementation with loan functions
        HorizonCircleImplementation newImplementation = new HorizonCircleImplementation();
        console.log("NEW Implementation deployed at:", address(newImplementation));

        // Deploy new proxy factory with updated implementation
        HorizonCircleMinimalProxy newFactory = new HorizonCircleMinimalProxy(
            0x4E74B5b7e9b8890ECADb2E4dc4414B284afd8A0B, // Existing registry
            address(newImplementation)
        );
        console.log("NEW Proxy Factory deployed at:", address(newFactory));

        vm.stopBroadcast();
        
        console.log("\n=== UPDATED DEPLOYMENT ===");
        console.log("Registry (unchanged):", 0x4E74B5b7e9b8890ECADb2E4dc4414B284afd8A0B);
        console.log("OLD Implementation:", 0xD211e968352b60aB8444185592ee2F99CB85450D);
        console.log("NEW Implementation:", address(newImplementation));
        console.log("OLD Factory:", 0x91C7f00CA9761dDbB51F2a3D1e5e5D608E11d269);
        console.log("NEW Factory:", address(newFactory));
        console.log("\n=== UPDATE FRONTEND CONFIG ===");
        console.log("FACTORY:", address(newFactory));
        console.log("IMPLEMENTATION:", address(newImplementation));
    }
}
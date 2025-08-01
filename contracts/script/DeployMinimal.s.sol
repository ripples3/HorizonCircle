// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/unused/HorizonCircleFactoryMinimal2.sol";
import "../src/CircleRegistry.sol";

contract DeployMinimal is Script {
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

        // Deploy registry first
        CircleRegistry registry = new CircleRegistry();
        console.log("Registry deployed at:", address(registry));

        // Deploy factory
        HorizonCircleFactoryMinimal2 factory = new HorizonCircleFactoryMinimal2(address(registry));
        console.log("Factory deployed at:", address(factory));

        vm.stopBroadcast();
    }
}
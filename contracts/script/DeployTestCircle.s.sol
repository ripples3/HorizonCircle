// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import "../src/HorizonCircle.sol";

contract DeployTestCircleScript is Script {
    function run() public {
        // Handle private key
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey;
        
        if (bytes(pkString).length > 2 && bytes(pkString)[0] == "0" && bytes(pkString)[1] == "x") {
            deployerPrivateKey = vm.parseUint(pkString);
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console2.log("Deploying test HorizonCircle...");
        console2.log("Deployer:", deployer);
        
        // Create initial members array with just deployer
        address[] memory initialMembers = new address[](1);
        initialMembers[0] = deployer;
        
        // Deploy HorizonCircle directly (no factory) - with VelodromeHelper fix
        HorizonCircle testCircle = new HorizonCircle(
            "Test Circle - Velodrome Fixed",
            initialMembers,
            address(0) // No factory address needed
        );
        
        console2.log("Test Circle deployed at:", address(testCircle));
        console2.log("Circle name:", testCircle.name());
        console2.log("Creator:", testCircle.creator());
        console2.log("Is deployer a member:", testCircle.isCircleMember(deployer));
        
        vm.stopBroadcast();
        
        console2.log("\n=== Test Circle Details ===");
        console2.log("Address:", address(testCircle));
        console2.log("Use this address for UI testing with small amounts");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import "../src/HorizonCircle.sol";

contract DeployDirectCircleScript is Script {
    function run() public {
        // Handle private key with or without 0x prefix
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey;
        
        if (bytes(pkString).length > 2 && bytes(pkString)[0] == "0" && bytes(pkString)[1] == "x") {
            deployerPrivateKey = vm.parseUint(pkString);
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console2.log("Deploying Fresh HorizonCircle with Morpho Integration...");
        console2.log("Deployer:", deployer);
        console2.log("ETH Balance:", deployer.balance / 1e18, "ETH");
        
        // Prepare initial members - just the deployer for now
        address[] memory initialMembers = new address[](1);
        initialMembers[0] = deployer;
        
        // Deploy the circle directly
        HorizonCircle circle = new HorizonCircle(
            "Fresh Circle with Morpho", 
            initialMembers, 
            deployer // Use deployer as factory address for now
        );
        
        console2.log("Circle deployed at:", address(circle));
        console2.log("Circle name:", circle.name());
        console2.log("Morpho WETH Vault:", address(circle.morphoWethVault()));
        console2.log("WETH address:", address(circle.weth()));
        console2.log("wstETH address:", address(circle.wsteth()));
        console2.log("Members count:", circle.getMemberCount());
        
        vm.stopBroadcast();
        
        console2.log("\nDeployment complete! Update frontend with new circle address.");
        console2.log("Circle has full Morpho integration with WETH standardization.");
    }
}
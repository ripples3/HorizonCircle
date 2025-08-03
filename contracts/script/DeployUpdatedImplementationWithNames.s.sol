// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/HorizonCircleWithMorphoAuth.sol";

contract DeployUpdatedImplementationWithNames is Script {
    function run() external {
        console.log("Deploying updated HorizonCircleWithMorphoAuth with name functionality...");
        
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = bytes(pkString)[0] == "0" ? 
            vm.parseUint(pkString) : vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy updated implementation with name functionality
        HorizonCircleWithMorphoAuth implementation = new HorizonCircleWithMorphoAuth();
        
        console.log("Updated Implementation deployed at:", address(implementation));
        console.log("Size:", address(implementation).code.length, "bytes");
        
        // Log the changes made
        console.log("\nFIXES INCLUDED:");
        console.log("- Added string public name; storage variable");
        console.log("- Fixed initialize() function to store _name parameter");
        console.log("- Circles created with this implementation will have proper names");
        console.log("\nFRONTEND ACTION NEEDED:");
        console.log("- Update IMPLEMENTATION address in frontend config to use this new implementation");
        console.log("- New circles created after this update will show proper names instead of 'Unnamed Circle'");
        
        vm.stopBroadcast();
    }
}
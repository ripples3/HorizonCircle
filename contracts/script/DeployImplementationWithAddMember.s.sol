// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/HorizonCircleWithMorphoAuth.sol";

contract DeployImplementationWithAddMember is Script {
    function run() external {
        console.log("Deploying HorizonCircleWithMorphoAuth with addMember function...");
        
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = bytes(pkString)[0] == "0" ? 
            vm.parseUint(pkString) : vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy updated implementation with addMember functionality
        HorizonCircleWithMorphoAuth implementation = new HorizonCircleWithMorphoAuth();
        
        console.log("Implementation with addMember deployed at:", address(implementation));
        console.log("Size:", address(implementation).code.length, "bytes");
        
        console.log("\nFIXES INCLUDED:");
        console.log("- Added addMember(address newMember) function");
        console.log("- Members can now add new friends to existing circles");
        console.log("- Only existing members can add new members (onlyMember modifier)");
        console.log("- Proper validation: no zero address, no duplicate members");
        console.log("- Emits MemberAdded event for frontend integration");
        
        console.log("\nNEXT STEPS:");
        console.log("1. Deploy new factory with this implementation");
        console.log("2. Update frontend IMPLEMENTATION address");
        console.log("3. Test adding members to new circles");
        
        vm.stopBroadcast();
    }
}
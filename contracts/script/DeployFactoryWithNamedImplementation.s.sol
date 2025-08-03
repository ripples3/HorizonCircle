// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/HorizonCircleMinimalProxyWithModules.sol";

contract DeployFactoryWithNamedImplementation is Script {
    function run() external {
        console.log("Deploying factory with updated implementation that has name functionality...");
        
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = bytes(pkString)[0] == "0" ? 
            vm.parseUint(pkString) : vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Use existing verified components
        address registry = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
        address implementation = 0xd942E96c9ee7252798b8B03Eb56849bF1A384f39; // NEW implementation with names
        address swapModule = 0x1E394C5740f3b04b4a930EC843a43d1d49Ddbd2A;
        address lendingModule = 0x96F582fAF5a1D61640f437EBea9758b18a678720;
        
        console.log("Using components:");
        console.log("Registry:", registry);
        console.log("Implementation:", implementation);
        console.log("Swap Module:", swapModule);
        console.log("Lending Module:", lendingModule);
        
        // Deploy new factory with updated implementation
        HorizonCircleMinimalProxyWithModules factory = new HorizonCircleMinimalProxyWithModules(
            registry,
            implementation,
            swapModule,
            lendingModule
        );
        
        console.log("\nNEW FACTORY deployed at:", address(factory));
        console.log("Size:", address(factory).code.length, "bytes");
        
        console.log("\nFIXES INCLUDED:");
        console.log("- Uses updated implementation with name functionality");
        console.log("- New circles will show proper names instead of 'Unnamed Circle'");
        console.log("- All other functionality remains the same");
        
        console.log("\nFRONTEND UPDATE NEEDED:");
        console.log("Update CONTRACT_ADDRESSES.FACTORY to:", address(factory));
        console.log("Update MIN_BLOCK_NUMBER to current block for filtering");
        
        vm.stopBroadcast();
    }
}
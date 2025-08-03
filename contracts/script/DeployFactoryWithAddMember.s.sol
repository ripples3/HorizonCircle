// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/HorizonCircleMinimalProxyWithModules.sol";

contract DeployFactoryWithAddMember is Script {
    function run() external {
        console.log("Deploying factory with addMember implementation...");
        
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = bytes(pkString)[0] == "0" ? 
            vm.parseUint(pkString) : vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Use the newly deployed implementation with addMember function
        address implementation = 0x8F131C8A090CED5af97Ba94C8698479eDe136eA8;
        address registry = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
        address lendingModule = 0x96F582fAF5a1D61640f437EBea9758b18a678720;
        address swapModule = 0x1E394C5740f3b04b4a930EC843a43d1d49Ddbd2A;
        
        // Deploy new factory with addMember implementation
        HorizonCircleMinimalProxyWithModules factory = new HorizonCircleMinimalProxyWithModules(
            registry,
            implementation,
            swapModule,
            lendingModule
        );
        
        console.log("Factory with addMember deployed at:", address(factory));
        console.log("Implementation address:", implementation);
        console.log("Registry address:", registry);
        console.log("Lending module:", lendingModule);
        console.log("Swap module:", swapModule);
        
        console.log("\nFEATURES INCLUDED:");
        console.log("- Complete loan execution with WETH->wstETH->Morpho lending");
        console.log("- Users can add friends to circles via addMember function");
        console.log("- Morpho vault integration for yield earning");
        console.log("- Registry integration for circle discovery");
        console.log("- Verified modular architecture");
        
        console.log("\nFRONTEND UPDATE REQUIRED:");
        console.log("Update FACTORY address in frontend/src/config/web3.ts");
        console.log("New FACTORY:", address(factory));
        
        vm.stopBroadcast();
    }
}
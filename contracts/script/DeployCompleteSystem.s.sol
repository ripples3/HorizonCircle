// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleCore.sol";
import "../src/HorizonCircleModularFactory.sol";
import "../src/SwapModule.sol";
import "../src/LendingModule.sol";

contract DeployCompleteSystem is Script {
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING COMPLETE MODULAR SYSTEM ===");
        console.log("Owner:", msg.sender);
        
        // Step 1: Deploy core components
        console.log("\n=== STEP 1: DEPLOY CORE COMPONENTS ===");
        
        // Deploy Core Implementation
        HorizonCircleCore coreImplementation = new HorizonCircleCore();
        console.log("Core Implementation:", address(coreImplementation));
        
        // Deploy Registry
        CircleRegistry registry = new CircleRegistry();
        console.log("Registry:", address(registry));
        
        // Deploy SwapModule
        SwapModule swapModule = new SwapModule();
        console.log("SwapModule:", address(swapModule));
        
        // Deploy LendingModule
        LendingModule lendingModule = new LendingModule();
        console.log("LendingModule:", address(lendingModule));
        
        // Deploy Factory
        HorizonCircleModularFactory factory = new HorizonCircleModularFactory(
            address(registry),
            address(coreImplementation)
        );
        console.log("Factory:", address(factory));
        
        // Step 2: Create a test circle
        console.log("\n=== STEP 2: CREATE TEST CIRCLE ===");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        address circleAddr = factory.createCircle("ProductionTestCircle", members);
        console.log("Circle created:", circleAddr);
        
        // Step 3: Authorize the circle in modules
        console.log("\n=== STEP 3: AUTHORIZE CIRCLE ===");
        swapModule.authorizeCircle(circleAddr);
        console.log("Circle authorized in SwapModule");
        
        lendingModule.authorizeCircle(circleAddr);
        console.log("Circle authorized in LendingModule");
        
        console.log("\n=== COMPLETE SYSTEM DEPLOYED & READY ===");
        console.log("Factory:", address(factory));
        console.log("Registry:", address(registry));
        console.log("Core Implementation:", address(coreImplementation));
        console.log("SwapModule:", address(swapModule));
        console.log("LendingModule:", address(lendingModule));
        console.log("Test Circle:", circleAddr);
        console.log("Ready for complete DeFi testing!");
        
        vm.stopBroadcast();
    }
}
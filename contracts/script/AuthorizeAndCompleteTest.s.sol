// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface ISwapModule {
    function authorizeCircle(address circle) external;
}

interface ICircle {
    function executeRequest(bytes32 requestId) external;
}

contract AuthorizeAndCompleteTest is Script {
    address constant SWAP_MODULE = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92;
    address constant CIRCLE = 0xA6ae82C17bfEDdAa1810Ea3c053CD21866EF5DB8;
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    // Request ID from previous test: 13077123896647132253486257075971564269095512336304397975671746123521265101674
    bytes32 constant REQUEST_ID = 0x1ce963cbe84ea4fd25c82ac48a8e50da3e89aaf857af188ff54f009c830deb6a;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== AUTHORIZING AND COMPLETING TEST ===");
        console.log("Swap Module:", SWAP_MODULE);
        console.log("Circle:", CIRCLE);
        console.log("Test User:", TEST_USER);
        
        // Step 1: Authorize circle in swap module
        console.log("=== STEP 1: AUTHORIZE CIRCLE ===");
        ISwapModule swapModule = ISwapModule(SWAP_MODULE);
        swapModule.authorizeCircle(CIRCLE);
        console.log("SUCCESS: Circle authorized in swap module");
        
        // Step 2: Execute the loan request
        console.log("=== STEP 2: EXECUTE LOAN ===");
        console.log("This will now complete the full DeFi flow:");
        console.log("1. Withdraw WETH from Morpho vault (DONE)");
        console.log("2. Swap WETH -> wstETH via Velodrome (NOW AUTHORIZED)");
        console.log("3. Supply wstETH as collateral to Morpho lending");
        console.log("4. Borrow WETH against wstETH collateral");
        console.log("5. Send ETH to user");
        
        uint256 ethBefore = TEST_USER.balance;
        console.log("User ETH before execution:", ethBefore);
        
        ICircle circle = ICircle(CIRCLE);
        circle.executeRequest(REQUEST_ID);
        
        uint256 ethAfter = TEST_USER.balance;
        console.log("User ETH after execution:", ethAfter);
        console.log("ETH received by user:", ethAfter - ethBefore);
        
        if (ethAfter > ethBefore) {
            console.log("SUCCESS: COMPLETE FLOW WORKING!");
            console.log("User received borrowed ETH successfully");
            console.log("All verified contracts working together:");
            console.log("- Factory: Circle creation");
            console.log("- Implementation: Deposits & loans");
            console.log("- Lending Module: Morpho integration");
            console.log("- Swap Module: Velodrome swaps");
            console.log("- Complete DeFi flow: SUCCESS!");
        } else {
            console.log("ISSUE: User did not receive ETH");
        }
        
        vm.stopBroadcast();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface ISwapModuleFixed {
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256 wstETHReceived);
    function authorizeCircle(address circle) external;
}

interface IWETH {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract VerifySwapModule is Script {
    // Working factory's configured swap module
    address constant SWAP_MODULE = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== VERIFYING FACTORY'S SWAP MODULE ===");
        console.log("Swap Module:", SWAP_MODULE);
        console.log("Testing with user's existing WETH");
        
        // Check user's balances
        uint256 wethBalance = IWETH(WETH).balanceOf(TEST_USER);
        uint256 wstETHBefore = IERC20(wstETH).balanceOf(TEST_USER);
        console.log("User WETH balance:", wethBalance);
        console.log("User wstETH before:", wstETHBefore);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Authorize user for testing
        console.log("\n=== STEP 1: AUTHORIZE USER ===");
        ISwapModuleFixed(SWAP_MODULE).authorizeCircle(TEST_USER);
        console.log("SUCCESS: User authorized for swap module");
        
        vm.stopBroadcast();
        
        // Step 2: Test swap with user's WETH
        console.log("\n=== STEP 2: TEST SWAP EXECUTION ===");
        uint256 testAmount = 0.00003 ether; // 30 microETH
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Approving", testAmount, "WETH for swap...");
        IWETH(WETH).approve(SWAP_MODULE, testAmount);
        
        console.log("Executing WETH->wstETH swap...");
        
        try ISwapModuleFixed(SWAP_MODULE).swapWETHToWstETH(testAmount) returns (uint256 wstETHReceived) {
            uint256 wstETHAfter = IERC20(wstETH).balanceOf(TEST_USER);
            
            console.log("\n=== SUCCESS: FACTORY'S SWAP MODULE WORKING! ===");
            console.log("wstETH before:", wstETHBefore);
            console.log("wstETH after:", wstETHAfter);
            console.log("wstETH received:", wstETHReceived);
            console.log("SUCCESS: Swap module", SWAP_MODULE, "is functional!");
            console.log("SUCCESS: Working factory has working swap integration!");
            
        } catch Error(string memory reason) {
            console.log("SWAP FAILED:", reason);
            console.log("Factory's swap module needs investigation");
        } catch (bytes memory lowLevelData) {
            console.log("SWAP FAILED: Low-level error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== VERIFICATION COMPLETE ===");
        console.log("Factory swap module:", SWAP_MODULE);
        console.log("Ready for circle creation testing");
    }
}
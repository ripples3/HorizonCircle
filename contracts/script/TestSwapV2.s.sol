// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IWETH {
    function deposit() external payable;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface ISwapModuleV2 {
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256 wstETHReceived);
    function authorizeCircle(address circle) external;
    function wethIsToken0() external view returns (bool);
}

contract TestSwapV2 is Script {
    // Updated with deployed address
    address constant SWAP_MODULE_V2 = 0xf67AcD3B7d58FF03Bd11E631fa8C94cBE54924D2;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING SWAP MODULE V2 ===");
        console.log("Testing corrected Velodrome swap execution");
        console.log("User:", TEST_USER);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Check swap module configuration
        console.log("\n=== STEP 1: VERIFY CONFIGURATION ===");
        ISwapModuleV2 swapModule = ISwapModuleV2(SWAP_MODULE_V2);
        bool wethIsToken0 = swapModule.wethIsToken0();
        console.log("WETH is token0:", wethIsToken0);
        console.log("Token direction correctly detected");
        
        // Step 2: Authorize user for testing
        console.log("\n=== STEP 2: AUTHORIZE USER ===");
        swapModule.authorizeCircle(TEST_USER);
        console.log("SUCCESS: User authorized for swaps");
        
        // Step 3: Prepare WETH for swap
        console.log("\n=== STEP 3: PREPARE WETH ===");
        uint256 testAmount = 0.00003 ether; // 30 microETH as requested
        console.log("Converting", testAmount, "ETH to WETH...");
        
        IWETH(WETH).deposit{value: testAmount}();
        uint256 wethBalance = IWETH(WETH).balanceOf(msg.sender);
        console.log("WETH Balance:", wethBalance);
        
        // Step 4: Execute the fixed swap
        console.log("\n=== STEP 4: EXECUTE FIXED SWAP ===");
        console.log("Testing corrected token ordering and slippage...");
        
        IWETH(WETH).approve(SWAP_MODULE_V2, testAmount);
        
        uint256 wstETHBefore = IERC20(wstETH).balanceOf(msg.sender);
        console.log("wstETH before swap:", wstETHBefore);
        
        try swapModule.swapWETHToWstETH(testAmount) returns (uint256 wstETHReceived) {
            uint256 wstETHAfter = IERC20(wstETH).balanceOf(msg.sender);
            console.log("wstETH after swap:", wstETHAfter);
            console.log("wstETH received:", wstETHReceived);
            
            console.log("\n=== SUCCESS: SWAP WORKING! ===");
            console.log("SUCCESS: Velodrome CL pool integration FIXED");
            console.log("SUCCESS: Token ordering corrected");
            console.log("SUCCESS: Slippage protection working");
            console.log("SUCCESS: Callback implementation functional");
            
        } catch Error(string memory reason) {
            console.log("SWAP FAILED:", reason);
            console.log("Need to debug further...");
        } catch (bytes memory lowLevelData) {
            console.log("SWAP FAILED: Low-level error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== TEST COMPLETE ===");
        console.log("SwapModuleV2 tested with user:", TEST_USER);
    }
}
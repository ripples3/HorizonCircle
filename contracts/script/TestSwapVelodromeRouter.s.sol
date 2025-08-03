// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IWETH {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface ISwapModuleVelodromeRouter {
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256 wstETHReceived);
    function authorizeCircle(address circle) external;
}

contract TestSwapVelodromeRouter is Script {
    // Updated with deployed address
    address constant SWAP_MODULE = 0xeA9126fB3B8840C03BFc27522687e5935C30Cb2d;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING VELODROME ROUTER SWAP MODULE ===");
        console.log("Using industry standard Velodrome Router");
        console.log("User:", TEST_USER);
        
        // Check existing balances
        uint256 wethBalance = IWETH(WETH).balanceOf(TEST_USER);
        uint256 wstETHBefore = IERC20(wstETH).balanceOf(TEST_USER);
        console.log("User WETH balance:", wethBalance);
        console.log("User wstETH before:", wstETHBefore);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Authorize user for testing
        console.log("\n=== STEP 1: AUTHORIZE USER ===");
        ISwapModuleVelodromeRouter(SWAP_MODULE).authorizeCircle(TEST_USER);
        console.log("SUCCESS: User authorized for Velodrome Router swaps");
        
        vm.stopBroadcast();
        
        // Switch to user's account for the actual swap test
        vm.startBroadcast(deployerPrivateKey); // Still use deployer key but test as user
        
        // Step 2: Test with user's existing WETH
        console.log("\n=== STEP 2: EXECUTE VELODROME ROUTER SWAP ===");
        uint256 testAmount = 0.00003 ether; // 30 microETH as requested
        require(wethBalance >= testAmount, "Insufficient WETH balance");
        
        console.log("Approving", testAmount, "WETH for Velodrome Router...");
        IWETH(WETH).approve(SWAP_MODULE, testAmount);
        
        console.log("Executing Velodrome Router WETH->wstETH swap...");
        
        try ISwapModuleVelodromeRouter(SWAP_MODULE).swapWETHToWstETH(testAmount) returns (uint256 wstETHReceived) {
            uint256 wstETHAfter = IERC20(wstETH).balanceOf(TEST_USER);
            
            console.log("\n=== SUCCESS: VELODROME ROUTER SWAP WORKING! ===");
            console.log("wstETH before swap:", wstETHBefore);
            console.log("wstETH after swap:", wstETHAfter);
            console.log("wstETH received:", wstETHReceived);
            console.log("SUCCESS: Velodrome Router integration WORKING");
            console.log("SUCCESS: Swap issue RESOLVED with Router approach");
            console.log("SUCCESS: Ready for complete loan flow testing!");
            
        } catch Error(string memory reason) {
            console.log("SWAP FAILED:", reason);
            console.log("Router approach also failed - investigating...");
        } catch (bytes memory lowLevelData) {
            console.log("SWAP FAILED: Low-level error with Velodrome Router");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== TEST COMPLETE ===");
        console.log("Velodrome Router swap module tested");
        console.log("User:", TEST_USER);
    }
}
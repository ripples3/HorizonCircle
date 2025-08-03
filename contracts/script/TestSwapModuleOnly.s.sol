// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IWETH {
    function deposit() external payable;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface ISwapModuleFixed {
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256 wstETHReceived);
    function authorizeCircle(address circle) external;
}

contract TestSwapModuleOnly is Script {
    address constant SWAP_MODULE = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TEST SWAP MODULE WITH YOUR CONTRACTS ===");
        console.log("Swap Module:", SWAP_MODULE);
        console.log("Testing WETH -> wstETH swap functionality");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Test with 0.00003 ETH as requested
        uint256 testAmount = 0.00003 ether;
        console.log("Test amount:", testAmount);
        
        // Convert ETH to WETH
        console.log("Converting ETH to WETH...");
        IWETH(WETH).deposit{value: testAmount}();
        
        uint256 wethBalance = IWETH(WETH).balanceOf(msg.sender);
        console.log("WETH Balance:", wethBalance);
        
        // Approve swap module
        console.log("Approving swap module...");
        IWETH(WETH).approve(SWAP_MODULE, testAmount);
        
        // Get wstETH balance before swap
        uint256 wstETHBefore = IERC20(wstETH).balanceOf(msg.sender);
        console.log("wstETH before swap:", wstETHBefore);
        
        // Execute swap
        console.log("Executing WETH -> wstETH swap...");
        ISwapModuleFixed swapModule = ISwapModuleFixed(SWAP_MODULE);
        uint256 wstETHReceived = swapModule.swapWETHToWstETH(testAmount);
        
        uint256 wstETHAfter = IERC20(wstETH).balanceOf(msg.sender);
        console.log("wstETH after swap:", wstETHAfter);
        console.log("wstETH received from swap:", wstETHReceived);
        
        vm.stopBroadcast();
        
        console.log("\\n=== RESULTS ===");
        if (wstETHReceived > 0) {
            console.log("SUCCESS: Swap module working!");
            console.log("Your verified contracts can now use WETH->wstETH swaps");
        } else {
            console.log("FAILED: Swap did not work");
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface ISwapModuleFixed {
    function authorizeCircle(address circle) external;
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256 wstETHReceived);
}

interface IWETH {
    function deposit() external payable;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract TestSwapWithExistingCircle is Script {
    address constant SWAP_MODULE = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TEST SWAP MODULE DIRECTLY ===");
        console.log("Swap Module:", SWAP_MODULE);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Test direct swap functionality
        uint256 testAmount = 0.00001 ether; // 10 microETH
        
        console.log("Converting ETH to WETH...");
        IWETH(WETH).deposit{value: testAmount}();
        
        uint256 wethBalance = IWETH(WETH).balanceOf(address(this));
        console.log("WETH Balance:", wethBalance);
        
        console.log("Approving swap module...");
        IWETH(WETH).approve(SWAP_MODULE, testAmount);
        
        console.log("Testing swap...");
        uint256 wstETHBefore = IERC20(wstETH).balanceOf(address(this));
        
        ISwapModuleFixed swapModule = ISwapModuleFixed(SWAP_MODULE);
        uint256 wstETHReceived = swapModule.swapWETHToWstETH(testAmount);
        
        uint256 wstETHAfter = IERC20(wstETH).balanceOf(address(this));
        
        console.log("wstETH received:", wstETHReceived);
        console.log("wstETH balance before:", wstETHBefore);
        console.log("wstETH balance after:", wstETHAfter);
        
        vm.stopBroadcast();
        
        if (wstETHReceived > 0) {
            console.log("SUCCESS: Swap module working!");
        } else {
            console.log("FAILED: Swap did not work");
        }
    }
}
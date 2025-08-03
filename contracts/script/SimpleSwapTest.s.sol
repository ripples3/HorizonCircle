// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
}

// Minimal interface for CL pool
interface IPool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

contract SimpleSwapTest is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant CL_POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    
    uint160 constant MIN_SQRT_RATIO = 4295128739;
    uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== SIMPLE SWAP TEST ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Get some WETH
        uint256 amount = 0.00001 ether;
        IWETH(WETH).deposit{value: amount}();
        IERC20(WETH).approve(CL_POOL, amount);
        
        console.log("Initial WETH balance:", IERC20(WETH).balanceOf(address(this)));
        console.log("Initial wstETH balance:", IERC20(wstETH).balanceOf(address(this)));
        
        // Try swap with extreme limits
        console.log("\nTrying swap...");
        
        try IPool(CL_POOL).swap(
            address(this),
            true, // WETH -> wstETH
            int256(amount),
            MIN_SQRT_RATIO + 1, // Use minimum price for maximum slippage tolerance
            ""
        ) returns (int256 amount0, int256 amount1) {
            console.log("Swap successful!");
            console.log("WETH used:", amount0);
            console.log("wstETH received:", amount1);
        } catch {
            console.log("Swap failed - trying with callback");
        }
        
        vm.stopBroadcast();
        
        console.log("\nFinal balances:");
        console.log("WETH:", IERC20(WETH).balanceOf(address(this)));
        console.log("wstETH:", IERC20(wstETH).balanceOf(address(this)));
    }
    
    // Velodrome uses this callback name
    function hook(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        if (amount0Delta > 0) {
            IERC20(WETH).transfer(msg.sender, uint256(amount0Delta));
        }
    }
}
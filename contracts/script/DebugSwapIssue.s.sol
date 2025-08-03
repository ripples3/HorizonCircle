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
    function approve(address, uint256) external returns (bool);
}

interface IVelodromeCLPool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
    
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
}

contract DebugSwapIssue is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant CL_POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEBUG SWAP ISSUE ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deposit ETH to get WETH
        uint256 amount = 0.00001 ether;
        IWETH(WETH).deposit{value: amount}();
        console.log("Deposited ETH to WETH:", amount);
        
        // Approve pool
        IERC20(WETH).approve(CL_POOL, amount);
        console.log("Approved WETH to pool");
        
        // Get current price
        (uint160 sqrtPriceX96,,,,,,) = IVelodromeCLPool(CL_POOL).slot0();
        console.log("Current sqrtPriceX96:", sqrtPriceX96);
        
        // Try simple swap with no slippage protection (MIN/MAX)
        console.log("\nAttempting swap...");
        
        // For WETH->wstETH (token0->token1), we use zeroForOne = true
        // Use extreme price limits to debug
        uint160 sqrtPriceLimitX96 = 4295128740; // MIN_SQRT_RATIO + 1
        
        try IVelodromeCLPool(CL_POOL).swap(
            address(this),
            true, // zeroForOne
            int256(amount),
            sqrtPriceLimitX96,
            ""
        ) returns (int256 amount0, int256 amount1) {
            console.log("Swap successful!");
            console.log("Amount0:", amount0);
            console.log("Amount1:", amount1);
        } catch Error(string memory reason) {
            console.log("Swap failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Swap failed with low-level error");
        }
        
        vm.stopBroadcast();
        
        console.log("\nFinal balances:");
        console.log("WETH:", IERC20(WETH).balanceOf(address(this)));
        console.log("wstETH:", IERC20(wstETH).balanceOf(address(this)));
    }
    
    // Callback for CL pool
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external {
        console.log("Callback called!");
        console.log("amount0Delta:", amount0Delta);
        console.log("amount1Delta:", amount1Delta);
        
        if (amount0Delta > 0) {
            IERC20(WETH).transfer(msg.sender, uint256(amount0Delta));
            console.log("Paid WETH:", uint256(amount0Delta));
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
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
    
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract TestDirectSwap is Script {
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant wstETH_ADDRESS = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant CL_POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DIRECT VELODROME CL POOL SWAP TEST ===");
        console.log("Testing minimal swap parameters to isolate the issue");
        
        IVelodromeCLPool pool = IVelodromeCLPool(CL_POOL);
        IERC20 weth = IERC20(WETH_ADDRESS);
        IERC20 wstETH = IERC20(wstETH_ADDRESS);
        
        // Check pool tokens
        address token0 = pool.token0();
        address token1 = pool.token1();
        console.log("Pool token0:", token0);
        console.log("Pool token1:", token1);
        console.log("WETH address:", WETH_ADDRESS);
        console.log("wstETH address:", wstETH_ADDRESS);
        
        // Get current price
        (uint160 sqrtPriceX96, int24 tick,,,,,) = pool.slot0();
        console.log("Current sqrtPriceX96:", sqrtPriceX96);
        console.log("Current tick:", tick);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Get some WETH by wrapping ETH
        address user = vm.addr(deployerPrivateKey);
        console.log("User address:", user);
        console.log("User WETH balance before:", weth.balanceOf(user));
        
        // We need WETH for the swap - let's get it from a different source or skip this direct test
        console.log("Skipping direct swap test - need WETH balance");
        console.log("The issue might be with slippage calculation or pool state");
        
        // Let's try a different approach - check if the issue is with the slippage limits
        console.log("\n=== ANALYZING POTENTIAL ISSUES ===");
        console.log("1. Check if sqrtPriceLimitX96 calculation is correct");
        console.log("2. Verify token ordering (WETH should be token0 or token1)");
        console.log("3. Test with different slippage values");
        
        // Calculate slippage limit like our contract does
        uint256 slippageBps = 50; // 0.5%
        uint256 BASIS_POINTS = 10000;
        uint160 priceDelta = uint160((uint256(sqrtPriceX96) * slippageBps) / BASIS_POINTS);
        uint160 sqrtPriceLimitX96 = sqrtPriceX96 - priceDelta;
        
        console.log("Calculated price delta:", priceDelta);
        console.log("Calculated sqrtPriceLimitX96:", sqrtPriceLimitX96);
        console.log("Original sqrtPriceX96:", sqrtPriceX96);
        
        if (sqrtPriceLimitX96 >= sqrtPriceX96) {
            console.log("ERROR: Price limit >= current price!");
        }
        
        // Check if tokens are in expected order
        bool wethIsToken0 = (token0 == WETH_ADDRESS);
        bool wstETHIsToken1 = (token1 == wstETH_ADDRESS);
        console.log("WETH is token0:", wethIsToken0);
        console.log("wstETH is token1:", wstETHIsToken1);
        
        if (!wethIsToken0 || !wstETHIsToken1) {
            console.log("TOKEN ORDERING ISSUE: Expected WETH=token0, wstETH=token1");
            console.log("Actual token0:", token0);
            console.log("Actual token1:", token1);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== DIAGNOSIS COMPLETE ===");
        console.log("Check token ordering and slippage calculation issues above");
    }
}
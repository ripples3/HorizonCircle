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
    function transfer(address to, uint256 amount) external returns (bool);
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

/**
 * @title TestVelodromeSwapDirect
 * @notice Direct test to identify exact swap failure point
 */
contract TestVelodromeSwapDirect is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DIRECT VELODROME SWAP TEST ===");
        console.log("Identifying exact failure point");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Prepare WETH
        uint256 testAmount = 0.00003 ether;
        IWETH(WETH).deposit{value: testAmount}();
        console.log("WETH prepared:", IWETH(WETH).balanceOf(msg.sender));
        
        // Step 2: Check pool configuration
        IVelodromeCLPool pool = IVelodromeCLPool(POOL);
        address token0 = pool.token0();
        address token1 = pool.token1();
        console.log("Pool token0:", token0);
        console.log("Pool token1:", token1);
        
        bool wethIsToken0 = token0 == WETH;
        console.log("WETH is token0:", wethIsToken0);
        
        // Step 3: Get pool state
        (uint160 sqrtPriceX96, int24 tick,,,,,) = pool.slot0();
        console.log("Pool sqrtPriceX96:", sqrtPriceX96);
        console.log("Pool tick:", vm.toString(tick));
        
        // Step 4: Test different price limits
        console.log("\n=== TESTING PRICE LIMITS ===");
        
        // Test 1: Minimal slippage (0.01%)
        uint160 minimalSlippage = uint160((uint256(sqrtPriceX96) * 1) / 10000);
        uint160 limit1 = wethIsToken0 ? sqrtPriceX96 - minimalSlippage : sqrtPriceX96 + minimalSlippage;
        console.log("Minimal slippage limit:", limit1);
        
        // Test 2: Safe range limits
        uint160 limit2 = wethIsToken0 ? sqrtPriceX96 - (sqrtPriceX96 / 200) : sqrtPriceX96 + (sqrtPriceX96 / 200); // 0.5%
        console.log("Safe range limit:", limit2);
        
        // Test 3: No slippage protection (max range)
        uint160 limit3 = wethIsToken0 ? 0 : type(uint160).max;
        console.log("No slippage limit:", limit3);
        
        // Step 5: Test actual swap with debugging
        console.log("\n=== TESTING SWAP EXECUTION ===");
        
        try this.executeTestSwap(testAmount, limit2) {
            console.log("SUCCESS: Swap executed with safe limits");
        } catch Error(string memory reason) {
            console.log("SWAP FAILED with reason:", reason);
            
            // Try with no slippage protection
            try this.executeTestSwap(testAmount, limit3) {
                console.log("SUCCESS: Swap executed with no slippage protection");
            } catch Error(string memory reason2) {
                console.log("SWAP FAILED even without slippage:", reason2);
            }
        }
        
        vm.stopBroadcast();
    }
    
    function executeTestSwap(uint256 amount, uint160 sqrtPriceLimitX96) external {
        IVelodromeCLPool pool = IVelodromeCLPool(POOL);
        bool wethIsToken0 = pool.token0() == WETH;
        
        // Transfer WETH to this contract for swap
        IWETH(WETH).transfer(address(this), amount);
        
        console.log("Executing swap with:");
        console.log("- Amount:", amount);
        console.log("- zeroForOne:", wethIsToken0);
        console.log("- sqrtPriceLimitX96:", sqrtPriceLimitX96);
        
        pool.swap(
            address(this),
            wethIsToken0,
            int256(amount),
            sqrtPriceLimitX96,
            ""
        );
        
        console.log("Swap completed successfully");
    }
    
    // Callback for Velodrome pool
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external {
        console.log("Callback triggered:");
        console.log("- amount0Delta:", vm.toString(amount0Delta));
        console.log("- amount1Delta:", vm.toString(amount1Delta));
        
        if (amount0Delta > 0) {
            IWETH(WETH).transfer(POOL, uint256(amount0Delta));
            console.log("Paid WETH to pool:", uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            IWETH(WETH).transfer(POOL, uint256(amount1Delta));
            console.log("Paid WETH to pool (token1):", uint256(amount1Delta));
        }
    }
}
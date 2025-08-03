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

/**
 * @title TestMinimalSwap
 * @notice Minimal swap test with no slippage protection to isolate the issue
 */
contract TestMinimalSwap is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== MINIMAL SWAP TEST ===");
        console.log("Testing with NO slippage protection to isolate issue");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Get WETH (using deployer account)
        uint256 testAmount = 0.00003 ether;
        IWETH(WETH).deposit{value: testAmount}();
        
        uint256 wethBalance = IWETH(WETH).balanceOf(msg.sender);
        console.log("WETH Balance:", wethBalance);
        
        // Step 2: Check pool state
        IVelodromeCLPool pool = IVelodromeCLPool(POOL);
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        console.log("Pool sqrtPriceX96:", sqrtPriceX96);
        
        // Step 3: Try swap with minimal price protection (near max range)
        uint160 sqrtPriceLimitX96 = 4295128739; // Very low limit for zeroForOne
        console.log("Using minimal price limit:", sqrtPriceLimitX96);
        
        // Step 4: Execute minimal swap
        console.log("Transferring WETH to this contract...");
        IWETH(WETH).transfer(address(this), testAmount);
        
        uint256 wstETHBefore = IERC20(wstETH).balanceOf(msg.sender);
        console.log("wstETH before:", wstETHBefore);
        
        console.log("Executing swap with minimal protection...");
        try pool.swap(
            msg.sender,              // recipient
            true,                    // zeroForOne (WETH -> wstETH)
            int256(testAmount),      // exactInput
            sqrtPriceLimitX96,       // minimal protection
            ""                       // data
        ) returns (int256 amount0, int256 amount1) {
            console.log("SUCCESS: Swap completed!");
            console.log("amount0 (WETH paid):", vm.toString(amount0));
            console.log("amount1 (wstETH received):", vm.toString(amount1));
            
            uint256 wstETHAfter = IERC20(wstETH).balanceOf(msg.sender);
            console.log("wstETH after:", wstETHAfter);
            console.log("Net wstETH received:", wstETHAfter - wstETHBefore);
            
        } catch Error(string memory reason) {
            console.log("Swap failed with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Swap failed with low-level error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
    }
    
    // Callback for Velodrome CL pool
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external {
        console.log("Callback - amount0Delta:", vm.toString(amount0Delta));
        console.log("Callback - amount1Delta:", vm.toString(amount1Delta));
        
        // Pay WETH (token0) to pool
        if (amount0Delta > 0) {
            IWETH(WETH).transfer(POOL, uint256(amount0Delta));
            console.log("SUCCESS: Paid WETH to pool:", uint256(amount0Delta));
        }
    }
}
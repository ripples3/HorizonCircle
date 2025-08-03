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
 * @title TestSwapSimple
 * @notice Simple direct swap test without complex logic
 */
contract TestSwapSimple is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== SIMPLE SWAP TEST ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Get some WETH
        uint256 testAmount = 0.00003 ether;
        IWETH(WETH).deposit{value: testAmount}();
        
        uint256 wethBalance = IWETH(WETH).balanceOf(msg.sender);
        console.log("WETH Balance:", wethBalance);
        require(wethBalance >= testAmount, "WETH deposit failed");
        
        // Step 2: Get current pool price
        IVelodromeCLPool pool = IVelodromeCLPool(POOL);
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        console.log("Pool price:", sqrtPriceX96);
        
        // Step 3: Calculate simple price limit (use wide range for testing)
        uint160 sqrtPriceLimitX96 = sqrtPriceX96 / 2; // Allow 50% price movement
        console.log("Price limit:", sqrtPriceLimitX96);
        
        // Step 4: Transfer WETH to this contract for swap
        IWETH(WETH).transfer(address(this), testAmount);
        console.log("WETH transferred to contract");
        
        // Step 5: Execute swap
        uint256 wstETHBefore = IERC20(wstETH).balanceOf(msg.sender);
        console.log("wstETH before:", wstETHBefore);
        
        try pool.swap(
            msg.sender,              // recipient
            true,                    // zeroForOne (WETH -> wstETH)
            int256(testAmount),      // exactInput
            sqrtPriceLimitX96,       // wide price limit
            ""                       // data
        ) returns (int256 amount0, int256 amount1) {
            console.log("Swap successful!");
            console.log("amount0:", vm.toString(amount0));
            console.log("amount1:", vm.toString(amount1));
            
            uint256 wstETHAfter = IERC20(wstETH).balanceOf(msg.sender);
            console.log("wstETH after:", wstETHAfter);
            console.log("wstETH received:", wstETHAfter - wstETHBefore);
            
        } catch Error(string memory reason) {
            console.log("Swap failed:", reason);
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
            console.log("Paid WETH to pool:", uint256(amount0Delta));
        }
    }
}
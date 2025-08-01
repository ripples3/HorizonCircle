// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IWETH {
    function deposit() external payable;
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IVelodromeCLPool {
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
    
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

contract WrapAndTestPool is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        console.log("Callback called");
        console.log("Amount0Delta:", amount0Delta >= 0 ? uint256(amount0Delta) : uint256(-amount0Delta));
        console.log("Amount1Delta:", amount1Delta >= 0 ? uint256(amount1Delta) : uint256(-amount1Delta));
        
        // Pay what we owe
        if (amount0Delta > 0) {
            IWETH(WETH).approve(msg.sender, uint256(amount0Delta));
            // Transfer via approve/transferFrom pattern
        }
    }
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== WRAP ETH AND TEST POOL ===");
        
        // Wrap ETH to WETH
        uint256 wrapAmount = 0.001 ether;
        IWETH weth = IWETH(WETH);
        weth.deposit{value: wrapAmount}();
        
        uint256 balance = weth.balanceOf(address(this));
        console.log("WETH balance after wrapping:", balance);
        
        // Test pool swap
        IVelodromeCLPool pool = IVelodromeCLPool(POOL);
        
        uint256 swapAmount = 0.0001 ether;
        console.log("Attempting swap of:", swapAmount);
        
        // Get pool state
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        console.log("Pool price:", sqrtPriceX96);
        
        // Calculate price limit (0.5% slippage) 
        uint160 priceDelta = uint160((uint256(sqrtPriceX96) * 50) / 10000);
        uint160 sqrtPriceLimitX96 = sqrtPriceX96 - priceDelta;
        
        console.log("Price limit:", sqrtPriceLimitX96);
        
        // Try swap
        try pool.swap(
            address(this),
            true, // WETH -> wstETH
            int256(swapAmount),
            sqrtPriceLimitX96,
            ""
        ) returns (int256 amount0, int256 amount1) {
            console.log("SUCCESS!");
            console.log("Amount0:", amount0 >= 0 ? uint256(amount0) : uint256(-amount0));
            console.log("Amount1:", amount1 >= 0 ? uint256(amount1) : uint256(-amount1));
        } catch Error(string memory reason) {
            console.log("Swap failed:", reason);
        } catch (bytes memory data) {
            console.log("Swap failed with low-level error");
            console.logBytes(data);
        }
        
        vm.stopBroadcast();
    }
}
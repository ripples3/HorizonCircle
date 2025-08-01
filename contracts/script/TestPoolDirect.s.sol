// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TestPoolDirect is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== TESTING DIRECT POOL CALL ===");
        
        IVelodromeCLPool pool = IVelodromeCLPool(POOL);
        IERC20 weth = IERC20(WETH);
        
        // Check WETH balance
        uint256 balance = weth.balanceOf(msg.sender);
        console.log("WETH balance:", balance);
        
        if (balance == 0) {
            console.log("No WETH balance - skipping test");
            vm.stopBroadcast();
            return;
        }
        
        // Try small amount
        uint256 swapAmount = 0.0001 ether;
        console.log("Attempting swap of:", swapAmount);
        
        // Approve pool
        weth.approve(POOL, swapAmount);
        console.log("Approved pool");
        
        // Get pool state
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        console.log("Pool price:", sqrtPriceX96);
        
        // Calculate price limit (0.5% slippage)
        uint160 priceDelta = uint160((uint256(sqrtPriceX96) * 50) / 10000);
        uint160 sqrtPriceLimitX96 = sqrtPriceX96 - priceDelta;
        
        console.log("Price limit:", sqrtPriceLimitX96);
        
        // Try swap
        try pool.swap(
            msg.sender,
            true, // WETH -> wstETH
            int256(swapAmount),
            sqrtPriceLimitX96,
            ""
        ) returns (int256 amount0, int256 amount1) {
            console.log("SUCCESS!");
            console.log("Amount0:", uint256(amount0));
            console.log("Amount1:", uint256(-amount1));
        } catch Error(string memory reason) {
            console.log("Swap failed:", reason);
        } catch (bytes memory data) {
            console.log("Swap failed with low-level error");
            console.logBytes(data);
        }
        
        vm.stopBroadcast();
    }
}
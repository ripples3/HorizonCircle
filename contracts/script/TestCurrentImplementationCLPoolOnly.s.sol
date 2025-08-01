// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LiskConfig.sol";

interface IWETH {
    function deposit() external payable;
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC20Simple {
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IVelodromeCLPoolTest {
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol
    );
    
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

contract TestCurrentImplementationCLPoolOnly is Script, LiskConfig {
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== TESTING CL POOL SWAP WITH EXACT CURRENT IMPLEMENTATION LOGIC ===");
        
        IWETH wethToken = IWETH(WETH);
        IVelodromeCLPoolTest pool = IVelodromeCLPoolTest(WETH_wstETH_CL_POOL);
        
        // Get some WETH for testing
        uint256 initialBalance = wethToken.balanceOf(msg.sender);
        console.log("Initial WETH balance:", initialBalance);
        
        if (initialBalance < 0.0001 ether) {
            wethToken.deposit{value: 0.0001 ether}();
            console.log("Got WETH for testing");
        }
        
        uint256 wethBalance = wethToken.balanceOf(msg.sender);
        console.log("Current WETH balance:", wethBalance);
        
        // Deploy exact callback implementation
        ExactCallbackImplementation callback = new ExactCallbackImplementation();
        console.log("Deployed callback:", address(callback));
        
        // Transfer WETH to callback for testing
        uint256 testAmount = 0.00001 ether;
        wethToken.transfer(address(callback), testAmount);
        console.log("Transferred", testAmount, "WETH to callback");
        
        // Test the exact swap logic from current implementation
        try callback.testExactSwapLogic() {
            console.log("SUCCESS: CL pool swap logic works!");
            console.log("The issue is NOT in the swap logic itself");
            console.log("The issue must be in the context or gas limits");
        } catch Error(string memory reason) {
            console.log("FAILED:", reason);
            console.log("The swap logic itself has an issue");
        } catch (bytes memory lowLevelData) {
            console.log("FAILED with low-level error, length:", lowLevelData.length);
        }
        
        vm.stopBroadcast();
    }
}

contract ExactCallbackImplementation is LiskConfig {
    
    IWETH weth = IWETH(WETH);
    
    function testExactSwapLogic() external {
        console.log("=== TESTING EXACT SWAP LOGIC FROM CURRENT IMPLEMENTATION ===");
        
        uint256 wethAmount = weth.balanceOf(address(this));
        console.log("Testing with WETH amount:", wethAmount);
        require(wethAmount > 0, "No WETH to test");
        
        IVelodromeCLPoolTest pool = IVelodromeCLPoolTest(WETH_wstETH_CL_POOL);
        
        // Approve WETH to pool - EXACT current implementation logic
        weth.approve(WETH_wstETH_CL_POOL, wethAmount);
        console.log("Approved WETH to pool");
        
        // Get current pool state - EXACT current implementation logic
        (uint160 sqrtPriceX96, , , , , ) = pool.slot0();
        console.log("Got pool state, sqrtPriceX96:", sqrtPriceX96);
        
        // Calculate safe price limits - EXACT current implementation logic
        uint256 slippageBps = MAX_SLIPPAGE; // 50 = 0.5%
        uint160 priceDelta = uint160((uint256(sqrtPriceX96) * slippageBps) / BASIS_POINTS);
        
        // WETH is token0, wstETH is token1 - EXACT current implementation logic  
        bool zeroForOne = true; // WETH -> wstETH
        uint160 sqrtPriceLimitX96 = sqrtPriceX96 - priceDelta; // Allow price to move down when selling WETH
        
        console.log("Calculated price limit:", sqrtPriceLimitX96);
        
        // Direct CL pool swap - EXACT current implementation logic
        (int256 amount0, int256 amount1) = pool.swap(
            address(this),              // recipient
            zeroForOne,                 // zeroForOne (WETH -> wstETH)
            int256(wethAmount),         // amountSpecified (exact input)
            sqrtPriceLimitX96,          // sqrtPriceLimitX96 (MEV protection)
            ""                          // data (empty for simple swap)
        );
        
        console.log("Swap completed!");
        console.log("amount0 (WETH delta):", amount0);
        console.log("amount1 (wstETH delta):", amount1);
        
        // We sold token0 (WETH), received token1 (wstETH) - EXACT current implementation logic
        uint256 wstETHReceived = uint256(-amount1);
        console.log("wstETH received:", wstETHReceived);
        
        require(wstETHReceived > 0, "No wstETH received");
    }
    
    // EXACT callback from current implementation
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        console.log("=== CALLBACK CALLED ===");
        console.log("amount0Delta:", amount0Delta);
        console.log("amount1Delta:", amount1Delta);
        
        require(msg.sender == WETH_wstETH_CL_POOL, "!callback_pool");
        
        // Pay what we owe to the pool (positive delta = we owe tokens)
        if (amount0Delta > 0) {
            weth.transfer(msg.sender, uint256(amount0Delta));
            console.log("Paid", uint256(amount0Delta), "WETH to pool");
        }
        if (amount1Delta > 0) {
            // This shouldn't happen in our WETH->wstETH swap, but handle it
            IERC20Simple(wstETH).transfer(msg.sender, uint256(amount1Delta));
            console.log("Paid", uint256(amount1Delta), "wstETH to pool");
        }
        
        console.log("Callback completed");
    }
}
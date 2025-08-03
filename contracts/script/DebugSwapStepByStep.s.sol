// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IWETH {
    function deposit() external payable;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
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
    function fee() external view returns (uint24);
    function liquidity() external view returns (uint128);
}

/**
 * @title DebugSwapStepByStep
 * @notice Methodical debugging of each step to find the exact failure point
 */
contract DebugSwapStepByStep is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    
    bool public callbackTriggered = false;
    int256 public lastAmount0Delta;
    int256 public lastAmount1Delta;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== STEP BY STEP SWAP DEBUGGING ===");
        console.log("Finding the exact failure point in our logic");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Setup - get WETH
        uint256 testAmount = 0.00001 ether; // Smaller amount for testing
        IWETH(WETH).deposit{value: testAmount}();
        console.log("STEP 1 SUCCESS: Got WETH:", IWETH(WETH).balanceOf(msg.sender));
        
        // Step 2: Pool validation
        console.log("\n=== STEP 2: POOL VALIDATION ===");
        IVelodromeCLPool pool = IVelodromeCLPool(POOL);
        
        address token0 = pool.token0();
        address token1 = pool.token1();
        uint24 fee = pool.fee();
        uint128 liquidity = pool.liquidity();
        
        console.log("Token0 (should be WETH):", token0);
        console.log("Token1 (should be wstETH):", token1);
        console.log("Fee:", fee);
        console.log("Liquidity:", liquidity);
        
        require(token0 == WETH, "Token0 not WETH");
        require(token1 == wstETH, "Token1 not wstETH");
        require(liquidity > 0, "No liquidity");
        console.log("STEP 2 SUCCESS: Pool validation passed");
        
        // Step 3: Check current state
        console.log("\n=== STEP 3: POOL STATE ===");
        (uint160 sqrtPriceX96, int24 tick,,,,,) = pool.slot0();
        console.log("sqrtPriceX96:", sqrtPriceX96);
        console.log("Current tick:", vm.toString(tick));
        console.log("STEP 3 SUCCESS: Pool state accessible");
        
        // Step 4: Test minimal swap parameters
        console.log("\n=== STEP 4: TEST SWAP PARAMETERS ===");
        
        // Transfer WETH to this contract for callback
        IWETH(WETH).transfer(address(this), testAmount);
        console.log("WETH transferred to contract");
        
        // Most basic swap - no slippage protection
        bool zeroForOne = true; // WETH (token0) -> wstETH (token1)
        int256 amountSpecified = int256(testAmount); // Exact input
        uint160 sqrtPriceLimitX96 = 0; // No slippage protection for debugging
        
        console.log("zeroForOne:", zeroForOne);
        console.log("amountSpecified:", vm.toString(amountSpecified));
        console.log("sqrtPriceLimitX96:", sqrtPriceLimitX96);
        
        // Step 5: Execute the swap with detailed error catching
        console.log("\n=== STEP 5: EXECUTE SWAP ===");
        console.log("About to call pool.swap...");
        
        try pool.swap(
            address(this),      // recipient
            zeroForOne,         // direction
            amountSpecified,    // amount
            sqrtPriceLimitX96,  // price limit (none)
            ""                  // callback data
        ) returns (int256 amount0, int256 amount1) {
            console.log("SUCCESS: Swap completed!");
            console.log("amount0 (WETH paid):", vm.toString(amount0));
            console.log("amount1 (wstETH received):", vm.toString(amount1));
            console.log("Callback triggered:", callbackTriggered);
            
        } catch Error(string memory reason) {
            console.log("SWAP FAILED WITH REASON:", reason);
        } catch Panic(uint errorCode) {
            console.log("SWAP FAILED WITH PANIC CODE:", errorCode);
        } catch (bytes memory lowLevelData) {
            console.log("SWAP FAILED WITH LOW-LEVEL ERROR");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== DEBUGGING COMPLETE ===");
        console.log("Check each step for the exact failure point");
    }
    
    // Callback implementation
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        console.log("=== CALLBACK TRIGGERED ===");
        console.log("amount0Delta:", vm.toString(amount0Delta));
        console.log("amount1Delta:", vm.toString(amount1Delta));
        console.log("Callback data length:", data.length);
        
        callbackTriggered = true;
        lastAmount0Delta = amount0Delta;
        lastAmount1Delta = amount1Delta;
        
        // Validate callback sender
        require(msg.sender == POOL, "Invalid callback sender");
        console.log("Callback sender validated");
        
        // Pay WETH if required
        if (amount0Delta > 0) {
            console.log("Paying WETH to pool:", uint256(amount0Delta));
            
            uint256 contractBalance = IWETH(WETH).balanceOf(address(this));
            console.log("Contract WETH balance:", contractBalance);
            
            require(contractBalance >= uint256(amount0Delta), "Insufficient WETH");
            
            bool success = IWETH(WETH).transfer(POOL, uint256(amount0Delta));
            require(success, "WETH transfer failed");
            console.log("WETH payment successful");
        }
        
        console.log("=== CALLBACK COMPLETE ===");
    }
}
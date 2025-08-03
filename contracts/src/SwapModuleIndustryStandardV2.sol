// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IVelodromeCLPool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

/**
 * @title SwapModuleIndustryStandard
 * @notice EXACT Uniswap V3 industry standard implementation
 */
contract SwapModuleIndustryStandardV2 {
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant wstETH_ADDRESS = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant WETH_wstETH_CL_POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    
    IERC20 public immutable weth;
    IERC20 public immutable wstETH;
    IVelodromeCLPool public immutable pool;
    
    mapping(address => bool) public authorizedCallers;
    address public owner;
    
    event SwapExecuted(uint256 wethIn, uint256 wstETHOut);
    
    modifier onlyAuthorized() {
        require(authorizedCallers[msg.sender], "Unauthorized");
        _;
    }
    
    constructor() {
        weth = IERC20(WETH_ADDRESS);
        wstETH = IERC20(wstETH_ADDRESS);
        pool = IVelodromeCLPool(WETH_wstETH_CL_POOL);
        owner = msg.sender;
    }
    
    function authorizeCircle(address circle) external {
        require(msg.sender == owner, "Only owner");
        authorizedCallers[circle] = true;
    }
    
    function swapWETHToWstETH(uint256 wethAmount) external onlyAuthorized returns (uint256 wstETHReceived) {
        // Transfer WETH from caller
        require(weth.transferFrom(msg.sender, address(this), wethAmount), "Transfer failed");
        
        // Get wstETH balance before
        uint256 wstETHBefore = wstETH.balanceOf(address(this));
        
        // INDUSTRY STANDARD: Use MIN_SQRT_RATIO + 1 for zeroForOne = true
        // This allows maximum possible slippage while staying within valid bounds
        uint160 sqrtPriceLimitX96 = MIN_SQRT_RATIO + 1;
        
        // Execute swap with industry standard parameters
        pool.swap(
            address(this),                    // recipient
            true,                            // zeroForOne (WETH -> wstETH)
            int256(wethAmount),              // amountSpecified (positive = exact input)
            sqrtPriceLimitX96,               // INDUSTRY STANDARD price limit
            ""                               // data
        );
        
        // Calculate received amount
        uint256 wstETHAfter = wstETH.balanceOf(address(this));
        wstETHReceived = wstETHAfter - wstETHBefore;
        
        require(wstETHReceived > 0, "Swap failed");
        
        // Transfer wstETH to caller
        require(wstETH.transfer(msg.sender, wstETHReceived), "Transfer failed");
        
        emit SwapExecuted(wethAmount, wstETHReceived);
    }
    
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        require(msg.sender == WETH_wstETH_CL_POOL, "Unauthorized callback");
        
        // For WETH -> wstETH swap (zeroForOne = true):
        // amount0Delta > 0: We owe WETH to the pool (this is what we expect)
        // amount1Delta < 0: We receive wstETH from the pool (this is what we expect)
        
        if (amount0Delta > 0) {
            // Pay WETH to pool - EXACT Uniswap V3 pattern
            weth.transfer(WETH_wstETH_CL_POOL, uint256(amount0Delta));
        }
        
        // Note: If amount1Delta > 0, something is wrong with our swap direction
        require(amount1Delta <= 0, "Unexpected amount1Delta");
    }
}
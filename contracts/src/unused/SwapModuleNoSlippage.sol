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

interface IWETH {
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

/**
 * @title SwapModuleNoSlippage  
 * @notice Test version with no slippage protection to isolate the issue
 */
contract SwapModuleNoSlippage {
    // Constants
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant wstETH_ADDRESS = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant WETH_wstETH_CL_POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    
    IWETH public immutable weth;
    IERC20 public immutable wstETH;
    IVelodromeCLPool public immutable pool;
    
    // Access control
    mapping(address => bool) public authorizedCallers;
    address public owner;
    
    event SwapExecuted(uint256 wethIn, uint256 wstETHOut);
    
    modifier onlyAuthorized() {
        require(authorizedCallers[msg.sender], "Unauthorized");
        _;
    }
    
    constructor() {
        weth = IWETH(WETH_ADDRESS);
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
        require(IERC20(WETH_ADDRESS).transferFrom(msg.sender, address(this), wethAmount), "Transfer failed");
        
        // Get wstETH balance before swap
        uint256 wstETHBefore = wstETH.balanceOf(address(this));
        
        // Execute swap with NO slippage protection (use extreme limits)
        bool zeroForOne = true; // WETH -> wstETH
        uint160 sqrtPriceLimitX96 = 4295128740; // Very low limit to allow maximum slippage
        
        pool.swap(
            address(this),
            zeroForOne,
            int256(wethAmount),
            sqrtPriceLimitX96,
            ""
        );
        
        // Calculate wstETH received
        uint256 wstETHAfter = wstETH.balanceOf(address(this));
        wstETHReceived = wstETHAfter - wstETHBefore;
        require(wstETHReceived > 0, "Swap failed");
        
        // Transfer wstETH back to caller
        require(wstETH.transfer(msg.sender, wstETHReceived), "wstETH transfer failed");
        
        emit SwapExecuted(wethAmount, wstETHReceived);
    }
    
    // Velodrome CL pool callback
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256,
        bytes calldata
    ) external {
        require(msg.sender == WETH_wstETH_CL_POOL, "Invalid callback");
        
        if (amount0Delta > 0) {
            // Pay WETH to pool
            require(weth.transfer(WETH_wstETH_CL_POOL, uint256(amount0Delta)), "WETH payment failed");
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVelodromeRouter {
    struct Route {
        address from;
        address to;
        bool stable;
        address factory;
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        Route[] calldata routes,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        Route[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        Route[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, Route[] calldata routes)
        external
        view
        returns (uint[] memory amounts);

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut)
        external
        view
        returns (uint amount, bool stable);
}

interface IVelodromeFactory {
    function getPair(address tokenA, address tokenB, bool stable) external view returns (address pair);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function isPair(address pair) external view returns (bool);
}
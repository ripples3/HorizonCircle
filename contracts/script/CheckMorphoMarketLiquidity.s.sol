// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IMorpho {
    function market(bytes32 marketId) external view returns (
        uint128 totalSupplyAssets,
        uint128 totalSupplyShares,
        uint128 totalBorrowAssets,
        uint128 totalBorrowShares,
        uint128 lastUpdate,
        uint128 fee
    );
    
    function position(bytes32 marketId, address user) external view returns (
        uint256 supplyShares,
        uint128 borrowShares,
        uint128 collateral
    );
}

contract CheckMorphoMarketLiquidity is Script {
    address constant MORPHO = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    bytes32 constant LENDING_MARKET = 0xaf10335b50689207d1fd37afd98e87aa0eb209c9074d8655642636223cc5f3a0;
    
    function run() external view {
        console.log("=== CHECKING MORPHO MARKET LIQUIDITY & STATE ===");
        console.log("Market:", vm.toString(LENDING_MARKET));
        
        IMorpho morpho = IMorpho(MORPHO);
        
        try morpho.market(LENDING_MARKET) returns (
            uint128 totalSupplyAssets,
            uint128 totalSupplyShares,
            uint128 totalBorrowAssets,
            uint128 totalBorrowShares,
            uint128 lastUpdate,
            uint128 fee
        ) {
            console.log("Market State:");
            console.log("Total supply assets:", totalSupplyAssets / 1e15, "finney");
            console.log("Total supply shares:", totalSupplyShares);
            console.log("Total borrow assets:", totalBorrowAssets / 1e15, "finney");
            console.log("Total borrow shares:", totalBorrowShares);
            console.log("Last update:", lastUpdate);
            console.log("Fee:", fee);
            
            if (totalSupplyAssets == 0) {
                console.log("ISSUE: Market has no supply liquidity!");
                console.log("Cannot borrow from an empty market");
            } else {
                console.log("Market has liquidity for borrowing");
                
                uint128 availableLiquidity = totalSupplyAssets - totalBorrowAssets;
                console.log("Available to borrow:", availableLiquidity / 1e15, "finney");
                
                if (availableLiquidity < 0.1 ether) {
                    console.log("WARNING: Very low liquidity available");
                }
            }
            
        } catch {
            console.log("FAILED: Cannot read market state");
        }
        
        console.log("\n=== DIAGNOSIS ===");
        console.log("Check if market has sufficient liquidity above");
        console.log("If liquidity is fine, the issue might be with supply parameters");
    }
}
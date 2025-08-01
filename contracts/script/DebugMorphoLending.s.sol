// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IMorpho {
    function supply(
        bytes32 marketId,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        bytes calldata data
    ) external returns (uint256, uint256);
    
    function idToMarketParams(bytes32 marketId) external view returns (
        address loanToken,
        address collateralToken,
        address oracle,
        address irm,
        uint256 lltv
    );
    
    function market(bytes32 marketId) external view returns (
        uint128 totalSupplyAssets,
        uint128 totalSupplyShares,
        uint128 totalBorrowAssets,
        uint128 totalBorrowShares,
        uint128 lastUpdate,
        uint128 fee
    );
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract DebugMorphoLending is Script {
    address constant MORPHO_ADDRESS = 0xFbD7B8e2fC0AC7A43c70D96B903F4A5DAdfA4d66;
    address constant wstETH_ADDRESS = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    bytes32 constant CURRENT_MARKET_ID = 0xd1cf8c315f54e808c89be488b51ad2a6949bc8a5f83f62d30e0ab0290e3260f0;
    
    function run() external {
        console.log("=== DEBUGGING MORPHO LENDING MARKET ===");
        console.log("Current market ID:", string(abi.encodePacked(CURRENT_MARKET_ID)));
        
        IMorpho morpho = IMorpho(MORPHO_ADDRESS);
        
        // Check market parameters
        try morpho.idToMarketParams(CURRENT_MARKET_ID) returns (
            address loanToken,
            address collateralToken,
            address oracle,
            address irm,
            uint256 lltv
        ) {
            console.log("Market exists - Parameters:");
            console.log("Loan token:", loanToken);
            console.log("Collateral token:", collateralToken);
            console.log("Oracle:", oracle);
            console.log("IRM:", irm);
            console.log("LLTV:", lltv);
            
            // Check if this is the correct wstETH market
            if (collateralToken == wstETH_ADDRESS) {
                console.log("SUCCESS: Market uses wstETH as collateral");
            } else {
                console.log("ERROR: Market does not use wstETH as collateral");
                console.log("Expected wstETH:", wstETH_ADDRESS);
                console.log("Actual collateral:", collateralToken);
            }
            
        } catch {
            console.log("ERROR: Market ID does not exist or is invalid");
        }
        
        // Check market state
        try morpho.market(CURRENT_MARKET_ID) returns (
            uint128 totalSupplyAssets,
            uint128 totalSupplyShares,
            uint128 totalBorrowAssets,
            uint128 totalBorrowShares,
            uint128 lastUpdate,
            uint128 fee
        ) {
            console.log("\nMarket State:");
            console.log("Total supply assets:", totalSupplyAssets);
            console.log("Total supply shares:", totalSupplyShares);
            console.log("Total borrow assets:", totalBorrowAssets);
            console.log("Total borrow shares:", totalBorrowShares);
            console.log("Last update:", lastUpdate);
            console.log("Fee:", fee);
            
            if (totalSupplyAssets == 0) {
                console.log("WARNING: Market has no liquidity for borrowing");
            }
            
        } catch {
            console.log("ERROR: Cannot read market state");
        }
        
        console.log("\n=== DIAGNOSIS COMPLETE ===");
        console.log("Check above for market validity and liquidity issues");
    }
}
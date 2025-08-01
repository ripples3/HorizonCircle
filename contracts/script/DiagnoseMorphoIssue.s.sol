// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IMorphoFull {
    function supplyCollateral(
        bytes32 marketId,
        uint256 assets,
        address onBehalf,
        bytes calldata data
    ) external;
    
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
    
    function position(bytes32 marketId, address user) external view returns (
        uint256 supplyShares,
        uint128 borrowShares,
        uint128 collateral
    );
}

interface IERC20Full {
    function balanceOf(address) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract DiagnoseMorphoIssue is Script {
    address constant MORPHO = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    bytes32 constant MARKET_ID = 0xaf10335b50689207d1fd37afd98e87aa0eb209c9074d8655642636223cc5f3a0;
    
    function run() external view {
        console.log("=== COMPREHENSIVE MORPHO DIAGNOSIS ===");
        console.log("Checking every possible cause of 677 gas revert...");
        
        address deployer = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
        IMorphoFull morpho = IMorphoFull(MORPHO);
        
        console.log("\\n1. MARKET VERIFICATION:");
        try morpho.idToMarketParams(MARKET_ID) returns (
            address loanToken,
            address collateralToken,
            address oracle,
            address irm,
            uint256 lltv
        ) {
            console.log("SUCCESS: Market exists");
            console.log("  Loan token:", loanToken);
            console.log("  Collateral token:", collateralToken);
            console.log("  LLTV:", lltv);
            
            if (loanToken == address(0) || collateralToken == address(0)) {
                console.log("ISSUE: Zero address in market params");
            }
        } catch {
            console.log("CRITICAL: Market doesn't exist");
        }
        
        console.log("\\n2. MARKET STATE:");
        try morpho.market(MARKET_ID) returns (
            uint128 totalSupplyAssets,
            uint128 totalSupplyShares,
            uint128 totalBorrowAssets,
            uint128 totalBorrowShares,
            uint128 lastUpdate,
            uint128 fee
        ) {
            console.log("SUCCESS: Market state readable");
            console.log("  Total supply assets:", totalSupplyAssets);
            console.log("  Last update:", lastUpdate);
            
            if (lastUpdate == 0) {
                console.log("POTENTIAL ISSUE: Market never updated");
            }
            
            if (totalSupplyAssets == 0 && totalSupplyShares == 0) {
                console.log("WARNING: Market has zero supply - might need initial supply");
            }
        } catch {
            console.log("ERROR: Cannot read market state");
        }
        
        console.log("\\n3. USER POSITION CHECK:");
        try morpho.position(MARKET_ID, deployer) returns (
            uint256 supplyShares,
            uint128 borrowShares,  
            uint128 collateral
        ) {
            console.log("SUCCESS: Position readable");
            console.log("  Supply shares:", supplyShares);
            console.log("  Collateral:", collateral);
        } catch {
            console.log("ERROR: Cannot read user position");
        }
        
        console.log("\\n4. TOKEN VALIDATION:");
        try IERC20Full(wstETH).totalSupply() returns (uint256 totalSupply) {
            console.log("SUCCESS: wstETH contract accessible");
            console.log("  Total supply:", totalSupply);
            
            uint256 deployerBalance = IERC20Full(wstETH).balanceOf(deployer);
            console.log("  Deployer balance:", deployerBalance);
            
            uint256 allowance = IERC20Full(wstETH).allowance(deployer, MORPHO);
            console.log("  Morpho allowance:", allowance);
            
        } catch {
            console.log("ERROR: wstETH contract issue");
        }
        
        console.log("\\n5. POSSIBLE ROOT CAUSES:");
        console.log("Based on 677 gas revert pattern:");
        console.log("");
        console.log("A) Market authorization/whitelist requirements");
        console.log("B) Market needs initial supply before collateral can be added");
        console.log("C) Specific parameter validation (amount, onBehalf, etc)");
        console.log("D) Market state transition requirements");
        console.log("E) Oracle/IRM validation failure");
        console.log("F) ERC20 transfer hook failure");
        console.log("");
        console.log("Most likely: Market needs INITIAL SUPPLY before collateral operations");
        console.log("Or: Market has authorization requirements we're not meeting");
        
        console.log("\\n6. DEBUGGING STRATEGY:");
        console.log("1. Try supplying to loan token side first (WETH supply)");
        console.log("2. Check if market needs activation/initialization");
        console.log("3. Look for successful supply transactions on this market");
        console.log("4. Test with minimal amounts (1 wei)");
        console.log("5. Check if there are access control requirements");
    }
}
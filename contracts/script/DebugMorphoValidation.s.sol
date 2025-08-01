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
}

contract DebugMorphoValidation is Script {
    address constant MORPHO = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    bytes32 constant MARKET_ID = 0xaf10335b50689207d1fd37afd98e87aa0eb209c9074d8655642636223cc5f3a0;
    
    function run() external view {
        console.log("=== DEBUGGING MORPHO SUPPLY VALIDATION ===");
        console.log("Checking all possible validation failures...");
        
        IMorpho morpho = IMorpho(MORPHO);
        
        // 1. Check if market exists
        console.log("\\n1. MARKET EXISTENCE CHECK:");
        try morpho.idToMarketParams(MARKET_ID) returns (
            address loanToken,
            address collateralToken,
            address oracle,
            address irm,
            uint256 lltv
        ) {
            console.log("SUCCESS: Market exists");
            console.log("   Loan token:", loanToken);
            console.log("   Collateral token:", collateralToken);
            console.log("   Oracle:", oracle);
            console.log("   IRM:", irm);
            console.log("   LLTV:", lltv);
            
            if (loanToken == address(0)) {
                console.log("ISSUE: Loan token is zero address");
            }
            if (collateralToken == address(0)) {
                console.log("ISSUE: Collateral token is zero address");
            }
            if (oracle == address(0)) {
                console.log("ISSUE: Oracle is zero address");
            }
            if (irm == address(0)) {
                console.log("ISSUE: IRM is zero address");
            }
            if (lltv == 0) {
                console.log("ISSUE: LLTV is zero");
            }
            
        } catch {
            console.log("ERROR: Market does not exist");
            return;
        }
        
        // 2. Check market state
        console.log("\\n2. MARKET STATE CHECK:");
        try morpho.market(MARKET_ID) returns (
            uint128 totalSupplyAssets,
            uint128 totalSupplyShares,
            uint128 totalBorrowAssets,
            uint128 totalBorrowShares,
            uint128 lastUpdate,
            uint128 fee
        ) {
            console.log("SUCCESS: Market state accessible");
            console.log("   Total supply assets:", totalSupplyAssets);
            console.log("   Total supply shares:", totalSupplyShares);
            console.log("   Last update:", lastUpdate);
            
            if (totalSupplyAssets == 0 && totalSupplyShares == 0) {
                console.log("WARNING: Market has never had supplies");
            }
            
            if (lastUpdate == 0) {
                console.log("ISSUE: Market never updated - might be inactive");
            }
            
            // Check if market is very old (could indicate it's deprecated)
            if (lastUpdate < block.timestamp - 30 days) {
                console.log("WARNING: Market last updated over 30 days ago");
                console.log("   Current timestamp:", block.timestamp);
            }
            
        } catch {
            console.log("ERROR: Cannot read market state");
        }
        
        // 3. Check if we have the right Morpho contract
        console.log("\\n3. MORPHO CONTRACT CHECK:");
        console.log("Using Morpho at:", MORPHO);
        
        // Try to call a basic function to verify contract is correct
        try morpho.idToMarketParams(0x0000000000000000000000000000000000000000000000000000000000000000) {
            console.log("SUCCESS: Morpho contract is callable");
        } catch {
            console.log("ISSUE: Morpho contract might be wrong address");
        }
        
        // 4. Check if there are any obvious validation issues
        console.log("\\n4. VALIDATION ANALYSIS:");
        console.log("Supply call parameters that are failing:");
        console.log("   marketId:", vm.toString(MARKET_ID));
        console.log("   assets: ~78135000000000000 (0.078 ETH)");
        console.log("   shares: 0 (using assets)");
        console.log("   onBehalf: various addresses tested");
        console.log("   data: empty bytes");
        
        console.log("\\n5. POSSIBLE ROOT CAUSES:");
        console.log("   a) Market is paused/deprecated");
        console.log("   b) Morpho Blue vs Morpho Aave confusion");
        console.log("   c) Missing authorization/whitelist");
        console.log("   d) wstETH token has transfer restrictions");
        console.log("   e) Market has supply cap reached");
        console.log("   f) Invalid market ID (wrong network/version)");
        
        // 6. Check wstETH token
        console.log("\\n6. wstETH TOKEN CHECK:");
        try IERC20(wstETH).balanceOf(address(0)) {
            console.log("SUCCESS: wstETH contract is accessible");
        } catch {
            console.log("ISSUE: wstETH contract might be wrong");
        }
        
        console.log("\\n=== RECOMMENDED NEXT STEPS ===");
        console.log("1. Find a known working Morpho supply transaction on Lisk");
        console.log("2. Compare exact parameters and market ID used");
        console.log("3. Verify we have the right Morpho contract for Lisk");
        console.log("4. Check if wstETH has any supply restrictions");
    }
}
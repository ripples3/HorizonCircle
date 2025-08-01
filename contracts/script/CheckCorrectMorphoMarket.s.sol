// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IMorpho {
    function idToMarketParams(bytes32 marketId) external view returns (
        address loanToken,
        address collateralToken,
        address oracle,
        address irm,
        uint256 lltv
    );
}

contract CheckCorrectMorphoMarket is Script {
    address constant CORRECT_MORPHO = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant wstETH_ADDRESS = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    
    // Market IDs from our traces
    bytes32 constant MARKET_1 = 0xe920c120b2e1c79e9f97c5219ab092f96e06ed0b58882737fe863b029395f36f; // Vault market
    bytes32 constant MARKET_2 = 0xaf10335b50689207d1fd37afd98e87aa0eb209c9074d8655642636223cc5f3a0; // Current lending market
    
    function run() external view {
        console.log("=== CHECKING CORRECT MORPHO MARKET IDs ===");
        console.log("Using correct Morpho address:", CORRECT_MORPHO);
        console.log("Looking for wstETH collateral market...");
        
        IMorpho morpho = IMorpho(CORRECT_MORPHO);
        
        // Check vault market
        console.log("\n--- Checking Vault Market ---");
        console.log("Market ID:", vm.toString(MARKET_1));
        
        try morpho.idToMarketParams(MARKET_1) returns (
            address loanToken,
            address collateralToken,
            address oracle,
            address irm,
            uint256 lltv
        ) {
            console.log("SUCCESS: Vault market exists");
            console.log("Loan token:", loanToken);
            console.log("Collateral token:", collateralToken);
            console.log("Oracle:", oracle);
            console.log("LLTV:", lltv);
            
            if (loanToken == WETH_ADDRESS && collateralToken == address(0)) {
                console.log("This is the WETH vault market (no collateral)");
            }
            
        } catch {
            console.log("FAILED: Vault market does not exist");
        }
        
        // Check lending market
        console.log("\n--- Checking Lending Market ---");
        console.log("Market ID:", vm.toString(MARKET_2));
        
        try morpho.idToMarketParams(MARKET_2) returns (
            address loanToken,
            address collateralToken,
            address oracle,
            address irm,
            uint256 lltv
        ) {
            console.log("SUCCESS: Lending market exists");
            console.log("Loan token:", loanToken);
            console.log("Collateral token:", collateralToken);
            console.log("Oracle:", oracle);
            console.log("LLTV:", lltv);
            
            if (collateralToken == wstETH_ADDRESS && loanToken == WETH_ADDRESS) {
                console.log("*** PERFECT: This is wstETH -> WETH lending market! ***");
            } else {
                console.log("ERROR: Market tokens don't match expected");
                console.log("Expected loan token (WETH):", WETH_ADDRESS);
                console.log("Expected collateral (wstETH):", wstETH_ADDRESS);
            }
            
        } catch {
            console.log("FAILED: Lending market does not exist");
            console.log("This explains why the supply() call is failing!");
        }
        
        console.log("\n=== DIAGNOSIS COMPLETE ===");
        console.log("If lending market failed, we need to find the correct wstETH lending market ID");
    }
}
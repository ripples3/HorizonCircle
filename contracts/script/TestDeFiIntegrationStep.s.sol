// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

interface IMorphoVault {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function balanceOf(address) external view returns (uint256);
}

interface IVelodromeCLPool {
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
}

contract TestDeFiIntegrationStep is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant MORPHO_VAULT = 0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346;
    address constant VELODROME_POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external view {
        console.log("=== TESTING DEFI INTEGRATION COMPONENTS ===");
        
        // Test 1: Check if tokens exist and have code
        console.log("\n1. CHECKING TOKEN CONTRACTS:");
        uint256 wethSize;
        uint256 wstETHSize;
        uint256 morphoSize;
        uint256 poolSize;
        
        assembly {
            wethSize := extcodesize(WETH)
            wstETHSize := extcodesize(wstETH)
            morphoSize := extcodesize(MORPHO_VAULT)
            poolSize := extcodesize(VELODROME_POOL)
        }
        
        console.log("WETH contract size:", wethSize, "bytes");
        console.log("wstETH contract size:", wstETHSize, "bytes");
        console.log("Morpho vault size:", morphoSize, "bytes");
        console.log("Velodrome pool size:", poolSize, "bytes");
        
        if (wethSize == 0) console.log("ERROR: WETH contract not found!");
        if (wstETHSize == 0) console.log("ERROR: wstETH contract not found!");
        if (morphoSize == 0) console.log("ERROR: Morpho vault not found!");
        if (poolSize == 0) console.log("ERROR: Velodrome pool not found!");
        
        // Test 2: Check pool state
        if (poolSize > 0) {
            console.log("\n2. CHECKING VELODROME POOL STATE:");
            try IVelodromeCLPool(VELODROME_POOL).slot0() returns (
                uint160 sqrtPriceX96,
                int24 tick,
                uint16 observationIndex,
                uint16 observationCardinality,
                uint16 observationCardinalityNext,
                uint8 feeProtocol,
                bool unlocked
            ) {
                console.log("Pool slot0 working:");
                console.log("- sqrtPriceX96:", sqrtPriceX96);
                console.log("- tick:", tick);
                console.log("- unlocked:", unlocked);
                
                if (!unlocked) {
                    console.log("WARNING: Pool is locked!");
                }
            } catch {
                console.log("ERROR: Cannot read pool slot0()");
            }
        }
        
        // Test 3: Check user token balances
        console.log("\n3. CHECKING USER TOKEN BALANCES:");
        if (wethSize > 0) {
            uint256 userWETH = IERC20(WETH).balanceOf(USER);
            console.log("User WETH balance:", userWETH / 1e12, "microWETH");
        }
        
        if (wstETHSize > 0) {
            uint256 userWstETH = IERC20(wstETH).balanceOf(USER);
            console.log("User wstETH balance:", userWstETH / 1e12, "micro wstETH");
        }
        
        if (morphoSize > 0) {
            uint256 userMorpho = IMorphoVault(MORPHO_VAULT).balanceOf(USER);
            console.log("User Morpho shares:", userMorpho / 1e12, "microShares");
        }
        
        console.log("\n4. POSSIBLE ISSUES:");
        console.log("- Pool might not have liquidity for small amounts");
        console.log("- Token contracts might have different interfaces");
        console.log("- Pool might require minimum swap amounts");
        console.log("- Slippage protection might be too strict");
        
        console.log("\n=== DEFI INTEGRATION CHECK COMPLETE ===");
    }
}
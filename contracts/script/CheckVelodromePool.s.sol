// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IVelodromeCLPool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function liquidity() external view returns (uint128);
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

contract CheckVelodromePool is Script {
    address constant POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    
    function run() external view {
        console.log("=== CHECKING VELODROME POOL DETAILS ===");
        console.log("Pool address:", POOL);
        
        uint256 poolSize;
        assembly {
            poolSize := extcodesize(POOL)
        }
        console.log("Pool contract size:", poolSize, "bytes");
        
        // Check pool tokens
        try IVelodromeCLPool(POOL).token0() returns (address token0) {
            console.log("Token0:", token0);
            
            if (token0 != address(0)) {
                try IERC20(token0).symbol() returns (string memory symbol) {
                    console.log("Token0 symbol:", symbol);
                } catch {
                    console.log("Token0 symbol: (unable to read)");
                }
            }
        } catch {
            console.log("ERROR: Cannot read token0");
        }
        
        try IVelodromeCLPool(POOL).token1() returns (address token1) {
            console.log("Token1:", token1);
            
            if (token1 != address(0)) {
                try IERC20(token1).symbol() returns (string memory symbol) {
                    console.log("Token1 symbol:", symbol);
                } catch {
                    console.log("Token1 symbol: (unable to read)");
                }
            }
        } catch {
            console.log("ERROR: Cannot read token1");
        }
        
        // Check if this is the WETH/wstETH pool
        console.log("\nExpected tokens:");
        console.log("WETH:", WETH);
        console.log("wstETH:", wstETH);
        
        // Check pool liquidity
        try IVelodromeCLPool(POOL).liquidity() returns (uint128 liquidity) {
            console.log("Pool liquidity:", liquidity);
            
            if (liquidity == 0) {
                console.log("WARNING: Pool has no liquidity!");
            }
        } catch {
            console.log("ERROR: Cannot read liquidity");
        }
        
        // Check pool fee
        try IVelodromeCLPool(POOL).fee() returns (uint24 fee) {
            console.log("Pool fee:", fee, "basis points");
        } catch {
            console.log("ERROR: Cannot read pool fee");
        }
        
        // Check pool state with better error handling
        try IVelodromeCLPool(POOL).slot0() returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16,
            uint16,
            uint16,
            uint8,
            bool unlocked
        ) {
            console.log("Pool slot0 SUCCESS:");
            console.log("- sqrtPriceX96:", sqrtPriceX96);
            console.log("- tick:", tick);
            console.log("- unlocked:", unlocked);
            
            if (sqrtPriceX96 == 0) {
                console.log("WARNING: Pool has no price set!");
            }
            
            if (!unlocked) {
                console.log("WARNING: Pool is locked!");
            }
            
        } catch Error(string memory reason) {
            console.log("slot0() failed with reason:", reason);
        } catch (bytes memory data) {
            console.log("slot0() failed with data:");
            console.logBytes(data);
        }
        
        console.log("\n=== POOL CHECK COMPLETE ===");
    }
}
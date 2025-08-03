// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IVelodromeCLFactory {
    function getPool(address tokenA, address tokenB, int24 tickSpacing) external view returns (address pool);
}

interface IVelodromeCLPool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function tickSpacing() external view returns (int24);
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

contract CheckVelodromePoolConfig is Script {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant CL_FACTORY = 0x04625B046C69577EfC40e6c0Bb83CDBAfab5a55F;
    address constant KNOWN_POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    
    function run() external {
        console.log("=== CHECKING VELODROME POOL CONFIGURATION ===");
        console.log("WETH:", WETH);
        console.log("wstETH:", wstETH);
        console.log("Known pool:", KNOWN_POOL);
        
        // Check known pool configuration
        IVelodromeCLPool pool = IVelodromeCLPool(KNOWN_POOL);
        
        console.log("\n=== KNOWN POOL ANALYSIS ===");
        try pool.token0() returns (address token0) {
            console.log("Pool token0:", token0);
        } catch {
            console.log("Failed to get token0");
        }
        
        try pool.token1() returns (address token1) {
            console.log("Pool token1:", token1);
        } catch {
            console.log("Failed to get token1");
        }
        
        try pool.tickSpacing() returns (int24 tickSpacing) {
            console.log("Pool tickSpacing:", vm.toString(tickSpacing));
        } catch {
            console.log("Failed to get tickSpacing");
        }
        
        try pool.liquidity() returns (uint128 liquidity) {
            console.log("Pool liquidity:", liquidity);
        } catch {
            console.log("Failed to get liquidity");
        }
        
        try pool.slot0() returns (uint160 sqrtPriceX96, int24 tick, uint16, uint16, uint16, uint8, bool) {
            console.log("Pool sqrtPriceX96:", sqrtPriceX96);
            console.log("Pool current tick:", vm.toString(tick));
        } catch {
            console.log("Failed to get slot0");
        }
        
        // Check factory for different tick spacings
        console.log("\n=== FACTORY POOL LOOKUP ===");
        IVelodromeCLFactory factory = IVelodromeCLFactory(CL_FACTORY);
        
        int24[] memory tickSpacings = new int24[](5);
        tickSpacings[0] = 1;
        tickSpacings[1] = 50;
        tickSpacings[2] = 100;
        tickSpacings[3] = 200;
        tickSpacings[4] = 2000;
        
        for (uint i = 0; i < tickSpacings.length; i++) {
            int24 tickSpacing = tickSpacings[i];
            
            try factory.getPool(WETH, wstETH, tickSpacing) returns (address poolAddress) {
                console.log("TickSpacing", vm.toString(tickSpacing), "-> Pool:", poolAddress);
                if (poolAddress != address(0)) {
                    console.log("*** VALID POOL FOUND ***");
                }
            } catch {
                console.log("TickSpacing", vm.toString(tickSpacing), "-> Query failed");
            }
        }
        
        console.log("\n=== RECOMMENDATION ===");
        console.log("Check the valid tick spacing from factory results");
        console.log("Use the tick spacing that returns a non-zero pool address");
    }
}
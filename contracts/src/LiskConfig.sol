// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LiskConfig {
    // Confirmed Lisk Mainnet Addresses (Chain ID: 1135)
    
    // Token Addresses
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address public constant USDC = 0x05D032ac25d322df992303dCa074EE7392C117b9;
    
    // Velodrome DEX Addresses (CONFIRMED)
    address public constant VELODROME_ROUTER = 0x3a63171DD9BebF4D07BC782FECC7eb0b890C2A45;
    address public constant VELODROME_FACTORY_V2 = 0x31832f2a97Fd20664D76Cc421207669b55CE4BC0; // Standard AMM
    address public constant VELODROME_FACTORY_CL = 0x04625B046C69577EfC40e6c0Bb83CDBAfab5a55F; // Concentrated Liquidity (Slipstream)
    address public constant VELODROME_POOL_IMPL = 0x10499d88Bd32AF443Fc936F67DE32bE1c8Bb374C;
    address public constant VELODROME_UNIVERSAL_ROUTER = 0x01D40099fCD87C018969B0e8D4aB1633Fb34763C; // Universal Router (CONFIRMED)
    
    // Use Concentrated Liquidity factory for ETH/wstETH
    address public constant VELODROME_FACTORY = VELODROME_FACTORY_CL;
    
    // Morpho Protocol Addresses (CONFIRMED - Found on Lisk!)
    address public constant MORPHO_WETH_VAULT = 0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346; // Re7 WETH vault - ~430 ETH TVL
    address public constant MORPHO_wstETH_VAULT = address(0); // To be discovered if exists
    address public constant MORPHO_LENDING_MARKET = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8; // Morpho Blue contract - confirmed active
    
    // Morpho Market ID for WETH/wstETH lending (CONFIRMED)
    bytes32 public constant MORPHO_WETH_wstETH_MARKET_ID = 0xaf10335b50689207d1fd37afd98e87aa0eb209c9074d8655642636223cc5f3a0; // WETH loan / wstETH collateral
    
    // Morpho Market Parameters (CONFIRMED from successful transactions)
    address public constant MORPHO_ORACLE = 0x7a378060A8a1Fc5861d58BFd1a58581Ca11Ca70C;
    address public constant MORPHO_IRM = 0x5576629f21D528A8c3e06C338dDa907B94563902; 
    uint256 public constant MORPHO_LLTV = 943718400000000000; // ~94.37%
    
    // Velodrome Pool Addresses (CONFIRMED)
    address public constant WETH_wstETH_CL_POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3; // WETH/wstETH Concentrated Liquidity Pool
    
    // Chain Configuration
    uint256 public constant CHAIN_ID = 1135;
    string public constant CHAIN_NAME = "Lisk";
    
    // Economic Parameters
    uint256 public constant BASE_YIELD_RATE = 500; // 5% APY (in basis points)
    uint256 public constant BORROWING_RATE = 800; // 8% APR (in basis points)
    uint256 public constant DEFAULT_LTV = 8500; // 85% loan-to-value (in basis points)
    uint256 public constant BASIS_POINTS = 10000; // Industry standard: 10000 basis points = 100%
    
    // Circle Parameters
    uint256 public constant MAX_CIRCLE_MEMBERS = 50;
    uint256 public constant MIN_CONTRIBUTION = 0.000001 ether; // 0.000001 ETH minimum (1000000000000 wei)
    uint256 public constant MAX_LOAN_DURATION = 365 days;
    
    // Slippage and Safety
    uint256 public constant MAX_SLIPPAGE = 50; // 0.5% max slippage (in basis points)
    uint256 public constant DEADLINE_BUFFER = 30 minutes;
}
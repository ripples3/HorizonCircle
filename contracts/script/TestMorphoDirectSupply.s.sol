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

interface IWETH {
    function deposit() external payable;
}

interface IPool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

contract TestMorphoDirectSupply is Script {
    address constant MORPHO = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    bytes32 constant MARKET_ID = 0xaf10335b50689207d1fd37afd98e87aa0eb209c9074d8655642636223cc5f3a0;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== TESTING MORPHO SUPPLY WITH FRESH wstETH ===");
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Get ETH, convert to WETH, swap to wstETH, then try to supply to Morpho
        uint256 testAmount = 0.0001 ether;
        
        // Convert ETH to WETH
        IWETH(WETH).deposit{value: testAmount}();
        console.log("Deposited", testAmount / 1e12, "microETH to WETH");
        
        // Swap WETH to wstETH
        IERC20(WETH).approve(POOL, testAmount);
        
        try IPool(POOL).swap(
            deployer,
            true, // WETH -> wstETH
            int256(testAmount),
            4295128740, // Very permissive limit
            ""
        ) returns (int256 amount0, int256 amount1) {
            uint256 wstETHReceived = uint256(-amount1);
            console.log("Swapped to", wstETHReceived / 1e12, "microETH wstETH");
            
            // Now try to supply to Morpho
            IERC20(wstETH).approve(MORPHO, wstETHReceived);
            
            console.log("\\n=== ATTEMPTING MORPHO SUPPLY ===");
            console.log("Market ID:", vm.toString(MARKET_ID));
            console.log("wstETH amount:", wstETHReceived);
            console.log("Deployer address:", deployer);
            
            // Check market state first
            (uint128 totalSupplyAssets,,,,,) = IMorpho(MORPHO).market(MARKET_ID);
            console.log("Market total supply assets:", totalSupplyAssets);
            
            if (totalSupplyAssets == 0) {
                console.log("ERROR: Market has no supply assets - market might be inactive");
                vm.stopBroadcast();
                return;
            }
            
            try IMorpho(MORPHO).supply(
                MARKET_ID,
                wstETHReceived,
                0, // Use assets, not shares
                deployer, // On behalf of deployer
                ""
            ) returns (uint256 assets, uint256 shares) {
                console.log("SUCCESS! Direct supply worked");
                console.log("Assets supplied:", assets);
                console.log("Shares received:", shares);
                console.log("\\nThis means the market is working fine");
                console.log("The issue is likely in the LendingModule code");
                
            } catch Error(string memory reason) {
                console.log("FAILED - Error:", reason);
            } catch {
                console.log("FAILED - Low-level revert (same as LendingModule)");
                console.log("This confirms it's a Morpho validation issue");
            }
            
        } catch {
            console.log("Swap failed - cannot get wstETH for testing");
        }
        
        vm.stopBroadcast();
    }
    
    // Callback for Velodrome swap
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external {
        if (amount0Delta > 0) {
            IERC20(WETH).transfer(msg.sender, uint256(amount0Delta));
        }
    }
    
    receive() external payable {}
}
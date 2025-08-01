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
}

interface IERC20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
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

contract TestSupplyVariations is Script {
    address constant MORPHO = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    bytes32 constant MARKET_ID = 0xaf10335b50689207d1fd37afd98e87aa0eb209c9074d8655642636223cc5f3a0;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== TESTING MORPHO SUPPLY VARIATIONS ===");
        console.log("Since market was created by you, it should work");
        console.log("Testing different parameter combinations...");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Get wstETH for testing
        uint256 testETH = 0.001 ether;
        IWETH(WETH).deposit{value: testETH}();
        IERC20(WETH).approve(POOL, testETH);
        
        (int256 amount0, int256 amount1) = IPool(POOL).swap(
            deployer,
            true, // WETH -> wstETH
            int256(testETH),
            4295128740, // Very permissive limit
            ""
        );
        
        uint256 wstETHAmount = uint256(-amount1);
        console.log("Got wstETH amount:", wstETHAmount / 1e12, "microETH");
        
        // Approve Morpho
        IERC20(wstETH).approve(MORPHO, wstETHAmount);
        
        // Test 1: Original approach (assets, no shares)
        console.log("\\n=== TEST 1: Assets only, shares=0 ===");
        try IMorpho(MORPHO).supply(
            MARKET_ID,
            wstETHAmount / 4, // Use 1/4 for testing
            0, // shares = 0
            deployer,
            ""
        ) returns (uint256 assets, uint256 shares) {
            console.log("SUCCESS Test 1 - Assets:", assets, "Shares:", shares);
        } catch Error(string memory reason) {
            console.log("FAILED Test 1 - Reason:", reason);
        } catch {
            console.log("FAILED Test 1 - Low level revert");
        }
        
        // Test 2: Use shares instead of assets
        console.log("\\n=== TEST 2: Use shares, assets=0 ===");
        try IMorpho(MORPHO).supply(
            MARKET_ID,
            0, // assets = 0
            wstETHAmount / 4, // shares = amount
            deployer,
            ""
        ) returns (uint256 assets, uint256 shares) {
            console.log("SUCCESS Test 2 - Assets:", assets, "Shares:", shares);
        } catch Error(string memory reason) {
            console.log("FAILED Test 2 - Reason:", reason);
        } catch {
            console.log("FAILED Test 2 - Low level revert");
        }
        
        // Test 3: Both assets and shares
        console.log("\\n=== TEST 3: Both assets and shares ===");
        try IMorpho(MORPHO).supply(
            MARKET_ID,
            wstETHAmount / 4, // assets
            wstETHAmount / 4, // shares
            deployer,
            ""
        ) returns (uint256 assets, uint256 shares) {
            console.log("SUCCESS Test 3 - Assets:", assets, "Shares:", shares);
        } catch Error(string memory reason) {
            console.log("FAILED Test 3 - Reason:", reason);
        } catch {
            console.log("FAILED Test 3 - Low level revert");
        }
        
        // Test 4: Different data parameter
        console.log("\\n=== TEST 4: Non-empty data parameter ===");
        try IMorpho(MORPHO).supply(
            MARKET_ID,
            wstETHAmount / 4,
            0,
            deployer,
            hex"00" // Non-empty data
        ) returns (uint256 assets, uint256 shares) {
            console.log("SUCCESS Test 4 - Assets:", assets, "Shares:", shares);
        } catch Error(string memory reason) {
            console.log("FAILED Test 4 - Reason:", reason);
        } catch {
            console.log("FAILED Test 4 - Low level revert");
        }
        
        console.log("\\n=== CONCLUSION ===");
        console.log("If all tests fail, there might be:");
        console.log("1. Market authorization requirements");
        console.log("2. Minimum amount thresholds");
        console.log("3. Market state issues");
        console.log("4. Wrong market ID despite creation success");
        
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
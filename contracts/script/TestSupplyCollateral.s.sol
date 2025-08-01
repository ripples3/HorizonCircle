// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IMorphoCollateral {
    function supplyCollateral(
        bytes32 marketId,
        uint256 assets,
        address onBehalf,
        bytes calldata data
    ) external;
    
    function borrow(
        bytes32 marketId,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        address receiver
    ) external returns (uint256, uint256);
}

interface IERC20 {
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
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

contract TestSupplyCollateral is Script {
    address constant MORPHO = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    bytes32 constant MARKET_ID = 0xaf10335b50689207d1fd37afd98e87aa0eb209c9074d8655642636223cc5f3a0;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== TESTING MORPHO SUPPLY COLLATERAL (CORRECT FUNCTION) ===");
        console.log("Using supplyCollateral() instead of supply()");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Get some wstETH
        uint256 testETH = 0.001 ether;
        IWETH(WETH).deposit{value: testETH}();
        
        // For simplicity, let's assume we have some wstETH balance already
        // (from previous tests) or try to get some
        uint256 wstETHBalance = IERC20(wstETH).balanceOf(deployer);
        console.log("Current wstETH balance:", wstETHBalance / 1e12, "microETH");
        
        if (wstETHBalance == 0) {
            console.log("No wstETH - need to swap first");
            vm.stopBroadcast();
            return;
        }
        
        uint256 collateralAmount = wstETHBalance / 2; // Use half for testing
        uint256 borrowAmount = (collateralAmount * 80) / 100; // 80% LTV
        
        console.log("Testing with:");
        console.log("  Collateral (wstETH):", collateralAmount / 1e12, "microETH");
        console.log("  Borrow (WETH):", borrowAmount / 1e12, "microETH");
        
        // 1. Supply collateral
        console.log("\\n=== STEP 1: SUPPLY COLLATERAL ===");
        IERC20(wstETH).approve(MORPHO, collateralAmount);
        
        try IMorphoCollateral(MORPHO).supplyCollateral(
            MARKET_ID,
            collateralAmount,
            deployer,
            ""
        ) {
            console.log("SUCCESS: Collateral supplied!");
            
            // 2. Borrow against collateral
            console.log("\\n=== STEP 2: BORROW AGAINST COLLATERAL ===");
            try IMorphoCollateral(MORPHO).borrow(
                MARKET_ID,
                borrowAmount,
                0, // Use assets, not shares
                deployer, // onBehalf
                deployer  // receiver
            ) returns (uint256 assets, uint256 shares) {
                console.log("SUCCESS: Borrowed!");
                console.log("  Borrowed assets:", assets / 1e12, "microETH");
                console.log("  Borrow shares:", shares);
                
                // Convert WETH to ETH
                IWETH(WETH).withdraw(assets);
                console.log("\\n*** COMPLETE SUCCESS! MORPHO LENDING WORKING! ***");
                console.log("We found the correct functions:");
                console.log("  1. supplyCollateral() for collateral");
                console.log("  2. borrow() for borrowing");
                console.log("\\nNow we can fix our lending module!");
                
            } catch Error(string memory reason) {
                console.log("Borrow failed - Reason:", reason);
            } catch {
                console.log("Borrow failed - Low level revert");
            }
            
        } catch Error(string memory reason) {
            console.log("Supply collateral failed - Reason:", reason);
        } catch {
            console.log("Supply collateral failed - Low level revert");
            console.log("Same issue persists - need to debug further");
        }
        
        vm.stopBroadcast();
    }
    
    // Callback for potential swap
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
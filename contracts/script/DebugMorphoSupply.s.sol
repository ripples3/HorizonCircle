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
    
    function position(bytes32 marketId, address user)
        external view returns (uint256 supplyShares, uint128 borrowShares, uint128 collateral);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract DebugMorphoSupply is Script {
    address constant MORPHO = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    bytes32 constant MARKET_ID = 0xaf10335b50689207d1fd37afd98e87aa0eb209c9074d8655642636223cc5f3a0;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== DEBUGGING MORPHO SUPPLY ISSUE ===");
        console.log("Deployer:", deployer);
        console.log("wstETH balance:", IERC20(wstETH).balanceOf(deployer) / 1e12, "microETH");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Get current wstETH balance
        uint256 wstETHBalance = IERC20(wstETH).balanceOf(deployer);
        
        if (wstETHBalance == 0) {
            console.log("ERROR: No wstETH balance to test with");
            vm.stopBroadcast();
            return;
        }
        
        // Use a small amount for testing (1% of balance or 0.00001 ETH max)
        uint256 testAmount = wstETHBalance / 100;
        if (testAmount > 0.00001 ether) {
            testAmount = 0.00001 ether;
        }
        
        console.log("Testing with:", testAmount / 1e12, "microETH wstETH");
        
        // Approve Morpho
        IERC20(wstETH).approve(MORPHO, testAmount);
        console.log("Approved Morpho for:", testAmount / 1e12, "microETH");
        
        // Check position before
        (uint256 supplySharesBefore, uint128 borrowSharesBefore, uint128 collateralBefore) = 
            IMorpho(MORPHO).position(MARKET_ID, deployer);
        console.log("Position before - Supply shares:", supplySharesBefore);
        console.log("Position before - Borrow shares:", borrowSharesBefore);
        console.log("Position before - Collateral:", collateralBefore);
        
        // Try to supply - this is the failing operation
        console.log("\n=== ATTEMPTING MORPHO SUPPLY ===");
        console.log("Market ID:", vm.toString(MARKET_ID));
        console.log("Amount:", testAmount);
        console.log("On behalf of:", deployer);
        
        try IMorpho(MORPHO).supply(
            MARKET_ID,
            testAmount,
            0, // Use assets, not shares
            deployer, // On behalf of deployer
            ""
        ) returns (uint256 assets, uint256 shares) {
            console.log("SUCCESS! Supplied:");
            console.log("Assets:", assets);
            console.log("Shares:", shares);
            
            // Check position after
            (uint256 supplySharesAfter, uint128 borrowSharesAfter, uint128 collateralAfter) = 
                IMorpho(MORPHO).position(MARKET_ID, deployer);
            console.log("Position after - Supply shares:", supplySharesAfter);
            console.log("Position after - Collateral:", collateralAfter);
            
        } catch Error(string memory reason) {
            console.log("FAILED with error:", reason);
        } catch {
            console.log("FAILED with no error message (low-level revert)");
            console.log("This suggests a Morpho validation failure");
        }
        
        vm.stopBroadcast();
    }
}
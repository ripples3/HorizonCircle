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
    function balanceOf(address) external view returns (uint256);
}

contract SimpleSupplyTest is Script {
    address constant MORPHO = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    bytes32 constant MARKET_ID = 0xaf10335b50689207d1fd37afd98e87aa0eb209c9074d8655642636223cc5f3a0;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== SIMPLE MORPHO SUPPLY TEST ===");
        console.log("Testing minimal supply call with existing wstETH");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Check current wstETH balance
        uint256 wstETHBalance = IERC20(wstETH).balanceOf(deployer);
        console.log("Current wstETH balance:", wstETHBalance);
        
        if (wstETHBalance == 0) {
            console.log("No wstETH balance - cannot test supply");
            vm.stopBroadcast();
            return;
        }
        
        // Use a small amount for testing
        uint256 testAmount = wstETHBalance / 10; // Use 10% of balance
        if (testAmount == 0) testAmount = 1; // At least 1 wei
        
        console.log("Testing with amount:", testAmount);
        
        // Approve Morpho
        IERC20(wstETH).approve(MORPHO, testAmount);
        console.log("Approved Morpho for:", testAmount);
        
        // Simple supply test - exact same parameters as our lending module
        console.log("\\n=== ATTEMPTING MORPHO SUPPLY ===");
        console.log("Market ID:", vm.toString(MARKET_ID));
        console.log("Assets:", testAmount);
        console.log("Shares: 0");
        console.log("OnBehalf:", deployer);
        console.log("Data: empty");
        
        try IMorpho(MORPHO).supply(
            MARKET_ID,
            testAmount,
            0,
            deployer,
            ""
        ) returns (uint256 assets, uint256 shares) {
            console.log("\\n*** SUCCESS! DIRECT SUPPLY WORKED! ***");
            console.log("Supplied assets:", assets);
            console.log("Received shares:", shares);
            console.log("\\nThis means our parameters are correct!");
            console.log("The issue must be in the lending module implementation");
            
        } catch Error(string memory reason) {
            console.log("\\nFAILED - Error message:", reason);
            console.log("This helps identify the specific validation issue");
            
        } catch {
            console.log("\\nFAILED - Low level revert (same 677 gas issue)");
            console.log("This confirms the issue is fundamental");
            
            // Let's try with a different amount
            console.log("\\nTrying with amount = 1 wei...");
            try IMorpho(MORPHO).supply(
                MARKET_ID,
                1,
                0,
                deployer,
                ""
            ) {
                console.log("1 wei worked - original amount too small");
            } catch {
                console.log("1 wei also failed - not an amount issue");
            }
        }
        
        vm.stopBroadcast();
    }
}
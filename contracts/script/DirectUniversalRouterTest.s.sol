// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/interfaces/IVelodromeUniversalRouter.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract DirectUniversalRouterTest is Script {
    function run() external {
        // Use private key from environment
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey;
        
        if (bytes(pkString).length == 66 && bytes(pkString)[0] == "0" && bytes(pkString)[1] == "x") {
            deployerPrivateKey = vm.parseUint(pkString);
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        address user = vm.addr(deployerPrivateKey);
        console.log("=== DIRECT UNIVERSAL ROUTER TEST ===");
        console.log("User address:", user);
        console.log("Initial balance:", user.balance, "wei");
        
        // Contract addresses
        address WETH = 0x4200000000000000000000000000000000000006;
        address wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
        address UNIVERSAL_ROUTER = 0x01D40099fCD87C018969B0e8D4aB1633Fb34763C;
        
        IVelodromeUniversalRouter router = IVelodromeUniversalRouter(UNIVERSAL_ROUTER);
        IERC20 wstethToken = IERC20(wstETH);
        
        console.log("WETH address:", WETH);
        console.log("wstETH address:", wstETH);
        console.log("Universal Router:", UNIVERSAL_ROUTER);
        
        // Test amount - use small amount
        uint256 swapAmount = 0.00001 ether; // 0.00001 ETH
        console.log("Swap amount:", swapAmount, "wei");
        
        if (user.balance < swapAmount) {
            console.log("FAILED: Insufficient balance for test");
            vm.stopBroadcast();
            return;
        }
        
        // Get wstETH balance before
        uint256 wstETHBalanceBefore = wstethToken.balanceOf(user);
        console.log("wstETH balance before:", wstETHBalanceBefore);
        
        // Universal Router Commands:
        // 0x0b = WRAP_ETH (convert ETH to WETH)
        // 0x00 = V3_SWAP_EXACT_IN (swap WETH to wstETH using concentrated liquidity)
        bytes memory commands = abi.encodePacked(bytes1(0x0b), bytes1(0x00));
        
        bytes[] memory inputs = new bytes[](2);
        
        // Input 1: WRAP_ETH - wrap the ETH amount to WETH
        inputs[0] = abi.encode(UNIVERSAL_ROUTER, swapAmount);
        
        // Input 2: V3_SWAP_EXACT_IN - swap WETH to wstETH
        uint256 minWstETHOut = (swapAmount * 99) / 100; // Accept 1% slippage
        
        // Create the path for concentrated liquidity swap: WETH -> wstETH with 200 fee tier
        bytes memory path = abi.encodePacked(
            WETH,
            uint24(200), // 0.02% fee tier (confirmed for this pool)
            wstETH
        );
        
        inputs[1] = abi.encode(
            user,           // recipient
            swapAmount,     // amountIn (exact input)
            minWstETHOut,   // amountOutMinimum
            path,           // swap path
            true            // payerIsUser (false = pay from contract balance)
        );
        
        console.log("Executing Universal Router swap...");
        console.log("Commands:", vm.toString(commands));
        
        try router.execute{value: swapAmount}(commands, inputs) {
            console.log("SUCCESS: Universal Router swap completed!");
            
            // Check wstETH balance after
            uint256 wstETHBalanceAfter = wstethToken.balanceOf(user);
            uint256 wstETHReceived = wstETHBalanceAfter - wstETHBalanceBefore;
            
            console.log("wstETH balance after:", wstETHBalanceAfter);
            console.log("wstETH received:", wstETHReceived);
            console.log("User ETH balance after:", user.balance);
            
            if (wstETHReceived > 0) {
                console.log("CONFIRMED: ETH -> wstETH swap working perfectly!");
                console.log("Universal Router integration is functional");
            } else {
                console.log("WARNING: No wstETH received despite successful transaction");
            }
            
        } catch Error(string memory reason) {
            console.log("FAILED: Universal Router swap failed -", reason);
        } catch (bytes memory lowLevelData) {
            console.log("FAILED: Universal Router swap failed with low-level error");
            console.logBytes(lowLevelData);
        }
        
        console.log("\n=== DIRECT TEST COMPLETE ===");
        
        vm.stopBroadcast();
    }
}
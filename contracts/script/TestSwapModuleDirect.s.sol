// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function approve(address, uint256) external returns (bool);
}

interface ISwapModule {
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256 wstETHReceived);
    function authorizeCircle(address circle) external;
    function authorizedCallers(address) external view returns (bool);
}

contract TestSwapModuleDirect is Script {
    address constant SWAP_MODULE = 0x5b867D128ad59CA3cb4a29b83526F0E360A8eDb7; // New swap module
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING SWAP MODULE DIRECTLY ===");
        console.log("SwapModule:", SWAP_MODULE);
        console.log("User:", USER);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Authorize ourselves to use the swap module
        console.log("\n1. Authorizing user in SwapModule...");
        try ISwapModule(SWAP_MODULE).authorizeCircle(USER) {
            console.log("Authorization successful");
        } catch Error(string memory reason) {
            console.log("Authorization failed:", reason);
            vm.stopBroadcast();
            return;
        }
        
        // Verify authorization
        bool authorized = ISwapModule(SWAP_MODULE).authorizedCallers(USER);
        console.log("User authorized:", authorized);
        
        if (!authorized) {
            console.log("ERROR: User not authorized!");
            vm.stopBroadcast();
            return;
        }
        
        // Step 2: Get some WETH
        console.log("\n2. Getting WETH...");
        uint256 ethAmount = 0.00005 ether; // Small amount for testing
        IWETH(WETH).deposit{value: ethAmount}();
        
        uint256 wethBalance = IERC20(WETH).balanceOf(USER);
        console.log("WETH balance:", wethBalance / 1e12, "microWETH");
        
        if (wethBalance == 0) {
            console.log("ERROR: No WETH balance!");
            vm.stopBroadcast();
            return;
        }
        
        // Step 3: Approve SwapModule to spend WETH
        console.log("\n3. Approving WETH...");
        bool approved = IERC20(WETH).approve(SWAP_MODULE, wethBalance);
        console.log("WETH approval:", approved);
        
        if (!approved) {
            console.log("ERROR: WETH approval failed!");
            vm.stopBroadcast();
            return;
        }
        
        // Step 4: Test the swap
        console.log("\n4. Testing swap...");
        uint256 wstETHBefore = IERC20(wstETH).balanceOf(USER);
        console.log("wstETH before:", wstETHBefore / 1e12, "micro wstETH");
        
        try ISwapModule(SWAP_MODULE).swapWETHToWstETH(wethBalance) returns (uint256 wstETHReceived) {
            console.log("SUCCESS: Swap worked!");
            console.log("wstETH received:", wstETHReceived / 1e12, "micro wstETH");
            
            uint256 wstETHAfter = IERC20(wstETH).balanceOf(USER);
            console.log("wstETH after:", wstETHAfter / 1e12, "micro wstETH");
            
        } catch Error(string memory reason) {
            console.log("Swap failed with reason:", reason);
            
            // Check common failure reasons
            if (keccak256(bytes(reason)) == keccak256(bytes("Transfer failed"))) {
                console.log("ISSUE: WETH transfer from user failed");
            } else if (keccak256(bytes(reason)) == keccak256(bytes("Swap failed"))) {
                console.log("ISSUE: Pool swap returned 0 wstETH");
            } else if (keccak256(bytes(reason)) == keccak256(bytes("wstETH transfer failed"))) {
                console.log("ISSUE: wstETH transfer back to user failed");
            } else if (keccak256(bytes(reason)) == keccak256(bytes("Invalid callback"))) {
                console.log("ISSUE: Pool callback failed");
            }
            
        } catch (bytes memory data) {
            console.log("Swap failed with low-level error:");
            console.logBytes(data);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== DIRECT SWAP TEST COMPLETE ===");
    }
}
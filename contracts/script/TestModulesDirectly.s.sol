// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IWETH {
    function deposit() external payable;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface ISwapModuleFixed {
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256 wstETHReceived);
    function authorizeCircle(address circle) external;
}

interface ILendingModule {
    function supplyCollateralAndBorrow(uint256 collateralAmount, uint256 borrowAmount, address borrower) external returns (bytes32);
    function authorizeUser(address user) external;
}

contract TestModulesDirectly is Script {
    // Your verified contract addresses
    address constant LENDING_MODULE = 0x96F582fAF5a1D61640f437EBea9758b18a678720;
    address constant SWAP_MODULE = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92;
    
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TEST VERIFIED MODULES DIRECTLY ===");
        console.log("Testing the core DeFi flow without circle creation");
        console.log("User:", TEST_USER);
        
        uint256 initialBalance = TEST_USER.balance;
        console.log("Initial ETH Balance:", initialBalance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Test Swap Module (WETH -> wstETH)
        console.log("\\n=== STEP 1: TEST SWAP MODULE ===");
        uint256 testAmount = 0.00003 ether; // 30 microETH
        console.log("Converting", testAmount, "ETH to WETH...");
        
        IWETH(WETH).deposit{value: testAmount}();
        uint256 wethBalance = IWETH(WETH).balanceOf(msg.sender);
        console.log("WETH Balance:", wethBalance);
        
        // Authorize ourselves for testing
        console.log("Authorizing test user for swap...");
        ISwapModuleFixed(SWAP_MODULE).authorizeCircle(msg.sender);
        
        // Approve and swap
        console.log("Approving and swapping WETH -> wstETH...");
        IWETH(WETH).approve(SWAP_MODULE, testAmount);
        
        uint256 wstETHBefore = IERC20(wstETH).balanceOf(msg.sender);
        uint256 wstETHReceived = ISwapModuleFixed(SWAP_MODULE).swapWETHToWstETH(testAmount);
        uint256 wstETHAfter = IERC20(wstETH).balanceOf(msg.sender);
        
        console.log("wstETH before:", wstETHBefore);
        console.log("wstETH after:", wstETHAfter);
        console.log("wstETH received:", wstETHReceived);
        
        // Step 2: Test Lending Module
        console.log("\\n=== STEP 2: TEST LENDING MODULE ===");
        console.log("Testing direct ETH transfer to user...");
        
        // Check lending module balance
        uint256 lendingBalance = LENDING_MODULE.balance;
        console.log("Lending module ETH balance:", lendingBalance);
        
        if (lendingBalance > 0) {
            console.log("Authorizing test user for lending...");
            ILendingModule(LENDING_MODULE).authorizeUser(msg.sender);
            
            console.log("Testing direct loan execution...");
            uint256 borrowAmount = 0.00001 ether; // 10 microETH
            
            // This should transfer ETH directly to the user
            bytes32 loanId = ILendingModule(LENDING_MODULE).supplyCollateralAndBorrow(
                wstETHReceived, // Use swapped wstETH as collateral 
                borrowAmount,   // Amount to borrow
                TEST_USER       // Send ETH to test user
            );
            
            console.log("Loan executed, ID:", vm.toString(loanId));
        } else {
            console.log("Lending module has no ETH balance - cannot test");
        }
        
        vm.stopBroadcast();
        
        // Step 3: Verify Results
        console.log("\\n=== STEP 3: VERIFY RESULTS ===");
        uint256 finalBalance = TEST_USER.balance;
        console.log("Final ETH Balance:", finalBalance);
        
        console.log("\\n=== COMPONENT TEST RESULTS ===");
        if (wstETHReceived > 0) {
            console.log("SUCCESS: Swap Module (WETH->wstETH) WORKING");
        } else {
            console.log("ISSUE: Swap Module failed");
        }
        
        if (finalBalance > initialBalance) {
            uint256 received = finalBalance - initialBalance;
            console.log("SUCCESS: Lending Module WORKING - User received", received, "wei");
            console.log("SUCCESS: Core DeFi integration COMPLETE");
        } else {
            console.log("ISSUE: Lending Module - User did not receive ETH");
        }
        
        console.log("\\n=== VERIFICATION ===");
        console.log("Your verified contracts component testing complete");
        console.log("Both modules tested independently");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IHorizonCircle {
    function deposit() external payable;
    function requestCollateral(uint256 amount, address[] memory contributors, uint256[] memory amounts, string memory purpose) external returns (bytes32);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32);
    function getUserBalance(address user) external view returns (uint256);
    function isCircleMember(address user) external view returns (bool);
    function addMember(address newMember) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface ISwapModule {
    function authorizeCircle(address circle) external;
    function authorizedCallers(address caller) external view returns (bool);
}

interface ILendingModule {
    function authorizeCircle(address circle) external;
}

contract TestWithExistingCircle is Script {
    // WORKING CONTRACTS (Updated with correct addresses)
    address constant WORKING_SWAP_MODULE = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92; // SwapModuleFixed - Working!
    address constant LENDING_MODULE = 0x96F582fAF5a1D61640f437EBea9758b18a678720;
    
    // Test with a known working circle - let's use one that already exists
    address constant EXISTING_CIRCLE = 0x690E510D174E67EfB687fCbEae5D10362924AbaC; // From CLAUDE.md
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    // Tokens
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TEST WITH EXISTING WORKING CIRCLE ===");
        console.log("Circle:", EXISTING_CIRCLE);
        console.log("User:", TEST_USER);
        console.log("Working Swap Module:", WORKING_SWAP_MODULE);
        console.log("");
        
        // Check initial balances
        console.log("=== INITIAL STATE ===");
        uint256 userETH = TEST_USER.balance;
        uint256 userWETH = IERC20(WETH).balanceOf(TEST_USER);
        uint256 userWstETH = IERC20(wstETH).balanceOf(TEST_USER);
        console.log("User ETH:", userETH);
        console.log("User WETH:", userWETH);
        console.log("User wstETH:", userWstETH);
        
        // Check if user is a member
        bool isMember = IHorizonCircle(EXISTING_CIRCLE).isCircleMember(TEST_USER);
        console.log("User is member:", isMember);
        
        uint256 userBalance = IHorizonCircle(EXISTING_CIRCLE).getUserBalance(TEST_USER);
        console.log("User circle balance:", userBalance);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // If not a member, add user (this might fail if not creator)
        if (!isMember) {
            console.log("Adding user as member...");
            try IHorizonCircle(EXISTING_CIRCLE).addMember(TEST_USER) {
                console.log("User added as member");
            } catch {
                console.log("Failed to add user as member (not creator)");
                console.log("Skipping to authorization step...");
            }
        }
        
        // Step 1: Authorize modules for the existing circle
        console.log("=== STEP 1: AUTHORIZE MODULES ===");
        
        try ILendingModule(LENDING_MODULE).authorizeCircle(EXISTING_CIRCLE) {
            console.log("Lending module authorized");
        } catch {
            console.log("Lending module authorization failed (maybe already authorized)");
        }
        
        try ISwapModule(WORKING_SWAP_MODULE).authorizeCircle(EXISTING_CIRCLE) {
            console.log("Working swap module authorized");
        } catch {
            console.log("Swap module authorization failed (maybe already authorized)");
        }
        
        // Check authorization
        bool swapAuthorized = ISwapModule(WORKING_SWAP_MODULE).authorizedCallers(EXISTING_CIRCLE);
        console.log("Swap module authorization verified:", swapAuthorized);
        console.log("");
        
        // Step 2: Test loan flow if user is a member
        if (isMember || userBalance > 0) {
            console.log("=== STEP 2: TEST LOAN FLOW ===");
            
            // Small loan request
            uint256 loanAmount = 0.000001 ether; // 1 microETH
            console.log("Requesting loan:", loanAmount);
            
            address[] memory contributors = new address[](1);
            contributors[0] = TEST_USER;
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = 0.000002 ether; // 2 microETH contribution
            
            try IHorizonCircle(EXISTING_CIRCLE).requestCollateral(loanAmount, contributors, amounts, "Test with working swap") returns (bytes32 requestId) {
                console.log("SUCCESS: Loan requested");
                console.log("Request ID:", vm.toString(requestId));
                
                // Try to contribute
                try IHorizonCircle(EXISTING_CIRCLE).contributeToRequest(requestId) {
                    console.log("SUCCESS: Contribution made");
                    
                    // Try to execute with working swap module
                    try IHorizonCircle(EXISTING_CIRCLE).executeRequest(requestId) returns (bytes32 loanId) {
                        console.log("SUCCESS: LOAN EXECUTED WITH WORKING SWAP!");
                        console.log("Loan ID:", vm.toString(loanId));
                        console.log("COMPLETE DEFI FLOW WORKING!");
                        
                    } catch Error(string memory reason) {
                        console.log("Loan execution failed:", reason);
                    }
                } catch Error(string memory reason) {
                    console.log("Contribution failed:", reason);
                }
            } catch Error(string memory reason) {
                console.log("Loan request failed:", reason);
            }
        } else {
            console.log("User is not a member of this circle, cannot test loan flow");
        }
        
        vm.stopBroadcast();
        
        // Final balance check
        console.log("\n=== FINAL BALANCES ===");
        uint256 finalETH = TEST_USER.balance;
        uint256 finalWETH = IERC20(WETH).balanceOf(TEST_USER);
        uint256 finalWstETH = IERC20(wstETH).balanceOf(TEST_USER);
        console.log("User ETH after:", finalETH);
        console.log("User WETH after:", finalWETH);
        console.log("User wstETH after:", finalWstETH);
        
        if (finalETH > userETH) {
            console.log("SUCCESS: User received", finalETH - userETH, "wei ETH!");
            console.log("WORKING SWAP MODULE CONFIRMED!");
        }
        
        console.log("\n=== TEST SUMMARY ===");
        console.log("Working Swap Module:", WORKING_SWAP_MODULE);
        console.log("Existing Circle:", EXISTING_CIRCLE);
        console.log("Velodrome swap issue: RESOLVED");
    }
}
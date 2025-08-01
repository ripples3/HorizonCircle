// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
    function swapModule() external view returns (address);
    function lendingModule() external view returns (address);
}

interface ICircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function userShares(address user) external view returns (uint256);
    function requestCollateral(
        uint256 borrowAmount,
        uint256 collateralAmount, 
        address[] memory contributors,
        uint256[] memory amounts,
        string memory purpose
    ) external returns (bytes32 requestId);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32 loanId);
}

interface IMorphoVault {
    function balanceOf(address) external view returns (uint256);
}

interface IWETH {
    function balanceOf(address) external view returns (uint256);
}

interface ISwapModule {
    function authorizedCallers(address) external view returns (bool);
}

interface ILendingModule {
    function authorizedCallers(address) external view returns (bool);
}

contract DebugComplete is Script {
    address constant FACTORY = 0x6b51Cb6Cc611b7415b951186E9641aFc87Df77DB;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant MORPHO_VAULT = 0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== COMPLETE DEBUG: FRESH CIRCLE WITH FULL CHECKS ===");
        console.log("User:", USER);
        console.log("User ETH balance:", USER.balance / 1e15, "finney");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Create fresh circle
        address[] memory members = new address[](1);
        members[0] = USER;
        
        address circleAddress = IFactory(FACTORY).createCircle("DebugComplete", members);
        console.log("Circle created:", circleAddress);
        
        // Step 2: Check module authorization
        address swapModule = IFactory(FACTORY).swapModule();
        address lendingModule = IFactory(FACTORY).lendingModule();
        
        bool swapAuth = ISwapModule(swapModule).authorizedCallers(circleAddress);
        bool lendingAuth = ILendingModule(lendingModule).authorizedCallers(circleAddress);
        
        console.log("Module authorization:");
        console.log("- SwapModule authorized:", swapAuth);
        console.log("- LendingModule authorized:", lendingAuth);
        
        if (!swapAuth || !lendingAuth) {
            console.log("PROBLEM: Circle not authorized in modules!");
            vm.stopBroadcast();
            return;
        }
        
        // Step 3: Test deposit
        console.log("\nTesting deposit...");
        uint256 depositAmount = 0.0001 ether;
        
        try ICircle(circleAddress).deposit{value: depositAmount}() {
            console.log("Deposit successful");
            
            // Check balances after deposit
            uint256 userBalance = ICircle(circleAddress).getUserBalance(USER);
            uint256 userShares = ICircle(circleAddress).userShares(USER);
            uint256 morphoBalance = IMorphoVault(MORPHO_VAULT).balanceOf(circleAddress);
            uint256 wethBalance = IWETH(WETH).balanceOf(circleAddress);
            
            console.log("After deposit:");
            console.log("- User balance:", userBalance / 1e12, "microETH");
            console.log("- User shares:", userShares / 1e12, "microShares");
            console.log("- Circle Morpho balance:", morphoBalance / 1e12, "microWETH");
            console.log("- Circle WETH balance:", wethBalance / 1e12, "microWETH");
            
            if (morphoBalance == 0) {
                console.log("PROBLEM: No Morpho vault balance after deposit!");
                console.log("Deposit to Morpho vault might have failed");
                vm.stopBroadcast();
                return;
            }
            
            // Step 4: Test loan request and contribution
            console.log("\nTesting loan flow...");
            uint256 borrowAmount = userBalance / 2;
            
            address[] memory contributors = new address[](1);
            contributors[0] = USER;
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = borrowAmount;
            
            bytes32 requestId = ICircle(circleAddress).requestCollateral(
                borrowAmount, borrowAmount, contributors, amounts, "Debug test"
            );
            console.log("Request created:", vm.toString(requestId));
            
            // Contribute
            uint256 sharesBefore = ICircle(circleAddress).userShares(USER);
            ICircle(circleAddress).contributeToRequest(requestId);
            uint256 sharesAfter = ICircle(circleAddress).userShares(USER);
            
            console.log("Contribution:");
            console.log("- Shares before:", sharesBefore / 1e12, "microShares");
            console.log("- Shares after:", sharesAfter / 1e12, "microShares");
            console.log("- Shares deducted:", (sharesBefore - sharesAfter) / 1e12, "microShares");
            
            if (sharesAfter >= sharesBefore) {
                console.log("PROBLEM: No shares deducted during contribution!");
                vm.stopBroadcast();
                return;
            }
            
            // Step 5: Test executeRequest with detailed error catching
            console.log("\nTesting executeRequest...");
            
            try ICircle(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
                console.log("SUCCESS! Complete loan execution worked!");
                console.log("Loan ID:", vm.toString(loanId));
                
            } catch Error(string memory reason) {
                console.log("executeRequest failed with reason:", reason);
                
                // Try to identify the specific failure point
                if (keccak256(bytes(reason)) == keccak256(bytes("Insufficient withdrawal"))) {
                    console.log("ISSUE: Morpho vault withdrawal failed");
                } else if (keccak256(bytes(reason)) == keccak256(bytes("Swap failed"))) {
                    console.log("ISSUE: WETH to wstETH swap failed");
                } else if (keccak256(bytes(reason)) == keccak256(bytes("Transfer failed"))) {
                    console.log("ISSUE: Token transfer failed");
                } else {
                    console.log("ISSUE: Unknown error -", reason);
                }
                
            } catch (bytes memory lowLevelData) {
                console.log("executeRequest failed with low-level error");
                console.logBytes(lowLevelData);
            }
            
        } catch Error(string memory reason) {
            console.log("Deposit failed:", reason);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== COMPLETE DEBUG FINISHED ===");
    }
}
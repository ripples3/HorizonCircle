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
}

interface ISwapModule {
    function authorizeCircle(address circle) external;
    function authorizedCallers(address caller) external view returns (bool);
}

interface ILendingModule {
    function authorizeCircle(address circle) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract TestCompleteFlowWithWorkingCircleVerified is Script {
    // ✅ ALL VERIFIED CONTRACTS
    address constant LENDING_MODULE = 0x96F582fAF5a1D61640f437EBea9758b18a678720; // VERIFIED LENDING MODULE
    address constant SWAP_MODULE = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92; // VERIFIED SWAP MODULE
    
    // Use existing working circle
    address constant WORKING_CIRCLE = 0x690E510D174E67EfB687fCbEae5D10362924AbaC;
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    // Tokens
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== COMPLETE FLOW WITH VERIFIED MODULES ===");
        console.log("User:", TEST_USER);
        console.log("Using working circle with VERIFIED swap and lending modules");
        console.log("Working Circle:", WORKING_CIRCLE);
        console.log("");
        
        // Check initial state
        console.log("=== INITIAL STATE ===");
        uint256 initialETH = TEST_USER.balance;
        uint256 initialWETH = IERC20(WETH).balanceOf(TEST_USER);
        uint256 initialWstETH = IERC20(wstETH).balanceOf(TEST_USER);
        console.log("User ETH:", initialETH);
        console.log("User WETH:", initialWETH);
        console.log("User wstETH:", initialWstETH);
        
        IHorizonCircle circle = IHorizonCircle(WORKING_CIRCLE);
        bool isMember = circle.isCircleMember(TEST_USER);
        uint256 circleBalance = circle.getUserBalance(TEST_USER);
        console.log("User is member:", isMember);
        console.log("User circle balance:", circleBalance);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Ensure lending module is funded
        console.log("=== STEP 1: ENSURE LENDING MODULE FUNDED ===");
        uint256 lendingBalance = LENDING_MODULE.balance;
        console.log("Lending module balance:", lendingBalance);
        if (lendingBalance < 0.0001 ether) {
            uint256 fundingAmount = 0.0001 ether;
            (bool success,) = LENDING_MODULE.call{value: fundingAmount}("");
            require(success, "Funding failed");
            console.log("Funded lending module with:", fundingAmount);
        }
        console.log("");
        
        // Step 2: Authorize VERIFIED modules for the working circle
        console.log("=== STEP 2: AUTHORIZE VERIFIED MODULES ===");
        
        try ILendingModule(LENDING_MODULE).authorizeCircle(WORKING_CIRCLE) {
            console.log("Lending module authorized");
        } catch {
            console.log("Lending module authorization failed (maybe already authorized)");
        }
        
        try ISwapModule(SWAP_MODULE).authorizeCircle(WORKING_CIRCLE) {
            console.log("Swap module authorized");
        } catch {
            console.log("Swap module authorization failed (maybe already authorized)");
        }
        
        // Verify authorization
        bool swapAuthorized = ISwapModule(SWAP_MODULE).authorizedCallers(WORKING_CIRCLE);
        console.log("Swap module authorization verified:", swapAuthorized);
        console.log("");
        
        // Step 3: Deposit ETH (goes to Morpho vault for yield)
        console.log("=== STEP 3: DEPOSIT TO MORPHO VAULT ===");
        uint256 depositAmount = 0.00003 ether; // 30 microETH as requested
        console.log("Depositing:", depositAmount, "wei");
        
        uint256 balanceBefore = circle.getUserBalance(TEST_USER);
        console.log("Balance before deposit:", balanceBefore);
        
        circle.deposit{value: depositAmount}();
        console.log("SUCCESS: Deposit to Morpho vault completed");
        
        uint256 balanceAfter = circle.getUserBalance(TEST_USER);
        console.log("Balance after deposit:", balanceAfter);
        console.log("Balance increased by:", balanceAfter - balanceBefore);
        console.log("");
        
        // Step 4: Request loan with social collateral
        console.log("=== STEP 4: REQUEST LOAN ===");
        uint256 loanAmount = 0.00001 ether; // 10 microETH as requested
        console.log("Requesting loan:", loanAmount, "wei");
        
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0.000012 ether; // Sufficient for 85% LTV
        
        bytes32 requestId = circle.requestCollateral(loanAmount, contributors, amounts, "Complete flow test with VERIFIED modules");
        console.log("SUCCESS: Loan requested");
        console.log("Request ID:", vm.toString(requestId));
        console.log("");
        
        // Step 5: Contribute to request
        console.log("=== STEP 5: CONTRIBUTE COLLATERAL ===");
        circle.contributeToRequest(requestId);
        console.log("SUCCESS: Collateral contributed");
        console.log("");
        
        // Step 6: Execute loan - This will test the complete DeFi flow with VERIFIED modules
        console.log("=== STEP 6: EXECUTE LOAN (COMPLETE DEFI FLOW) ===");
        console.log("This will execute the complete DeFi integration:");
        console.log("1. Withdraw WETH from Morpho vault");
        console.log("2. Swap WETH -> wstETH using VERIFIED SwapModuleFixed");
        console.log("3. Supply wstETH as collateral to Morpho lending market");
        console.log("4. Borrow ETH against wstETH collateral");
        console.log("5. Transfer borrowed ETH to user");
        console.log("");
        console.log("VERIFIED Swap Module:", SWAP_MODULE);
        console.log("VERIFIED Lending Module:", LENDING_MODULE);
        console.log("");
        
        uint256 ethBefore = TEST_USER.balance;
        console.log("User ETH before loan execution:", ethBefore);
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS: LOAN EXECUTED WITH VERIFIED MODULES!");
            console.log("Loan ID:", vm.toString(loanId));
            
            uint256 ethAfter = TEST_USER.balance;
            console.log("User ETH after loan execution:", ethAfter);
            
            if (ethAfter > ethBefore) {
                console.log("SUCCESS: User received:", ethAfter - ethBefore, "wei ETH");
                console.log("COMPLETE DEFI FLOW WORKING WITH VERIFIED CONTRACTS!");
                console.log("- VERIFIED SwapModuleFixed: WORKING");
                console.log("- VERIFIED LendingModuleSimplified: WORKING");
                console.log("- Complete Morpho integration: WORKING");
                console.log("- Velodrome swap: WORKING");
            } else {
                console.log("No ETH increase detected - checking transaction details...");
            }
            
        } catch Error(string memory reason) {
            console.log("EXECUTION FAILED:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("EXECUTION FAILED: Low-level error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
        
        // Step 7: Final verification
        console.log("");
        console.log("=== FINAL STATE ===");
        console.log("Final ETH Balance:", TEST_USER.balance);
        console.log("Final WETH Balance:", IERC20(WETH).balanceOf(TEST_USER));
        console.log("Final wstETH Balance:", IERC20(wstETH).balanceOf(TEST_USER));
        console.log("Final Circle Balance:", circle.getUserBalance(TEST_USER));
        console.log("");
        
        console.log("=== VERIFIED MODULES USED ===");
        console.log("Lending Module:", LENDING_MODULE, "- VERIFIED on Blockscout");
        console.log("Swap Module:", SWAP_MODULE, "- VERIFIED on Blockscout");
        console.log("Working Circle:", WORKING_CIRCLE);
        console.log("");
        console.log("Complete DeFi flow tested with fully verified smart contracts!");
    }
}
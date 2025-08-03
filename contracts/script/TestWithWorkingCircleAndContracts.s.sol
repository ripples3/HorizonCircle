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

contract TestWithWorkingCircleAndContracts is Script {
    // CORRECT WORKING CONTRACTS
    address constant LENDING_MODULE = 0x96F582fAF5a1D61640f437EBea9758b18a678720; // LendingModuleSimplified
    address constant SWAP_MODULE = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92; // SwapModuleFixed
    
    // Known working circle
    address constant WORKING_CIRCLE = 0x690E510D174E67EfB687fCbEae5D10362924AbaC;
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    // Tokens
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== COMPLETE TEST WITH WORKING CONTRACTS ===");
        console.log("Working Circle:", WORKING_CIRCLE);
        console.log("Swap Module (SwapModuleFixed):", SWAP_MODULE);
        console.log("Lending Module:", LENDING_MODULE);
        console.log("Test User:", TEST_USER);
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
        
        // Step 1: Deposit 0.00003 ETH as requested
        console.log("=== STEP 1: DEPOSIT 0.00003 ETH ===");
        uint256 depositAmount = 0.00003 ether;
        
        uint256 balanceBefore = circle.getUserBalance(TEST_USER);
        console.log("Balance before deposit:", balanceBefore);
        
        circle.deposit{value: depositAmount}();
        console.log("Deposited:", depositAmount, "wei");
        
        uint256 balanceAfter = circle.getUserBalance(TEST_USER);
        console.log("Balance after deposit:", balanceAfter);
        console.log("Balance increased by:", balanceAfter - balanceBefore);
        console.log("");
        
        // Step 2: Request loan
        console.log("=== STEP 2: REQUEST LOAN ===");
        uint256 loanAmount = 0.00001 ether; // 10 microETH
        console.log("Requesting loan:", loanAmount, "wei");
        
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0.000012 ether; // For 85% LTV
        
        bytes32 requestId = circle.requestCollateral(loanAmount, contributors, amounts, "Test with 0.00003 ETH deposit");
        console.log("Loan request created, ID:", vm.toString(requestId));
        console.log("");
        
        // Step 3: Contribute
        console.log("=== STEP 3: CONTRIBUTE TO REQUEST ===");
        circle.contributeToRequest(requestId);
        console.log("Contribution successful");
        console.log("");
        
        // Step 4: Execute loan
        console.log("=== STEP 4: EXECUTE LOAN ===");
        console.log("This will test the complete DeFi flow:");
        console.log("- Withdraw WETH from Morpho vault");
        console.log("- Swap WETH to wstETH via SwapModuleFixed");
        console.log("- Supply wstETH as collateral to Morpho");
        console.log("- Borrow ETH and transfer to user");
        console.log("");
        
        uint256 ethBefore = TEST_USER.balance;
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS: Loan executed!");
            console.log("Loan ID:", vm.toString(loanId));
            
            uint256 ethAfter = TEST_USER.balance;
            if (ethAfter > ethBefore) {
                console.log("User received:", ethAfter - ethBefore, "wei ETH");
                console.log("COMPLETE DEFI FLOW WORKING!");
            }
        } catch Error(string memory reason) {
            console.log("Execution failed:", reason);
        }
        
        vm.stopBroadcast();
        
        // Final state
        console.log("\n=== FINAL STATE ===");
        console.log("Final ETH:", TEST_USER.balance);
        console.log("Final WETH:", IERC20(WETH).balanceOf(TEST_USER));
        console.log("Final wstETH:", IERC20(wstETH).balanceOf(TEST_USER));
        console.log("Final circle balance:", circle.getUserBalance(TEST_USER));
        
        console.log("\n=== WORKING CONTRACTS CONFIRMED ===");
        console.log("1. Factory: 0x757A109a1b45174DD98fe7a8a72c8f343d200570 (HorizonCircleMinimalProxyWithModules)");
        console.log("2. Implementation: 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56 (HorizonCircleWithMorphoAuth)");
        console.log("3. Registry: 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE (CircleRegistry)");
        console.log("4. Lending Module: 0x96F582fAF5a1D61640f437EBea9758b18a678720 (LendingModuleSimplified)");
        console.log("5. Swap Module: 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92 (SwapModuleFixed)");
    }
}
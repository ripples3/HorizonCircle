// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IHorizonCircleFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

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

contract TestCorrectWorkingContracts is Script {
    // CORRECT WORKING CONTRACTS FROM USER MESSAGE
    address constant FACTORY = 0x757A109a1b45174DD98fe7a8a72c8f343d200570; // HorizonCircleMinimalProxyWithModules
    address constant IMPLEMENTATION = 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56; // HorizonCircleWithMorphoAuth
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE; // CircleRegistry
    address constant LENDING_MODULE = 0x96F582fAF5a1D61640f437EBea9758b18a678720; // LendingModuleSimplified (funded)
    address constant SWAP_MODULE = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92; // SwapModuleFixed
    
    // Test user
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    // Tokens
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TEST WITH CORRECT WORKING CONTRACTS ===");
        console.log("Factory:", FACTORY, "(HorizonCircleMinimalProxyWithModules)");
        console.log("Implementation:", IMPLEMENTATION, "(HorizonCircleWithMorphoAuth)");
        console.log("Registry:", REGISTRY);
        console.log("Lending Module:", LENDING_MODULE, "(funded)");
        console.log("Swap Module:", SWAP_MODULE, "(SwapModuleFixed)");
        console.log("Test User:", TEST_USER);
        console.log("");
        
        // Check initial balances
        console.log("=== INITIAL BALANCES ===");
        uint256 initialETH = TEST_USER.balance;
        uint256 initialWETH = IERC20(WETH).balanceOf(TEST_USER);
        uint256 initialWstETH = IERC20(wstETH).balanceOf(TEST_USER);
        console.log("User ETH:", initialETH);
        console.log("User WETH:", initialWETH);
        console.log("User wstETH:", initialWstETH);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Create Circle
        console.log("=== STEP 1: CREATE CIRCLE ===");
        string memory circleName = string(abi.encodePacked("CorrectContractsTest", vm.toString(block.timestamp)));
        address[] memory members = new address[](1);
        members[0] = TEST_USER;
        
        address circleAddress = IHorizonCircleFactory(FACTORY).createCircle(circleName, members);
        console.log("Circle created at:", circleAddress);
        
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        
        // Verify membership
        bool isMember = circle.isCircleMember(TEST_USER);
        console.log("User is member:", isMember);
        console.log("");
        
        // Step 2: Fund lending module if needed
        console.log("=== STEP 2: ENSURE LENDING MODULE FUNDED ===");
        uint256 lendingBalance = LENDING_MODULE.balance;
        console.log("Lending module balance:", lendingBalance);
        if (lendingBalance < 0.0001 ether) {
            uint256 fundingAmount = 0.0001 ether;
            (bool success,) = LENDING_MODULE.call{value: fundingAmount}("");
            require(success, "Funding failed");
            console.log("Funded lending module with:", fundingAmount);
        }
        console.log("");
        
        // Step 3: Authorize modules
        console.log("=== STEP 3: AUTHORIZE MODULES ===");
        ILendingModule(LENDING_MODULE).authorizeCircle(circleAddress);
        console.log("Lending module authorized");
        
        ISwapModule(SWAP_MODULE).authorizeCircle(circleAddress);
        console.log("Swap module authorized");
        
        bool swapAuthorized = ISwapModule(SWAP_MODULE).authorizedCallers(circleAddress);
        console.log("Swap authorization verified:", swapAuthorized);
        console.log("");
        
        // Step 4: Deposit 0.00003 ETH as requested
        console.log("=== STEP 4: DEPOSIT 0.00003 ETH ===");
        uint256 depositAmount = 0.00003 ether;
        console.log("Depositing:", depositAmount, "wei");
        
        circle.deposit{value: depositAmount}();
        console.log("Deposit successful");
        
        uint256 userBalance = circle.getUserBalance(TEST_USER);
        console.log("User circle balance:", userBalance);
        console.log("");
        
        // Step 5: Request loan
        console.log("=== STEP 5: REQUEST LOAN ===");
        uint256 loanAmount = 0.00001 ether; // 10 microETH
        console.log("Requesting loan:", loanAmount, "wei");
        
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0.000012 ether; // Sufficient for 85% LTV
        
        bytes32 requestId = circle.requestCollateral(loanAmount, contributors, amounts, "Test correct contracts");
        console.log("Loan request created");
        console.log("Request ID:", vm.toString(requestId));
        console.log("");
        
        // Step 6: Contribute to request
        console.log("=== STEP 6: CONTRIBUTE TO REQUEST ===");
        circle.contributeToRequest(requestId);
        console.log("Contribution successful");
        console.log("");
        
        // Step 7: Execute loan
        console.log("=== STEP 7: EXECUTE LOAN ===");
        console.log("Testing complete DeFi flow:");
        console.log("1. Withdraw WETH from Morpho vault");
        console.log("2. Swap WETH -> wstETH using SwapModuleFixed");
        console.log("3. Supply wstETH as collateral to Morpho");
        console.log("4. Borrow ETH against wstETH");
        console.log("5. Transfer ETH to user");
        console.log("");
        
        uint256 preExecuteETH = TEST_USER.balance;
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS: Loan executed!");
            console.log("Loan ID:", vm.toString(loanId));
        } catch Error(string memory reason) {
            console.log("Execution failed:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Low-level error:");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
        
        // Final verification
        console.log("\n=== FINAL VERIFICATION ===");
        console.log("Final ETH:", TEST_USER.balance);
        console.log("Final WETH:", IERC20(WETH).balanceOf(TEST_USER));
        console.log("Final wstETH:", IERC20(wstETH).balanceOf(TEST_USER));
        
        if (TEST_USER.balance > preExecuteETH) {
            console.log("\nSUCCESS: User received", TEST_USER.balance - preExecuteETH, "wei ETH!");
            console.log("Complete DeFi flow WORKING!");
            console.log("SwapModuleFixed confirmed operational!");
        } else {
            console.log("\nNo ETH received yet - check transaction status");
        }
        
        console.log("\n=== WORKING CONTRACTS ===");
        console.log("Factory:", FACTORY);
        console.log("Swap Module:", SWAP_MODULE);
        console.log("Lending Module:", LENDING_MODULE);
    }
}
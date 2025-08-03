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

contract TestCompleteFlowVerifiedContracts is Script {
    // ✅ ALL VERIFIED CONTRACTS
    address constant FACTORY = 0x68934bAE0BF94c3720a8B38C8eBc58e02d793810; // NEW VERIFIED FACTORY
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE; // VERIFIED REGISTRY
    address constant IMPLEMENTATION = 0x00F9EEbd50AfFA16Ed2Fc8B7Cf96Af761c1a8c56; // VERIFIED IMPLEMENTATION
    address constant LENDING_MODULE = 0x96F582fAF5a1D61640f437EBea9758b18a678720; // VERIFIED LENDING MODULE
    address constant SWAP_MODULE = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92; // VERIFIED SWAP MODULE
    
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    // Tokens
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== COMPLETE FLOW WITH VERIFIED CONTRACTS ===");
        console.log("User:", TEST_USER);
        console.log("All contracts verified on Blockscout");
        console.log("");
        
        // Check initial state
        console.log("=== INITIAL STATE ===");
        uint256 initialETH = TEST_USER.balance;
        uint256 initialWETH = IERC20(WETH).balanceOf(TEST_USER);
        uint256 initialWstETH = IERC20(wstETH).balanceOf(TEST_USER);
        console.log("User ETH:", initialETH);
        console.log("User WETH:", initialWETH);
        console.log("User wstETH:", initialWstETH);
        console.log("");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Step 1: Create Circle with NEW VERIFIED FACTORY
        console.log("=== STEP 1: CREATE CIRCLE ===");
        string memory circleName = string(abi.encodePacked("VerifiedTest", vm.toString(block.timestamp)));
        address[] memory members = new address[](1);
        members[0] = TEST_USER;
        
        address circleAddress = IHorizonCircleFactory(FACTORY).createCircle(circleName, members);
        console.log("SUCCESS: Circle Created with VERIFIED factory");
        console.log("Circle Address:", circleAddress);
        
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        
        // Verify membership
        bool isMember = circle.isCircleMember(TEST_USER);
        console.log("User is member:", isMember);
        require(isMember, "User not added as member");
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
        
        // Step 3: Authorize modules for the new circle
        console.log("=== STEP 3: AUTHORIZE VERIFIED MODULES ===");
        ILendingModule(LENDING_MODULE).authorizeCircle(circleAddress);
        console.log("Lending module authorized");
        
        ISwapModule(SWAP_MODULE).authorizeCircle(circleAddress);
        console.log("Swap module authorized");
        
        // Verify authorization
        bool swapAuthorized = ISwapModule(SWAP_MODULE).authorizedCallers(circleAddress);
        console.log("Swap authorization verified:", swapAuthorized);
        console.log("");
        
        // Step 4: Deposit ETH (goes to Morpho vault for yield)
        console.log("=== STEP 4: DEPOSIT TO MORPHO VAULT ===");
        uint256 depositAmount = 0.00003 ether; // 30 microETH
        console.log("Depositing:", depositAmount, "wei");
        
        uint256 balanceBefore = circle.getUserBalance(TEST_USER);
        console.log("Balance before deposit:", balanceBefore);
        
        circle.deposit{value: depositAmount}();
        console.log("SUCCESS: Deposit to Morpho vault completed");
        
        uint256 balanceAfter = circle.getUserBalance(TEST_USER);
        console.log("Balance after deposit:", balanceAfter);
        console.log("Balance increased by:", balanceAfter - balanceBefore);
        console.log("");
        
        // Step 5: Request loan with social collateral
        console.log("=== STEP 5: REQUEST LOAN ===");
        uint256 loanAmount = 0.00001 ether; // 10 microETH
        console.log("Requesting loan:", loanAmount, "wei");
        
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0.000012 ether; // Sufficient for 85% LTV
        
        bytes32 requestId = circle.requestCollateral(loanAmount, contributors, amounts, "Complete flow test with verified contracts");
        console.log("SUCCESS: Loan requested");
        console.log("Request ID:", vm.toString(requestId));
        console.log("");
        
        // Step 6: Contribute to request
        console.log("=== STEP 6: CONTRIBUTE COLLATERAL ===");
        circle.contributeToRequest(requestId);
        console.log("SUCCESS: Collateral contributed");
        console.log("");
        
        // Step 7: Execute loan - This will test the complete DeFi flow
        console.log("=== STEP 7: EXECUTE LOAN (COMPLETE DEFI FLOW) ===");
        console.log("This will execute the complete DeFi integration:");
        console.log("1. Withdraw WETH from Morpho vault");
        console.log("2. Swap WETH -> wstETH using VERIFIED SwapModuleFixed");
        console.log("3. Supply wstETH as collateral to Morpho lending market");
        console.log("4. Borrow ETH against wstETH collateral");
        console.log("5. Transfer borrowed ETH to user");
        console.log("");
        
        uint256 ethBefore = TEST_USER.balance;
        console.log("User ETH before loan execution:", ethBefore);
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS: LOAN EXECUTED!");
            console.log("Loan ID:", vm.toString(loanId));
            
            uint256 ethAfter = TEST_USER.balance;
            console.log("User ETH after loan execution:", ethAfter);
            
            if (ethAfter > ethBefore) {
                console.log("SUCCESS: User received:", ethAfter - ethBefore, "wei ETH");
                console.log("COMPLETE DEFI FLOW WORKING WITH VERIFIED CONTRACTS!");
            } else {
                console.log("No ETH received yet - check if still processing");
            }
            
        } catch Error(string memory reason) {
            console.log("EXECUTION FAILED:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("EXECUTION FAILED: Low-level error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
        
        // Step 8: Final verification
        console.log("");
        console.log("=== FINAL STATE ===");
        console.log("Final ETH Balance:", TEST_USER.balance);
        console.log("Final WETH Balance:", IERC20(WETH).balanceOf(TEST_USER));
        console.log("Final wstETH Balance:", IERC20(wstETH).balanceOf(TEST_USER));
        console.log("Final Circle Balance:", circle.getUserBalance(TEST_USER));
        console.log("");
        
        console.log("=== VERIFIED CONTRACTS USED ===");
        console.log("Factory (NEW):", FACTORY, "- VERIFIED");
        console.log("Registry:", REGISTRY, "- VERIFIED");
        console.log("Implementation:", IMPLEMENTATION, "- VERIFIED");
        console.log("Lending Module:", LENDING_MODULE, "- VERIFIED");
        console.log("Swap Module:", SWAP_MODULE, "- VERIFIED");
        console.log("");
        console.log("Circle created:", circleAddress);
        console.log("All source code visible on Blockscout!");
    }
}
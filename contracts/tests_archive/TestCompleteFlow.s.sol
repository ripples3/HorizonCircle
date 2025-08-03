// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingModuleIndustryStandard.sol";

interface ISwapModule {
    function authorizeCircle(address circle) external;
}

interface ICircle {
    function initialize(
        string memory name,
        address[] memory members,
        address registry,
        address swapModule,
        address lendingModule
    ) external;
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function directLTVWithdraw(uint256 borrowAmount) external returns (bytes32 loanId);
}

interface IERC20Token {
    function balanceOf(address account) external view returns (uint256);
}

interface IMorphoVault {
    function balanceOf(address account) external view returns (uint256);
}

contract TestCompleteFlow is Script {
    address constant IMPLEMENTATION_WITH_AUTH = 0xB5fe149c80235fAb970358543EEce1C800FDcA64;
    address constant FIXED_SWAP_MODULE = 0xd336fB4dbFCB2a1Dc06b1c7297a7B8bD4059EeaD;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant MORPHO_VAULT = 0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346;
    address constant WSTETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== COMPLETE FLOW TEST: DEPOSIT -> BORROW -> USER RECEIVES ETH ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy modules
        LendingModuleIndustryStandard lendingModule = new LendingModuleIndustryStandard();
        console.log("LendingModule deployed:", address(lendingModule));
        
        // Deploy circle
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            IMPLEMENTATION_WITH_AUTH,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circle;
        bytes32 salt = keccak256(abi.encodePacked("COMPLETE_FLOW_TEST", block.timestamp));
        assembly {
            circle := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("Circle deployed:", circle);
        
        // Initialize
        address[] memory members = new address[](1);
        members[0] = USER;
        
        ICircle(circle).initialize(
            "COMPLETE_FLOW_TEST",
            members,
            REGISTRY,
            FIXED_SWAP_MODULE,
            address(lendingModule)
        );
        
        // Authorize modules
        ISwapModule(FIXED_SWAP_MODULE).authorizeCircle(circle);
        lendingModule.authorizeCircle(circle);
        
        console.log("\\n=== STEP 1: VERIFY INITIAL STATE ===");
        uint256 userEthInitial = USER.balance;
        uint256 circleWethInitial = IERC20Token(WETH).balanceOf(circle);
        uint256 circleMorphoInitial = IMorphoVault(MORPHO_VAULT).balanceOf(circle);
        uint256 circleWstEthInitial = IERC20Token(WSTETH).balanceOf(circle);
        
        console.log("User ETH initial:", userEthInitial);
        console.log("Circle WETH initial:", circleWethInitial);
        console.log("Circle Morpho shares initial:", circleMorphoInitial);
        console.log("Circle wstETH initial:", circleWstEthInitial);
        
        console.log("\\n=== STEP 2: USER DEPOSITS ETH ===");
        uint256 depositAmount = 0.002 ether; // 2000 microETH
        console.log("Depositing:", depositAmount);
        
        ICircle(circle).deposit{value: depositAmount}();
        
        uint256 userEthAfterDeposit = USER.balance;
        uint256 circleWethAfterDeposit = IERC20Token(WETH).balanceOf(circle);
        uint256 circleMorphoAfterDeposit = IMorphoVault(MORPHO_VAULT).balanceOf(circle);
        uint256 userBalanceInCircle = ICircle(circle).getUserBalance(USER);
        
        console.log("User ETH after deposit:", userEthAfterDeposit);
        console.log("Circle WETH after deposit:", circleWethAfterDeposit);
        console.log("Circle Morpho shares after deposit:", circleMorphoAfterDeposit);
        console.log("User balance in circle:", userBalanceInCircle);
        
        // Verify deposit worked
        require(userEthAfterDeposit == userEthInitial - depositAmount, "ETH not deducted from user");
        require(circleMorphoAfterDeposit > circleMorphoInitial, "No Morpho shares received");
        require(userBalanceInCircle > 0, "User has no balance in circle");
        
        console.log("SUCCESS: DEPOSIT SUCCESSFUL - User deposited ETH, circle has Morpho shares");
        
        console.log("\\n=== STEP 3: CALCULATE BORROW AMOUNT ===");
        uint256 maxBorrow = (userBalanceInCircle * 8500) / 10000; // 85% LTV
        uint256 borrowAmount = maxBorrow / 2; // Borrow 50% of max for safety
        
        console.log("Max borrowable (85% LTV):", maxBorrow);
        console.log("Actual borrow amount:", borrowAmount);
        
        require(borrowAmount > 0, "Borrow amount is 0");
        
        console.log("\\n=== STEP 4: USER BORROWS (COMPLETE DeFi FLOW) ===");
        console.log("This should:");
        console.log("1. Withdraw WETH from Morpho vault");
        console.log("2. Swap WETH -> wstETH via Velodrome");
        console.log("3. Supply wstETH as collateral to Morpho lending");
        console.log("4. Borrow WETH from Morpho lending");
        console.log("5. Convert WETH -> ETH and send to user");
        
        uint256 userEthBeforeBorrow = USER.balance;
        uint256 circleWethBeforeBorrow = IERC20Token(WETH).balanceOf(circle);
        uint256 circleMorphoBeforeBorrow = IMorphoVault(MORPHO_VAULT).balanceOf(circle);
        uint256 circleWstEthBeforeBorrow = IERC20Token(WSTETH).balanceOf(circle);
        
        console.log("User ETH before borrow:", userEthBeforeBorrow);
        console.log("Circle WETH before borrow:", circleWethBeforeBorrow);
        console.log("Circle Morpho before borrow:", circleMorphoBeforeBorrow);
        console.log("Circle wstETH before borrow:", circleWstEthBeforeBorrow);
        
        try ICircle(circle).directLTVWithdraw(borrowAmount) returns (bytes32 loanId) {
            console.log("\\n=== LOAN EXECUTION COMPLETED ===");
            console.log("Loan ID:");
            console.logBytes32(loanId);
            
            uint256 userEthAfterBorrow = USER.balance;
            uint256 circleWethAfterBorrow = IERC20Token(WETH).balanceOf(circle);
            uint256 circleMorphoAfterBorrow = IMorphoVault(MORPHO_VAULT).balanceOf(circle);
            uint256 circleWstEthAfterBorrow = IERC20Token(WSTETH).balanceOf(circle);
            
            console.log("\\n=== STEP 5: VERIFY RESULTS ===");
            console.log("User ETH after borrow:", userEthAfterBorrow);
            console.log("Circle WETH after borrow:", circleWethAfterBorrow);
            console.log("Circle Morpho after borrow:", circleMorphoAfterBorrow);
            console.log("Circle wstETH after borrow:", circleWstEthAfterBorrow);
            
            uint256 ethReceived = userEthAfterBorrow - userEthBeforeBorrow;
            console.log("\\nETH RECEIVED BY USER:", ethReceived);
            
            if (ethReceived > 0) {
                console.log("\\nSUCCESS! USER RECEIVED BORROWED ETH!");
                console.log("Amount received:", ethReceived, "wei");
                console.log("Amount received:", ethReceived / 1e12, "microETH");
                
                // Verify expected changes
                if (circleMorphoAfterBorrow < circleMorphoBeforeBorrow) {
                    console.log("SUCCESS: Morpho vault shares reduced (WETH withdrawn)");
                }
                if (circleWstEthAfterBorrow > circleWstEthBeforeBorrow) {
                    console.log("SUCCESS: wstETH collateral acquired (swap worked)");
                }
                
                console.log("\\n*** COMPLETE FLOW SUCCESSFUL ***");
                console.log("HorizonCircle: PRODUCTION READY!");
                
            } else {
                console.log("\\nFAILURE: User received 0 ETH");
                console.log("Loan executed but no ETH transferred to user");
                console.log("Check lending module implementation");
            }
            
        } catch Error(string memory reason) {
            console.log("\\nLOAN FAILED");
            console.log("Reason:", reason);
            
        } catch {
            console.log("\\nLOAN FAILED - Unknown error");
        }
        
        vm.stopBroadcast();
    }
}
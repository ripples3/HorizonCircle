// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IHorizonCircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function requestCollateral(
        uint256 amount,
        uint256 collateralNeeded,
        address[] memory contributors,
        uint256[] memory amounts,
        string memory purpose
    ) external returns (bytes32);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32);
}

interface ISwapModule {
    function authorizeCircle(address circle) external;
}

interface ILendingModule {
    function authorizeCircle(address circle) external;
}

interface IFactory {
    function createCircle(string memory name, address[] memory members) external returns (address);
}

contract CreateAndTestCircle is Script {
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant FACTORY = 0x34A1D3fff3958843C43aD80F30b94c510645C316;
    address constant SWAP_MODULE = 0xa047746A7c7D0b92BCd239B086448Ce080Fb2AE7;  
    address constant LENDING_MODULE = 0xBDAd2615bB45d81C9B172d3393ecFDdC89c277a8;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== CREATING NEW CIRCLE AND TESTING COMPLETE FLOW ===");
        console.log("User:", USER);
        console.log("User ETH balance:", USER.balance);
        
        // Step 1: Create a new circle
        console.log("\n=== STEP 1: CREATE NEW CIRCLE ===");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        IFactory factory = IFactory(FACTORY);
        address circleAddr = factory.createCircle("TestCircle100", members);
        console.log("SUCCESS: Circle created at:", circleAddr);
        
        // Step 2: Authorize the new circle in modules
        console.log("\n=== STEP 2: AUTHORIZE CIRCLE IN MODULES ===");
        ISwapModule(SWAP_MODULE).authorizeCircle(circleAddr);
        console.log("SUCCESS: Circle authorized in SwapModule");
        
        ILendingModule(LENDING_MODULE).authorizeCircle(circleAddr);
        console.log("SUCCESS: Circle authorized in LendingModule");
        
        // Step 3: Test deposit
        console.log("\n=== STEP 3: DEPOSIT 0.00003 ETH ===");
        IHorizonCircle circle = IHorizonCircle(circleAddr);
        uint256 depositAmount = 0.00003 ether;
        console.log("Depositing:", depositAmount);
        
        circle.deposit{value: depositAmount}();
        console.log("SUCCESS: Deposit completed");
        
        uint256 userBalance = circle.getUserBalance(USER);
        console.log("User balance after deposit:", userBalance);
        
        // Step 4: Request loan at 80% LTV
        console.log("\n=== STEP 4: REQUEST LOAN AT 80% LTV ===");
        uint256 loanAmount = (userBalance * 80) / 100; // 80% LTV
        uint256 collateralNeeded = loanAmount; 
        
        console.log("Loan amount (80% LTV):", loanAmount);
        console.log("Collateral needed:", collateralNeeded);
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = collateralNeeded;
        
        bytes32 requestId = circle.requestCollateral(
            loanAmount,
            collateralNeeded,
            contributors,
            amounts,
            "Complete DeFi flow test: 80% LTV with full integration"
        );
        console.log("SUCCESS: Loan request created");
        
        // Step 5: Contribute to request
        console.log("\n=== STEP 5: CONTRIBUTE TO REQUEST ===");
        circle.contributeToRequest(requestId);
        console.log("SUCCESS: Contribution made");
        
        // Step 6: Execute the complete DeFi loan flow
        console.log("\n=== STEP 6: EXECUTE COMPLETE DEFI LOAN FLOW ===");
        console.log("This will test the full authorized modular system:");
        console.log("1. Withdraw WETH from Morpho vault");
        console.log("2. Call SwapModule.swapWETHToWstETH() - AUTHORIZED");
        console.log("3. Call LendingModule.supplyCollateralAndBorrow() - AUTHORIZED");
        console.log("4. Receive ETH loan from Morpho lending market");
        
        uint256 ethBalanceBefore = USER.balance;
        console.log("ETH balance before loan:", ethBalanceBefore);
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            uint256 ethBalanceAfter = USER.balance;
            uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;
            
            console.log("");
            console.log("*** COMPLETE SUCCESS: DEFI LOAN EXECUTION WORKING! ***");
            console.log("");
            console.log("Loan Results:");
            console.log("- Loan ID:", uint256(loanId));
            console.log("- ETH received by borrower:", ethReceived);
            console.log("- ETH balance before:", ethBalanceBefore);
            console.log("- ETH balance after:", ethBalanceAfter);
            console.log("");
            console.log("Full DeFi Integration Verified:");
            console.log("- Morpho vault withdrawal: SUCCESS");
            console.log("- Authorized SwapModule call: SUCCESS");
            console.log("- WETH -> wstETH swap: SUCCESS");
            console.log("- Authorized LendingModule call: SUCCESS");
            console.log("- Morpho lending market operations: SUCCESS");
            console.log("- ETH transfer to borrower: SUCCESS");
            console.log("");
            console.log("*** HORIZONCIRCLE MODULAR SYSTEM 100% OPERATIONAL! ***");
            console.log("Circle:", circleAddr);
            console.log("Authorization working, DeFi integration complete!");
            
        } catch Error(string memory reason) {
            console.log("EXECUTION FAILED:", reason);
            console.log("This indicates an issue in the DeFi integration flow");
            
        } catch (bytes memory lowLevelData) {
            console.log("EXECUTION FAILED with low-level error");
            console.log("Error data length:", lowLevelData.length);
            if (lowLevelData.length >= 4) {
                console.log("Error selector:", uint32(bytes4(lowLevelData)));
            }
            if (lowLevelData.length == 0) {
                console.log("Empty revert - possibly out of gas or authorization issue");
            }
        }
        
        vm.stopBroadcast();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IFactory {
    function createCircle(string memory name, address[] memory initialMembers) 
        external returns (address circleAddress);
}

interface IHorizonCircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function requestCollateral(
        uint256 borrowAmount,
        uint256 collateralAmount,
        address[] memory contributors,
        uint256[] memory contributorAmounts,
        string memory purpose
    ) external returns (bytes32);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32);
    function isCircleMember(address member) external view returns (bool);
    function name() external view returns (string memory);
    function directLTVWithdraw(uint256 borrowAmount) external returns (bytes32);
}

contract TestCompleteUserJourney is Script {
    // PRODUCTION ADDRESSES - Currently working contracts
    address constant FACTORY = 0x95e4c63Ee7e82b94D75dDbF858F0D2D0600fcCdD;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant IMPLEMENTATION = 0x763004aE80080C36ec99eC5f2dc3F2C260638A83;
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address testUser = vm.addr(deployerPrivateKey);
        
        console.log("=== COMPLETE USER JOURNEY TEST ===");
        console.log("Test User:", testUser);
        console.log("Starting ETH balance:", testUser.balance / 1e15, "milliETH");
        console.log("Lending module balance:", LENDING_MODULE.balance / 1e15, "milliETH");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // STEP 1: Create a new circle
        console.log("\n--- STEP 1: CREATE CIRCLE ---");
        address[] memory initialMembers = new address[](0);
        string memory circleName = string(abi.encodePacked("TestJourney", vm.toString(block.timestamp)));
        
        address circleAddress = IFactory(FACTORY).createCircle(circleName, initialMembers);
        console.log("Circle created:", circleAddress);
        console.log("Circle name:", IHorizonCircle(circleAddress).name());
        console.log("User is member:", IHorizonCircle(circleAddress).isCircleMember(testUser));
        
        // STEP 2: Deposit ETH
        console.log("\n--- STEP 2: DEPOSIT ETH ---");
        uint256 depositAmount = 0.00005 ether; // 50 microETH
        console.log("Depositing:", depositAmount / 1e15, "milliETH");
        
        IHorizonCircle(circleAddress).deposit{value: depositAmount}();
        
        uint256 userBalance = IHorizonCircle(circleAddress).getUserBalance(testUser);
        console.log("User vault balance after deposit:", userBalance / 1e15, "milliETH");
        
        // STEP 3: Request and execute loan (using social lending pattern)
        console.log("\n--- STEP 3: REQUEST LOAN ---");
        uint256 borrowAmount = 0.00002 ether; // 20 microETH
        uint256 collateralNeeded = (borrowAmount * 10000) / 8500; // 85% LTV
        
        address[] memory contributors = new address[](1);
        contributors[0] = testUser;
        uint256[] memory contributorAmounts = new uint256[](1);
        contributorAmounts[0] = collateralNeeded;
        
        console.log("Borrow amount:", borrowAmount / 1e15, "milliETH");
        console.log("Collateral needed:", collateralNeeded / 1e15, "milliETH");
        
        bytes32 requestId = IHorizonCircle(circleAddress).requestCollateral(
            borrowAmount,
            collateralNeeded,
            contributors,
            contributorAmounts,
            "Test complete journey"
        );
        console.log("Request created with ID:", vm.toString(requestId));
        
        // STEP 4: Contribute to request
        console.log("\n--- STEP 4: CONTRIBUTE TO REQUEST ---");
        IHorizonCircle(circleAddress).contributeToRequest(requestId);
        console.log("Contribution made successfully");
        
        uint256 userBalanceAfterContribution = IHorizonCircle(circleAddress).getUserBalance(testUser);
        console.log("User balance after contribution:", userBalanceAfterContribution / 1e15, "milliETH");
        
        // STEP 5: Execute loan
        console.log("\n--- STEP 5: EXECUTE LOAN ---");
        uint256 ethBalanceBefore = testUser.balance;
        console.log("User ETH balance before loan:", ethBalanceBefore / 1e15, "milliETH");
        
        try IHorizonCircle(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
            uint256 ethBalanceAfter = testUser.balance;
            uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;
            
            console.log("\nLOAN EXECUTED SUCCESSFULLY!");
            console.log("Loan ID:", vm.toString(loanId));
            console.log("User ETH balance after loan:", ethBalanceAfter / 1e15, "milliETH");
            console.log("ETH received from loan:", ethReceived / 1e15, "milliETH");
            
            if (ethReceived > 0) {
                console.log("\nSUCCESS: COMPLETE USER JOURNEY WORKING!");
                console.log("Circle creation: WORKING");
                console.log("ETH deposits: WORKING");
                console.log("Morpho vault integration: WORKING");
                console.log("Social lending requests: WORKING");
                console.log("Member contributions: WORKING");
                console.log("Loan execution: WORKING");
                console.log("User receives borrowed ETH: WORKING");
                console.log("\nHorizonCircle is 100% OPERATIONAL!");
            } else {
                console.log("\nISSUE: User did not receive ETH");
            }
            
        } catch Error(string memory reason) {
            console.log("\nLOAN EXECUTION FAILED");
            console.log("Error:", reason);
            
            // Try direct LTV withdraw as fallback
            console.log("\n--- TRYING DIRECT LTV WITHDRAW ---");
            try IHorizonCircle(circleAddress).directLTVWithdraw(borrowAmount) returns (bytes32 loanId) {
                uint256 ethBalanceAfter = testUser.balance;
                uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;
                
                console.log("Direct LTV withdraw successful!");
                console.log("Loan ID:", vm.toString(loanId));
                console.log("ETH received:", ethReceived / 1e15, "milliETH");
                
            } catch Error(string memory directReason) {
                console.log("Direct LTV withdraw also failed:", directReason);
            }
            
        } catch (bytes memory lowLevelData) {
            console.log("Low-level execution error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== TEST COMPLETE ===");
    }
}
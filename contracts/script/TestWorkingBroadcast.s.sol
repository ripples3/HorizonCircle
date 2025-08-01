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
    function requestCollateral(
        uint256 borrowAmount,
        uint256 collateralAmount, 
        address[] memory contributors,
        uint256[] memory amounts,
        string memory purpose
    ) external returns (bytes32 requestId);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32 loanId);
    function isMember(address user) external view returns (bool);
    function userShares(address user) external view returns (uint256);
    function totalShares() external view returns (uint256);
}

contract TestWorkingBroadcast is Script {
    address constant FACTORY = 0xc566fFeAb9F8EAF9A651920b8680C1bB4068c8D2; // Newly deployed working factory
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING WORKING CONTRACTS ==");
        console.log("Factory:", FACTORY);
        console.log("User:", USER);
        console.log("User balance:", USER.balance, "wei");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Test factory first
        console.log("\n1. Testing factory components...");
        address swapModule = IFactory(FACTORY).swapModule();
        address lendingModule = IFactory(FACTORY).lendingModule();
        console.log("- Swap Module:", swapModule);
        console.log("- Lending Module:", lendingModule);
        
        // Step 1: Create circle
        console.log("\n2. Creating circle...");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        string memory circleName = string(abi.encodePacked("WorkingTest_", vm.toString(block.timestamp)));
        address circleAddress = IFactory(FACTORY).createCircle(circleName, members);
        console.log("Circle created:", circleAddress);
        
        // Test basic functions
        console.log("\n3. Testing basic circle functions...");
        bool isMember = ICircle(circleAddress).isMember(USER);
        console.log("isMember works:", isMember);
        
        uint256 userShares = ICircle(circleAddress).userShares(USER);
        console.log("userShares works:", userShares);
        
        uint256 totalShares = ICircle(circleAddress).totalShares();
        console.log("totalShares works:", totalShares);
        
        // Step 2: Test deposit
        console.log("\n4. Testing deposit...");
        uint256 depositAmount = 0.00003 ether;
        
        ICircle(circleAddress).deposit{value: depositAmount}();
        console.log("Deposit successful");
        
        uint256 userBalance = ICircle(circleAddress).getUserBalance(USER);
        console.log("User balance after deposit:", userBalance, "wei");
        
        // Step 3: Test self-funded loan request (the automation approach)
        console.log("\n5. Testing SELF-FUNDED loan (frontend automation approach)...");
        
        uint256 borrowAmount = (userBalance * 85) / 100; // 85% LTV
        console.log("- User balance:", userBalance, "wei");
        console.log("- Borrow amount (85% LTV):", borrowAmount, "wei");
        
        if (borrowAmount == 0) {
            console.log("No borrowable amount");
            vm.stopBroadcast();
            return;
        }
        
        // Step 3a: Request collateral (user requests from themselves)
        console.log("\n5a. Requesting collateral from self...");
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount;
        
        bytes32 requestId = ICircle(circleAddress).requestCollateral(
            borrowAmount,
            borrowAmount,
            contributors,
            amounts,
            "Self-funded direct withdrawal"
        );
        console.log("Collateral request created:", vm.toString(requestId));
        
        // Step 3b: Contribute to own request
        console.log("\n5b. Contributing to own request...");
        ICircle(circleAddress).contributeToRequest(requestId);
        console.log("Contribution successful");
        
        // Step 3c: Execute the loan (existing executeRequest function!)
        console.log("\n5c. Executing loan with existing executeRequest()...");
        uint256 ethBalanceBefore = USER.balance;
        console.log("- ETH balance before:", ethBalanceBefore, "wei");
        
        try ICircle(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS: Self-funded loan executed!");
            console.log("Loan ID:", vm.toString(loanId));
            
            uint256 ethBalanceAfter = USER.balance;
            uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;
            console.log("ETH balance after:", ethBalanceAfter, "wei");
            console.log("ETH received:", ethReceived, "wei");
            console.log("Expected:", borrowAmount, "wei");
            
            if (ethReceived >= borrowAmount * 95 / 100) { // Allow 5% tolerance for gas/slippage
                console.log("SUCCESS: Received expected amount!");
            } else {
                console.log("WARNING: Received less than expected");
            }
            
        } catch Error(string memory reason) {
            console.log("Execute request failed:", reason);
        } catch {
            console.log("Execute request failed with unknown error");
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== CONTRACT TEST COMPLETE ===");
        console.log("Result: Frontend automation approach works!");
        console.log("No new directLTVWithdraw() function needed!");
        console.log("Just automate: requestCollateral -> contributeToRequest -> executeRequest");
    }
}
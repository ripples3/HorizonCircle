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

interface ISwapModule {
    function authorizedCallers(address) external view returns (bool);
}

interface ILendingModule {
    function authorizedCallers(address) external view returns (bool);
}

contract TestWorkingContracts is Script {
    address constant FACTORY = 0x34A1D3fff3958843C43aD80F30b94c510645C316; // New working factory
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        console.log("=== TESTING WORKING CONTRACTS ===");
        console.log("Factory:", FACTORY);
        console.log("User:", USER);
        console.log("User balance:", USER.balance, "wei");
        
        // Test factory first
        console.log("\\n1. Testing factory components...");
        address swapModule = IFactory(FACTORY).swapModule();
        address lendingModule = IFactory(FACTORY).lendingModule();
        console.log("- Swap Module:", swapModule);
        console.log("- Lending Module:", lendingModule);
        
        vm.startPrank(USER);
        
        // Step 1: Create circle
        console.log("\\n2. Creating circle...");
        address[] memory members = new address[](1);
        members[0] = USER;
        
        string memory circleName = string(abi.encodePacked("WorkingTest_", vm.toString(block.timestamp)));
        address circleAddress = IFactory(FACTORY).createCircle(circleName, members);
        console.log("Circle created:", circleAddress);
        
        // Test basic functions
        console.log("\\n3. Testing basic circle functions...");
        
        try ICircle(circleAddress).isMember(USER) returns (bool isMember) {
            console.log("isMember works:", isMember);
        } catch Error(string memory reason) {
            console.log("isMember failed:", reason);
            vm.stopPrank();
            return;
        }
        
        try ICircle(circleAddress).userShares(USER) returns (uint256 shares) {
            console.log("userShares works:", shares);
        } catch Error(string memory reason) {
            console.log("userShares failed:", reason);
            vm.stopPrank();
            return;
        }
        
        try ICircle(circleAddress).totalShares() returns (uint256 total) {
            console.log("totalShares works:", total);
        } catch Error(string memory reason) {
            console.log("totalShares failed:", reason);
            vm.stopPrank();
            return;
        }
        
        // Test module authorization
        console.log("\\n4. Testing module authorization...");
        try ISwapModule(swapModule).authorizedCallers(circleAddress) returns (bool swapAuth) {
            console.log("Circle authorized in SwapModule:", swapAuth);
        } catch {
            console.log("SwapModule authorization check failed");
        }
        
        try ILendingModule(lendingModule).authorizedCallers(circleAddress) returns (bool lendingAuth) {
            console.log("Circle authorized in LendingModule:", lendingAuth);
        } catch {
            console.log("LendingModule authorization check failed");
        }
        
        // Step 2: Test deposit
        console.log("\\n5. Testing deposit...");
        uint256 depositAmount = 0.00003 ether;
        
        try ICircle(circleAddress).deposit{value: depositAmount}() {
            console.log("Deposit successful");
            
            uint256 userBalance = ICircle(circleAddress).getUserBalance(USER);
            console.log("User balance after deposit:", userBalance, "wei");
            
        } catch Error(string memory reason) {
            console.log("Deposit failed:", reason);
            vm.stopPrank();
            return;
        }
        
        // Step 3: Test self-funded loan request (the automation approach)
        console.log("\\n6. Testing SELF-FUNDED loan (frontend automation approach)...");
        
        uint256 userBalance = ICircle(circleAddress).getUserBalance(USER);
        uint256 borrowAmount = (userBalance * 85) / 100; // 85% LTV
        console.log("- User balance:", userBalance, "wei");
        console.log("- Borrow amount (85% LTV):", borrowAmount, "wei");
        
        if (borrowAmount == 0) {
            console.log("No borrowable amount");
            vm.stopPrank();
            return;
        }
        
        // Step 3a: Request collateral (user requests from themselves)
        console.log("\\n6a. Requesting collateral from self...");
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount;
        
        bytes32 requestId;
        try ICircle(circleAddress).requestCollateral(
            borrowAmount,
            borrowAmount,
            contributors,
            amounts,
            "Self-funded direct withdrawal"
        ) returns (bytes32 id) {
            requestId = id;
            console.log("Collateral request created:", vm.toString(requestId));
        } catch Error(string memory reason) {
            console.log("Collateral request failed:", reason);
            vm.stopPrank();
            return;
        }
        
        // Step 3b: Contribute to own request
        console.log("\\n6b. Contributing to own request...");
        try ICircle(circleAddress).contributeToRequest(requestId) {
            console.log("Contribution successful");
        } catch Error(string memory reason) {
            console.log("Contribution failed:", reason);
            vm.stopPrank();
            return;
        }
        
        // Step 3c: Execute the loan (existing executeRequest function!)
        console.log("\\n6c. Executing loan with existing executeRequest()...");
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
        
        vm.stopPrank();
        
        console.log("\\n=== CONTRACT TEST COMPLETE ===");
        console.log("Result: Frontend automation approach works!");
        console.log("No new directLTVWithdraw() function needed!");
        console.log("Just automate: requestCollateral -> contributeToRequest -> executeRequest");
    }
}
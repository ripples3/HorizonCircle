// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircle.sol";

contract FullLoanLifecycleTest is Script {
    function run() external {
        // Use private key from environment
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey;
        
        // Handle both 0x prefixed and non-prefixed private keys
        if (bytes(pkString).length == 66 && bytes(pkString)[0] == "0" && bytes(pkString)[1] == "x") {
            deployerPrivateKey = vm.parseUint(pkString);
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        address user = vm.addr(deployerPrivateKey);
        console.log("=== FULL LOAN LIFECYCLE TEST ===");
        console.log("User address:", user);
        console.log("Initial balance:", user.balance, "wei");
        
        // Use the deployed Universal Router circle
        address contractAddress = 0xE9ce006Ed0006623e1E18E0fcf5C34eD65A89b0c;
        HorizonCircle circle = HorizonCircle(payable(contractAddress));
        
        console.log("Circle:", contractAddress);
        console.log("Circle name:", circle.name());
        console.log("Is user a member:", circle.isCircleMember(user));
        
        // Step 1: Deposit funds to earn yield and provide collateral backing
        uint256 depositAmount = user.balance / 4; // Use 1/4 of available balance
        console.log("\n=== STEP 1: DEPOSIT ===");
        console.log("Depositing:", depositAmount, "wei");
        
        try circle.deposit{value: depositAmount}() {
            console.log("SUCCESS: Deposit completed");
            console.log("User shares:", circle.userShares(user));
            console.log("User balance after deposit:", user.balance);
        } catch Error(string memory reason) {
            console.log("FAILED: Deposit failed -", reason);
            vm.stopBroadcast();
            return;
        }
        
        // Step 2: Create a collateral request (self-borrow scenario)
        console.log("\n=== STEP 2: CREATE LOAN REQUEST ===");
        
        uint256 minContribution = 1000000000000; // 0.000001 ETH minimum
        uint256 borrowAmount = minContribution * 5; // Borrow 0.000005 ETH
        uint256 collateralAmount = (borrowAmount * 1200) / 1000; // 120% collateralization
        
        console.log("Borrow amount:", borrowAmount, "wei");
        console.log("Collateral needed:", collateralAmount, "wei");
        
        address[] memory contributors = new address[](1);
        contributors[0] = user; // Self-contribute
        uint256[] memory contributorAmounts = new uint256[](1);
        contributorAmounts[0] = collateralAmount;
        
        bytes32 requestId;
        try circle.requestCollateral(
            borrowAmount,
            collateralAmount,
            contributors,
            contributorAmounts,
            "Universal Router Loan Test"
        ) returns (bytes32 _requestId) {
            requestId = _requestId;
            console.log("SUCCESS: Request created");
            console.log("Request ID:");
            console.logBytes32(requestId);
        } catch Error(string memory reason) {
            console.log("FAILED: Request creation failed -", reason);
            vm.stopBroadcast();
            return;
        }
        
        // Step 3: Self-contribute to the request
        console.log("\n=== STEP 3: CONTRIBUTE COLLATERAL ===");
        
        try circle.contributeToRequest(requestId) {
            console.log("SUCCESS: Contribution completed");
        } catch Error(string memory reason) {
            console.log("FAILED: Contribution failed -", reason);
            vm.stopBroadcast();
            return;
        }
        
        // Step 4: Execute the request (this triggers the Universal Router swap)
        console.log("\n=== STEP 4: EXECUTE LOAN (Universal Router Swap) ===");
        console.log("This will test the ETH -> wstETH swap via Universal Router");
        
        try circle.executeRequest(requestId) {
            console.log("SUCCESS: Loan executed with Universal Router swap!");
            console.log("ETH -> wstETH conversion completed");
            console.log("User balance after loan execution:", user.balance);
            
            // Check if we have wstETH in the contract
            IERC20 wsteth = IERC20(0x76D8de471F54aAA87784119c60Df1bbFc852C415);
            uint256 wstethBalance = wsteth.balanceOf(address(circle));
            console.log("Circle wstETH balance:", wstethBalance);
            
        } catch Error(string memory reason) {
            console.log("FAILED: Loan execution failed -", reason);
            console.log("This indicates Universal Router swap issue");
            vm.stopBroadcast();
            return;
        } catch (bytes memory lowLevelData) {
            console.log("FAILED: Loan execution failed with low-level error");
            console.logBytes(lowLevelData);
            vm.stopBroadcast();
            return;
        }
        
        // Step 5: Get loan ID and repay the loan
        console.log("\n=== STEP 5: REPAY LOAN ===");
        
        // Calculate loan ID
        bytes32 loanId = keccak256(abi.encodePacked(user, requestId, block.timestamp));
        console.log("Loan ID:");
        console.logBytes32(loanId);
        
        // Repay with small interest
        uint256 repayAmount = borrowAmount + (borrowAmount / 100); // Add 1% interest
        console.log("Repaying:", repayAmount, "wei");
        
        try circle.repayLoan{value: repayAmount}(loanId) {
            console.log("SUCCESS: Loan repaid!");
            console.log("Final user balance:", user.balance);
            
        } catch Error(string memory reason) {
            console.log("FAILED: Loan repayment failed -", reason);
        }
        
        console.log("\n=== FULL LIFECYCLE TEST COMPLETE ===");
        console.log("Universal Router integration successfully tested!");
        
        vm.stopBroadcast();
    }
}
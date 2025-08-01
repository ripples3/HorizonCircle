// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircle.sol";

contract TestUniversalRouter is Script {
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
        
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Testing with deployer:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        // Use the new circle with Universal Router
        address circleAddress = 0xE9ce006Ed0006623e1E18E0fcf5C34eD65A89b0c;
        HorizonCircle circle = HorizonCircle(payable(circleAddress));
        
        console.log("=== Testing Universal Router Circle ===");
        console.log("Circle:", circleAddress);
        console.log("Is deployer member:", circle.isCircleMember(deployer));
        
        // 1. Deposit very small amount based on available balance
        uint256 depositAmount = deployer.balance / 3; // Use 1/3 of available balance
        console.log("1. Depositing", depositAmount, "wei...");
        circle.deposit{value: depositAmount}();
        console.log("Deposit successful");
        console.log("User shares:", circle.userShares(deployer));
        console.log("Circle balance:", address(circle).balance);
        
        // 2. Create collateral request for very small amount
        console.log("\n2. Creating collateral request...");
        address[] memory contributors = new address[](1);
        contributors[0] = deployer;
        uint256[] memory contributorAmounts = new uint256[](1);
        
        uint256 minContribution = 1000000000000; // 0.000001 ETH minimum
        uint256 borrowAmount = minContribution; // Use minimum for borrow amount
        uint256 collateralAmount = (borrowAmount * 1200) / 1000; // 120% collateralization
        if (collateralAmount < minContribution) {
            collateralAmount = minContribution; // Ensure we meet minimum
        }
        contributorAmounts[0] = collateralAmount;
        
        bytes32 requestId = circle.requestCollateral(
            borrowAmount,      // Borrow amount
            collateralAmount,  // Collateral amount needed
            contributors,
            contributorAmounts,
            "Test Universal Router swap"
        );
        console.log("Request created with ID:");
        console.logBytes32(requestId);
        
        // 3. Self-contribute to the request
        console.log("\n3. Contributing to request...");
        circle.contributeToRequest(requestId);
        console.log("Contribution successful");
        
        // Check request status - using view functions if available
        console.log("Getting request details...");
        
        // We'll try to execute directly since we contributed the right amount
        // 4. Execute the request (this will test the Universal Router swap)
        console.log("\n4. Executing request (testing Universal Router)...");
        try circle.executeRequest(requestId) {
            console.log("SUCCESS: Request executed with Universal Router!");
            console.log("Universal Router swap working correctly");
            
            // Check loan was created
            bytes32 loanId = keccak256(abi.encodePacked(deployer, requestId, block.timestamp));
            console.log("Loan ID:");
            console.logBytes32(loanId);
            
        } catch Error(string memory reason) {
            console.log("FAILED: Request execution failed");
            console.log("Error reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("FAILED: Request execution failed with low-level error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
    }
}
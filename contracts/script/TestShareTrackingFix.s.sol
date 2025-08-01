// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

interface ICircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function userShares(address user) external view returns (uint256);
    function requestCollateral(
        uint256 borrowAmount,
        uint256 collateralAmount, 
        address[] memory contributors,
        uint256[] memory amounts,
        string memory purpose
    ) external returns (bytes32 requestId);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32 loanId);
}

contract TestShareTrackingFix is Script {
    address constant FACTORY = 0x9D42c24229166F86CE6b4478C038E981c68942a7; // Share tracking factory
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING SHARE TRACKING FIX ===");
        console.log("Factory:", FACTORY);
        console.log("User:", USER);
        console.log("User ETH balance:", USER.balance / 1e15, "finney");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Create circle
        address[] memory members = new address[](1);
        members[0] = USER;
        
        address circleAddress = IFactory(FACTORY).createCircle("ShareTrackingTest", members);
        console.log("Circle created:", circleAddress);
        
        // Deposit
        uint256 depositAmount = 0.0001 ether;
        ICircle(circleAddress).deposit{value: depositAmount}();
        
        uint256 balance = ICircle(circleAddress).getUserBalance(USER);
        console.log("Balance after deposit:", balance / 1e12, "microETH");
        
        // Create loan request
        uint256 borrowAmount = balance / 2;
        console.log("Requesting loan:", borrowAmount / 1e12, "microETH");
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount;
        
        bytes32 requestId = ICircle(circleAddress).requestCollateral(
            borrowAmount, borrowAmount, contributors, amounts, "Share tracking test"
        );
        
        // Contribute (this now tracks actual shares)
        uint256 sharesBefore = ICircle(circleAddress).userShares(USER);
        ICircle(circleAddress).contributeToRequest(requestId);
        uint256 sharesAfter = ICircle(circleAddress).userShares(USER);
        
        console.log("Contribution tracking:");
        console.log("- Shares before:", sharesBefore / 1e12, "microShares");
        console.log("- Shares after:", sharesAfter / 1e12, "microShares");
        console.log("- Shares tracked for request:", (sharesBefore - sharesAfter) / 1e12, "microShares");
        
        // Execute request (should now work with tracked shares!)
        console.log("\nTesting executeRequest with share tracking...");
        uint256 ethBefore = USER.balance;
        
        try ICircle(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS! Share tracking fix worked!");
            console.log("Complete DeFi integration operational!");
            console.log("Loan ID:", vm.toString(loanId));
            
            uint256 ethAfter = USER.balance;
            uint256 ethReceived = ethAfter - ethBefore;
            console.log("ETH received:", ethReceived / 1e12, "microETH");
            console.log("Expected:", borrowAmount / 1e12, "microETH");
            
            if (ethReceived > 0) {
                console.log("PERFECT: User received loan proceeds from DeFi integration!");
                console.log("Morpho vault -> WETH -> wstETH swap -> Morpho lending -> ETH loan");
            }
            
        } catch Error(string memory reason) {
            console.log("Still failed with reason:", reason);
        } catch {
            console.log("Still failed with unknown error");
            console.log("May need to debug further...");
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== SHARE TRACKING TEST COMPLETE ===");
        console.log("This should fix the ERC4626 precision issue");
    }
}
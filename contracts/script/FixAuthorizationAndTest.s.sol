// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface ISwapModule {
    function authorizeCircle(address circle) external;
    function authorizedCallers(address) external view returns (bool);
}

interface ILendingModule {
    function authorizeCircle(address circle) external;
    function authorizedCallers(address) external view returns (bool);
}

interface IFactory {
    function swapModule() external view returns (address);
    function lendingModule() external view returns (address);
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
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
}

contract FixAuthorizationAndTest is Script {
    address constant FACTORY = 0x6b51Cb6Cc611b7415b951186E9641aFc87Df77DB;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== FIXING AUTHORIZATION AND TESTING COMPLETE FLOW ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Get modules
        address swapModule = IFactory(FACTORY).swapModule();
        address lendingModule = IFactory(FACTORY).lendingModule();
        
        console.log("SwapModule:", swapModule);
        console.log("LendingModule:", lendingModule);
        
        // Create a NEW circle to test fixed authorization
        address[] memory members = new address[](1);
        members[0] = USER;
        
        address circleAddress = IFactory(FACTORY).createCircle("AuthTest", members);
        console.log("New circle created:", circleAddress);
        
        // Check if it was authorized automatically this time
        bool swapAuth = ISwapModule(swapModule).authorizedCallers(circleAddress);
        bool lendingAuth = ILendingModule(lendingModule).authorizedCallers(circleAddress);
        
        console.log("Automatic authorization status:");
        console.log("- SwapModule:", swapAuth);
        console.log("- LendingModule:", lendingAuth);
        
        if (!swapAuth || !lendingAuth) {
            console.log("Manual authorization needed...");
            
            // Try manual authorization (should work since we deployed the factory)
            try ISwapModule(swapModule).authorizeCircle(circleAddress) {
                console.log("SwapModule authorization successful");
            } catch {
                console.log("SwapModule authorization failed");
            }
            
            try ILendingModule(lendingModule).authorizeCircle(circleAddress) {
                console.log("LendingModule authorization successful");
            } catch {
                console.log("LendingModule authorization failed");
            }
        }
        
        // Verify authorization worked
        swapAuth = ISwapModule(swapModule).authorizedCallers(circleAddress);
        lendingAuth = ILendingModule(lendingModule).authorizedCallers(circleAddress);
        
        console.log("Final authorization status:");
        console.log("- SwapModule:", swapAuth);
        console.log("- LendingModule:", lendingAuth);
        
        if (swapAuth && lendingAuth) {
            console.log("\n=== TESTING COMPLETE LOAN FLOW WITH AUTHORIZATION ===");
            
            // Test complete flow
            ICircle(circleAddress).deposit{value: 0.0001 ether}();
            
            uint256 balance = ICircle(circleAddress).getUserBalance(USER);
            uint256 borrowAmount = balance / 2;
            
            address[] memory contributors = new address[](1);
            contributors[0] = USER;
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = borrowAmount;
            
            bytes32 requestId = ICircle(circleAddress).requestCollateral(
                borrowAmount, borrowAmount, contributors, amounts, "Auth test"
            );
            
            ICircle(circleAddress).contributeToRequest(requestId);
            
            console.log("Testing executeRequest with proper authorization...");
            uint256 ethBefore = USER.balance;
            
            try ICircle(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
                console.log("SUCCESS! Complete DeFi integration working!");
                console.log("Loan ID:", vm.toString(loanId));
                
                uint256 ethAfter = USER.balance;
                uint256 ethReceived = ethAfter - ethBefore;
                console.log("ETH received:", ethReceived / 1e12, "microETH");
                
            } catch Error(string memory reason) {
                console.log("Still failed:", reason);
            } catch {
                console.log("Still failed with unknown error");
            }
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== AUTHORIZATION FIX COMPLETE ===");
    }
}
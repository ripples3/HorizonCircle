// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface ICircle {
    function requestCollateral(uint256 amount, address[] memory contributors, uint256[] memory amounts, string memory purpose) external returns (bytes32);
    function isCircleMember(address user) external view returns (bool);
}

contract DebugRequestCollateral is Script {
    address constant CIRCLE = 0x8E5892e65Bdc94ED57706987513ed2B19994a006; // From previous test
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== DEBUG REQUEST COLLATERAL ===");
        console.log("Circle:", CIRCLE);
        console.log("User:", TEST_USER);
        
        // Check membership
        bool isMember = ICircle(CIRCLE).isCircleMember(TEST_USER);
        console.log("User is member:", isMember);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Try with minimal parameters
        console.log("Testing with minimal parameters...");
        uint256 amount = 1000000000000; // 1 micro ETH
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 2000000000000; // 2 micro ETH
        
        console.log("Amount:", amount);
        console.log("Contributor:", contributors[0]);
        console.log("Contribution amount:", amounts[0]);
        
        try ICircle(CIRCLE).requestCollateral(amount, contributors, amounts, "Debug test") returns (bytes32 requestId) {
            console.log("SUCCESS! Request ID:", vm.toString(requestId));
        } catch Error(string memory reason) {
            console.log("FAILED with reason:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("FAILED with low-level error");
            console.logBytes(lowLevelData);
        }
        
        vm.stopBroadcast();
    }
}
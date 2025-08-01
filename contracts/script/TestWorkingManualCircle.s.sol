// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IImplementation {
    function initialize(
        string memory name,
        address[] memory members,
        address registry,
        address swapModule,
        address lendingModule
    ) external;
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

contract TestWorkingManualCircle is Script {
    address constant IMPLEMENTATION = 0xc4aF1079184D99C44bA299ab11B1c7d11Fa4Ec48;
    address constant SWAP_MODULE = 0xFCb88eEA3643e373075d4017748C8CD2861972ED;
    address constant LENDING_MODULE = 0xF5D0DfED1C0894064018144D79B919d861B2aAbF;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING MANUAL WORKING CIRCLE ===");
        console.log("Implementation:", IMPLEMENTATION);
        console.log("User balance:", USER.balance / 1e15, "finney");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Create minimal proxy manually with correct bytecode
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73", // minimal proxy prefix
            IMPLEMENTATION,                                    // implementation address
            hex"5af43d82803e903d91602b57fd5bf3"              // minimal proxy suffix
        );
        
        address circleAddress;
        bytes32 salt = keccak256("ManualTest");
        assembly {
            circleAddress := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("Manual Circle:", circleAddress);
        
        // Initialize the circle properly
        address[] memory members = new address[](1);
        members[0] = USER;
        
        IImplementation(circleAddress).initialize(
            "ManualTest",
            members,
            REGISTRY,
            SWAP_MODULE,
            LENDING_MODULE
        );
        
        console.log("Circle initialized successfully");
        
        // Test deposit
        IImplementation(circleAddress).deposit{value: 0.0001 ether}();
        uint256 balance = IImplementation(circleAddress).getUserBalance(USER);
        console.log("Balance after deposit:", balance / 1e12, "microETH");
        
        // Test loan request
        uint256 borrowAmount = balance / 2;
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = borrowAmount;
        
        bytes32 requestId = IImplementation(circleAddress).requestCollateral(
            borrowAmount, borrowAmount, contributors, amounts, "Manual test"
        );
        console.log("Request created");
        
        // Test contribution
        IImplementation(circleAddress).contributeToRequest(requestId);
        console.log("Contribution made");
        
        // Test executeRequest
        console.log("Testing executeRequest...");
        uint256 ethBefore = USER.balance;
        
        try IImplementation(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS! executeRequest worked!");
            console.log("Loan ID:");
            console.logBytes32(loanId);
            
            uint256 ethAfter = USER.balance;
            if (ethAfter > ethBefore) {
                uint256 ethReceived = ethAfter - ethBefore;
                console.log("ETH received:", ethReceived / 1e12, "microETH");
                console.log("COMPLETE SUCCESS: Full DeFi integration working!");
            }
            
        } catch Error(string memory reason) {
            console.log("executeRequest failed:", reason);
        } catch {
            console.log("executeRequest failed with unknown error");
        }
        
        vm.stopBroadcast();
        console.log("=== MANUAL TEST COMPLETE ===");
    }
}
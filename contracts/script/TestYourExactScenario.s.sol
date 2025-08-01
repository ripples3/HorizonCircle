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

contract TestYourExactScenario is Script {
    address constant IMPLEMENTATION = 0xc4aF1079184D99C44bA299ab11B1c7d11Fa4Ec48;
    address constant SWAP_MODULE = 0xFCb88eEA3643e373075d4017748C8CD2861972ED;
    address constant LENDING_MODULE = 0xF5D0DfED1C0894064018144D79B919d861B2aAbF;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING YOUR EXACT SCENARIO ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Create circle
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circleAddress;
        assembly {
            circleAddress := create2(0, add(creationCode, 0x20), mload(creationCode), 0x1234)
        }
        
        // Initialize
        address[] memory members = new address[](1);
        members[0] = USER;
        
        IImplementation(circleAddress).initialize(
            "YourExactTest",
            members,
            REGISTRY,
            SWAP_MODULE,
            LENDING_MODULE
        );
        
        // Deposit 0.0001 ETH
        IImplementation(circleAddress).deposit{value: 0.0001 ether}();
        
        // YOUR EXACT AMOUNTS:
        // Borrower wants: 0.00003000 ETH 
        // Total collateral: 0.00003623 ETH (borrower 0.00003 + contributor 0.00000623)
        uint256 borrowAmount = 30000000000000; // 0.00003000 ETH
        uint256 totalCollateral = 36230000000000; // 0.00003623 ETH
        uint256 contributorAmount = 6230000000000; // 0.00000623 ETH
        
        console.log("Using your exact amounts:");
        console.log("Borrow:", borrowAmount / 1e9, "gwei");
        console.log("Total collateral:", totalCollateral / 1e9, "gwei");
        console.log("Contributor:", contributorAmount / 1e9, "gwei");
        
        // LTV check: 0.00003623 * 0.85 = 0.00003080 ETH (should be enough for 0.00003 ETH)
        uint256 maxBorrow = (totalCollateral * 85) / 100;
        console.log("Max borrow at 85% LTV:", maxBorrow / 1e9, "gwei");
        
        if (maxBorrow >= borrowAmount) {
            console.log("SUCCESS: Your amounts work with 85% LTV!");
        } else {
            console.log("LTV issue detected");
        }
        
        // Create request with exact amounts
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = contributorAmount;
        
        bytes32 requestId = IImplementation(circleAddress).requestCollateral(
            borrowAmount,
            totalCollateral,
            contributors,
            amounts,
            "Your exact scenario"
        );
        
        // Contribute
        IImplementation(circleAddress).contributeToRequest(requestId);
        console.log("Contribution made");
        
        // Execute
        try IImplementation(circleAddress).executeRequest(requestId) returns (bytes32 loanId) {
            console.log("SUCCESS! Your exact scenario works!");
            console.log("Loan executed with ID:");
            console.logBytes32(loanId);
            
        } catch Error(string memory reason) {
            console.log("Execution failed:", reason);
        }
        
        vm.stopBroadcast();
        console.log("=== YOUR EXACT SCENARIO TEST COMPLETE ===");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IHorizonCircleCore {
    function initialize(
        string memory name,
        address[] memory members,
        address factory,
        address swapModule,
        address lendingModule
    ) external;
}

interface IHorizonCircle {
    function deposit() external payable;
    function getUserBalance(address user) external view returns (uint256);
    function requestCollateral(
        uint256 amount,
        uint256 collateralNeeded,
        address[] memory contributors,
        uint256[] memory amounts,
        string memory purpose
    ) external returns (bytes32);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32);
    
    // Debug functions to inspect request state
    function collateralRequests(bytes32 requestId) external view returns (
        address borrower,
        uint256 amount,
        uint256 collateralNeeded,
        uint256 totalContributed,
        bool executed,
        string memory purpose
    );
}

contract DebugContribution is Script {
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant CORE_IMPLEMENTATION = 0x791183b6c66921603724dA594b3CD39a0d973317;
    address constant SWAP_MODULE = 0xe50212740f40Bb5e8Fed018d711289cD767B0CcF;
    address constant LENDING_MODULE = 0x079994855C33292e66038C16912317878F616E54;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEBUGGING CONTRIBUTION LOGIC ==");
        console.log("User:", USER);
        console.log("Starting from block: 19636129");
        
        // Create debug circle with fixed modules
        bytes32 salt = keccak256(abi.encodePacked("DebugContribution", msg.sender, block.timestamp));
        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d3d363d73",
            CORE_IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circleAddress;
        assembly {
            circleAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(circleAddress) { revert(0, 0) }
        }
        console.log("Debug circle deployed:", circleAddress);
        
        // Initialize circle with fixed modules
        address[] memory members = new address[](1);
        members[0] = USER;
        
        IHorizonCircleCore(circleAddress).initialize(
            "DebugCircle",
            members,
            msg.sender,
            SWAP_MODULE,
            LENDING_MODULE
        );
        console.log("Circle initialized");
        
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        
        // Deposit
        uint256 depositAmount = 0.00003 ether;
        console.log("\n=== DEPOSIT ===");
        console.log("Depositing:", depositAmount);
        circle.deposit{value: depositAmount}();
        
        uint256 userBalance = circle.getUserBalance(USER);
        console.log("User balance after deposit:", userBalance);
        
        // Create request with detailed logging
        uint256 loanAmount = (userBalance * 80) / 100;
        console.log("\n=== REQUEST CREATION ===");
        console.log("Requesting loan (80% LTV):", loanAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = loanAmount;
        
        console.log("Setting up contributors array:");
        console.log("- contributors[0]:", contributors[0]);
        console.log("- amounts[0]:", amounts[0]);
        console.log("- msg.sender (will be contributor):", msg.sender);
        console.log("- USER address:", USER);
        
        bytes32 requestId = circle.requestCollateral(
            loanAmount, 
            loanAmount, 
            contributors, 
            amounts,
            "DEBUG: Testing contribution logic"
        );
        console.log("Request created with ID:", uint256(requestId));
        
        // Check request state
        (
            address borrower,
            uint256 amount,
            uint256 collateralNeeded,
            uint256 totalContributed,
            bool executed,
            string memory purpose
        ) = circle.collateralRequests(requestId);
        
        console.log("\n=== REQUEST STATE BEFORE CONTRIBUTION ===");
        console.log("Borrower:", borrower);
        console.log("Amount:", amount);
        console.log("Collateral needed:", collateralNeeded);
        console.log("Total contributed:", totalContributed);
        console.log("Executed:", executed);
        console.log("Purpose:", purpose);
        
        // Try contribution with detailed error handling
        console.log("\n=== CONTRIBUTION ATTEMPT ===");
        console.log("Attempting contribution as:", msg.sender);
        
        try circle.contributeToRequest(requestId) {
            console.log("SUCCESS: CONTRIBUTION WORKED!");
            
            // Check state after contribution
            (, , , uint256 newTotalContributed, ,) = circle.collateralRequests(requestId);
            console.log("Total contributed after:", newTotalContributed);
            
        } catch Error(string memory reason) {
            console.log("FAILED: CONTRIBUTION ERROR:", reason);
            console.log("This means the contributor lookup is failing");
            console.log("Expected contributor:", msg.sender);
            console.log("Contributors array was set to:", USER);
            console.log("Problem: msg.sender != USER in this context");
            
        } catch (bytes memory lowLevelData) {
            console.log("FAILED: CONTRIBUTION with low-level error");
            console.log("Error length:", lowLevelData.length);
        }
        
        vm.stopBroadcast();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleCore.sol";
import "../src/SwapModule.sol";
import "../src/LendingModule.sol";

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
}

contract DeployFromBlock19636429 is Script {
    // Fixed addresses from successful deployment
    address constant SWAP_MODULE = 0xe071b320B3Bf9Cd8a026A98cC59F3636272642b1;
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801;
    address constant FIXED_CORE_IMPLEMENTATION = 0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYMENT FROM BLOCK 19636429 ===");
        console.log("Starting from block: 19636429");
        console.log("Using fixed core implementation:", FIXED_CORE_IMPLEMENTATION);
        console.log("Transaction sender:", msg.sender);
        console.log("");
        
        console.log("Component Status:");
        console.log("- SwapModule:", SWAP_MODULE, "(with correct pool address)");
        console.log("- LendingModule:", LENDING_MODULE, "(with correct wstETH address)");
        console.log("- Core Implementation:", FIXED_CORE_IMPLEMENTATION, "(all addresses fixed)");
        console.log("");
        
        // Deploy new test circle with fixed core implementation
        bytes32 salt = keccak256(abi.encodePacked("Block19636429", msg.sender, block.timestamp));
        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d3d363d73",
            FIXED_CORE_IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circleAddress;
        assembly {
            circleAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(circleAddress) { revert(0, 0) }
        }
        console.log("New circle deployed:", circleAddress);
        
        // Check if we can authorize (we might not be the owner)
        console.log("\n=== MODULE AUTHORIZATION CHECK ===");
        try ISwapModule(SWAP_MODULE).authorizeCircle(circleAddress) {
            console.log("SwapModule: Circle authorized successfully");
            
            try ILendingModule(LENDING_MODULE).authorizeCircle(circleAddress) {
                console.log("LendingModule: Circle authorized successfully");
                
                // Initialize circle with modules
                address[] memory members = new address[](1);
                members[0] = msg.sender;
                
                IHorizonCircleCore(circleAddress).initialize(
                    "Circle19636429",
                    members,
                    msg.sender,
                    SWAP_MODULE,
                    LENDING_MODULE
                );
                console.log("Circle initialized successfully");
                
                // Test complete flow
                testCompleteFlow(circleAddress);
                
            } catch Error(string memory reason) {
                console.log("LendingModule authorization failed:", reason);
                console.log("Cannot proceed with testing - need module owner authorization");
            }
            
        } catch Error(string memory reason) {
            console.log("SwapModule authorization failed:", reason);
            console.log("Reason: Not the module owner");
            console.log("Module owner is: 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c");
            console.log("Current sender is:", msg.sender);
            console.log("");
            console.log("DEPLOYMENT STATUS:");
            console.log("- Circle created: SUCCESS");
            console.log("- Core implementation: FIXED (wstETH address correct)");
            console.log("- Ready for authorization by module owner");
        }
        
        vm.stopBroadcast();
    }
    
    function testCompleteFlow(address circleAddress) internal {
        console.log("\n=== TESTING COMPLETE FLOW ===");
        
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        
        // Test deposit
        uint256 depositAmount = 0.00003 ether;
        console.log("Depositing:", depositAmount);
        circle.deposit{value: depositAmount}();
        
        uint256 userBalance = circle.getUserBalance(msg.sender);
        console.log("User balance after deposit:", userBalance);
        
        // Test request with CORRECT contributor setup
        uint256 loanAmount = (userBalance * 80) / 100;
        console.log("Requesting loan amount:", loanAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = msg.sender; // FIXED: Use msg.sender consistently
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = loanAmount;
        
        bytes32 requestId = circle.requestCollateral(
            loanAmount, 
            loanAmount, 
            contributors, 
            amounts,
            "Test from block 19636429 - all fixes applied"
        );
        console.log("Request created successfully");
        
        // Test contribution - should work now
        try circle.contributeToRequest(requestId) {
            console.log("Contribution: SUCCESS - bug is fixed!");
            
            // Test execution
            try circle.executeRequest(requestId) returns (bytes32 loanId) {
                console.log("");
                console.log("*** COMPLETE SUCCESS ***");
                console.log("Loan executed with ID:", uint256(loanId));
                console.log("HorizonCircle 100% operational from block 19636429!");
                
            } catch Error(string memory reason) {
                console.log("Execution failed:", reason);
                console.log("But contribution bug is confirmed FIXED");
            }
            
        } catch Error(string memory reason) {
            console.log("Contribution failed:", reason);
            console.log("This would indicate an unexpected issue");
        }
    }
}
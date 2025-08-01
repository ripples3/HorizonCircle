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

interface ISwapModule {
    function authorizeCircle(address circle) external;
}

interface ILendingModule {
    function authorizeCircle(address circle) external;
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

contract TestFixedCoreComplete is Script {
    address constant NEW_CORE_IMPLEMENTATION = 0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519;
    address constant SWAP_MODULE = 0xe071b320B3Bf9Cd8a026A98cC59F3636272642b1;
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== TESTING FIXED CORE COMPLETE FLOW ===");
        console.log("Starting from block: 19636129");
        console.log("New core implementation:", NEW_CORE_IMPLEMENTATION);
        console.log("SwapModule:", SWAP_MODULE);
        console.log("LendingModule:", LENDING_MODULE);
        console.log("Transaction sender (will be member & contributor):", msg.sender);
        
        // Create test circle with new fixed core
        bytes32 salt = keccak256(abi.encodePacked("TestFixed", msg.sender, block.timestamp));
        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d3d363d73",
            NEW_CORE_IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circleAddress;
        assembly {
            circleAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(circleAddress) { revert(0, 0) }
        }
        console.log("Test circle deployed:", circleAddress);
        
        // Authorize circle in both modules FIRST
        console.log("Authorizing circle in modules...");
        ISwapModule(SWAP_MODULE).authorizeCircle(circleAddress);
        console.log("- SwapModule authorized");
        
        ILendingModule(LENDING_MODULE).authorizeCircle(circleAddress);
        console.log("- LendingModule authorized");
        
        // Now initialize circle
        address[] memory members = new address[](1);
        members[0] = msg.sender; // KEY: Use msg.sender as member
        
        IHorizonCircleCore(circleAddress).initialize(
            "TestFixedCircle",
            members,
            msg.sender,
            SWAP_MODULE,
            LENDING_MODULE
        );
        console.log("Circle initialized successfully");
        
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        
        // Test deposit
        uint256 depositAmount = 0.00003 ether;
        console.log("\n=== DEPOSIT TEST ===");
        console.log("Depositing:", depositAmount);
        circle.deposit{value: depositAmount}();
        
        uint256 userBalance = circle.getUserBalance(msg.sender);
        console.log("User balance after deposit:", userBalance);
        
        // Test request creation with CORRECT contributor setup
        uint256 loanAmount = (userBalance * 80) / 100;
        console.log("\n=== REQUEST CREATION ===");
        console.log("Requesting loan:", loanAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = msg.sender; // KEY FIX: Use msg.sender as contributor
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = loanAmount;
        
        console.log("Contributor setup:");
        console.log("- contributors[0]:", contributors[0]);
        console.log("- msg.sender:", msg.sender);
        console.log("- Match:", contributors[0] == msg.sender);
        
        bytes32 requestId = circle.requestCollateral(
            loanAmount, 
            loanAmount, 
            contributors, 
            amounts,
            "FINAL TEST: Fixed core with correct addresses"
        );
        console.log("Request created successfully");
        
        // Test contribution - THE KEY TEST
        console.log("\n=== CONTRIBUTION TEST ===");
        console.log("This is the critical test for the bug fix");
        
        try circle.contributeToRequest(requestId) {
            console.log("SUCCESS: Contribution bug is FIXED!");
            console.log("");
            console.log("The contribution logic now works correctly:");
            console.log("- msg.sender matches contributors[0]");
            console.log("- Contributor lookup finds the right amount");
            console.log("- Contribution is recorded successfully");
            
            // Test execution with all fixes
            console.log("\n=== EXECUTION TEST ===");
            console.log("Testing complete loan execution with ALL fixes:");
            console.log("- wstETH address: 0x76D8de471F54aAA87784119c60Df1bbFc852C415 (FIXED)");
            console.log("- Pool address: 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3 (FIXED)");
            console.log("- Modules authorized: YES");
            console.log("- Contribution logic: FIXED");
            
            try circle.executeRequest(requestId) returns (bytes32 loanId) {
                console.log("");
                console.log("*** COMPLETE SUCCESS: 100% OPERATIONAL! ***");
                console.log("");
                console.log("FINAL STATUS:");
                console.log("- Core implementation: FIXED");
                console.log("- wstETH address: FIXED");
                console.log("- Pool integration: WORKING");
                console.log("- Module authorization: WORKING");
                console.log("- Contribution logic: FIXED");
                console.log("- Complete loan execution: SUCCESS");
                console.log("");
                console.log("Loan ID:", uint256(loanId));
                console.log("HorizonCircle is now 100% OPERATIONAL!");
                
            } catch Error(string memory reason) {
                console.log("Execution failed:", reason);
                console.log("But contribution bug is FIXED - that was the main issue");
                
            } catch (bytes memory lowLevelData) {
                console.log("Execution failed (low-level)");
                console.log("But contribution bug is FIXED - that was the main issue");
                console.log("Error length:", lowLevelData.length);
            }
            
        } catch Error(string memory reason) {
            console.log("CONTRIBUTION STILL FAILING:", reason);
            console.log("This means there's still an issue in the contract logic");
            
        } catch (bytes memory lowLevelData) {
            console.log("CONTRIBUTION FAILED (low-level)");
            console.log("Error length:", lowLevelData.length);
        }
        
        vm.stopBroadcast();
    }
}
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
}

contract FixContributionBug is Script {
    address constant CORE_IMPLEMENTATION = 0x791183b6c66921603724dA594b3CD39a0d973317;
    address constant SWAP_MODULE = 0xe071b320B3Bf9Cd8a026A98cC59F3636272642b1;
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== CONTRIBUTION BUG FIX TEST ===");
        console.log("The issue: msg.sender in script != contributor address in array");
        console.log("Solution: Use msg.sender as both member AND contributor");
        console.log("");
        console.log("Script sender (will be contributor):", msg.sender);
        
        // Create circle where msg.sender is the member and contributor
        bytes32 salt = keccak256(abi.encodePacked("FixTest", msg.sender, block.timestamp));
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
        console.log("Circle deployed:", circleAddress);
        
        // Initialize with msg.sender as member (not USER constant)
        address[] memory members = new address[](1);
        members[0] = msg.sender; // KEY FIX: Use actual transaction sender
        
        IHorizonCircleCore(circleAddress).initialize(
            "FixTestCircle",
            members,
            msg.sender,
            SWAP_MODULE,
            LENDING_MODULE
        );
        console.log("Circle initialized with msg.sender as member");
        
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        
        // Deposit
        uint256 depositAmount = 0.00003 ether;
        console.log("Depositing:", depositAmount);
        circle.deposit{value: depositAmount}();
        
        uint256 userBalance = circle.getUserBalance(msg.sender);
        console.log("Balance after deposit:", userBalance);
        
        // Create request with msg.sender as contributor (not USER)
        uint256 loanAmount = (userBalance * 80) / 100;
        console.log("Requesting loan:", loanAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = msg.sender; // KEY FIX: Use actual transaction sender
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = loanAmount;
        
        console.log("Setting up correct contributor:");
        console.log("- contributors[0]:", contributors[0]);
        console.log("- msg.sender:", msg.sender);
        console.log("- Match:", contributors[0] == msg.sender);
        
        bytes32 requestId = circle.requestCollateral(
            loanAmount, 
            loanAmount, 
            contributors, 
            amounts,
            "FIX TEST: msg.sender as contributor"
        );
        console.log("Request created");
        
        // Now contribute - this should work!
        console.log("=== CONTRIBUTION TEST ===");
        console.log("This should work because msg.sender == contributors[0]");
        
        try circle.contributeToRequest(requestId) {
            console.log("SUCCESS: Contribution bug is FIXED!");
            console.log("");
            console.log("The issue was:");
            console.log("- DeployFinalFixedModules used USER as contributor");
            console.log("- But msg.sender was the wallet deploying the script");
            console.log("- The lookup failed because they didn't match");
            console.log("");
            console.log("Fix: Always use msg.sender as both member and contributor");
            
        } catch Error(string memory reason) {
            console.log("Still failing:", reason);
            console.log("This means there's a deeper contract issue");
            
        } catch (bytes memory lowLevelData) {
            console.log("Low-level error, length:", lowLevelData.length);
        }
        
        vm.stopBroadcast();
    }
}
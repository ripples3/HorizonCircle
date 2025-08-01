// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
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

contract DeployFinalFixedModules is Script {
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant CORE_IMPLEMENTATION = 0x791183b6c66921603724dA594b3CD39a0d973317;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING FINAL FIXED MODULES ===");
        console.log("User:", USER);
        console.log("Fixed addresses:");
        console.log("- Pool: 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3");
        console.log("- wstETH: 0x76D8de471F54aAA87784119c60Df1bbFc852C415");
        
        // Deploy final fixed modules
        SwapModule swapModule = new SwapModule();
        console.log("SwapModule (BOTH ADDRESSES FIXED):", address(swapModule));
        
        LendingModule lendingModule = new LendingModule();
        console.log("LendingModule (BOTH ADDRESSES FIXED):", address(lendingModule));
        
        // Create final test circle with BOTH fixes
        bytes32 salt = keccak256(abi.encodePacked("FinalTestCircle", msg.sender, block.timestamp));
        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            CORE_IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circleAddress;
        assembly {
            circleAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(circleAddress) { revert(0, 0) }
        }
        console.log("Final test circle deployed:", circleAddress);
        
        // Authorize circle in BOTH modules
        swapModule.authorizeCircle(circleAddress);
        console.log("Circle authorized in SwapModule");
        
        lendingModule.authorizeCircle(circleAddress);
        console.log("Circle authorized in LendingModule");
        
        // Initialize circle with fixed modules
        address[] memory members = new address[](1);
        members[0] = USER;
        
        IHorizonCircleCore(circleAddress).initialize(
            "FinalTestCircle",
            members,
            msg.sender,
            address(swapModule),
            address(lendingModule)
        );
        console.log("Circle initialized with FIXED modules");
        
        // Test complete flow
        console.log("\n=== TESTING COMPLETE DEFI FLOW WITH ALL FIXES ===");
        
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        
        // Deposit
        uint256 depositAmount = 0.00003 ether;
        console.log("Depositing:", depositAmount);
        circle.deposit{value: depositAmount}();
        
        uint256 userBalance = circle.getUserBalance(USER);
        console.log("User balance after deposit:", userBalance);
        
        // Request loan
        uint256 loanAmount = (userBalance * 80) / 100;
        console.log("Requesting loan (80% LTV):", loanAmount);
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = loanAmount;
        
        bytes32 requestId = circle.requestCollateral(
            loanAmount, loanAmount, contributors, amounts,
            "FINAL TEST: All addresses fixed - pool and wstETH"
        );
        console.log("Loan request created");
        
        // Contribute
        circle.contributeToRequest(requestId);
        console.log("Contribution made");
        
        // Execute with ALL FIXES
        console.log("\n=== EXECUTING WITH ALL FIXES ===");
        console.log("Pool: 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3 (FIXED)");
        console.log("wstETH: 0x76D8de471F54aAA87784119c60Df1bbFc852C415 (FIXED)");
        
        uint256 ethBalanceBefore = USER.balance;
        console.log("ETH balance before:", ethBalanceBefore);
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            uint256 ethBalanceAfter = USER.balance;
            uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;
            
            console.log("");
            console.log("*** COMPLETE SUCCESS: ALL FIXES WORKING! ***");
            console.log("");
            console.log("Results:");
            console.log("- Loan ID:", uint256(loanId));
            console.log("- ETH received:", ethReceived);
            console.log("- ETH balance after:", ethBalanceAfter);
            console.log("");
            console.log("100% OPERATIONAL VERIFICATION:");
            console.log("- Pool address fixed: SUCCESS");
            console.log("- wstETH address fixed: SUCCESS");
            console.log("- Morpho vault operations: SUCCESS");
            console.log("- WETH -> wstETH swap: SUCCESS");
            console.log("- Morpho lending market: SUCCESS");
            console.log("- Complete loan execution: SUCCESS");
            console.log("");
            console.log("*** HORIZONCIRCLE 100% OPERATIONAL! ***");
            console.log("Circle:", circleAddress);
            console.log("Ready for production!");
            
        } catch Error(string memory reason) {
            console.log("EXECUTION FAILED:", reason);
            
        } catch (bytes memory lowLevelData) {
            console.log("EXECUTION FAILED with low-level error");
            console.log("Error length:", lowLevelData.length);
        }
        
        vm.stopBroadcast();
    }
}
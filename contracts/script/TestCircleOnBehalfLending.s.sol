// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingModuleCircleOnBehalf.sol";

interface ISwapModule {
    function authorizeCircle(address circle) external;
    function authorizedCallers(address circle) external view returns (bool);
}

interface ILendingModule {
    function authorizeCircle(address circle) external;
    function authorizedCallers(address circle) external view returns (bool);
}

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
    function directLTVWithdraw(uint256 borrowAmount) external returns (bytes32 loanId);
}

contract TestCircleOnBehalfLending is Script {
    address constant IMPLEMENTATION = 0xc4aF1079184D99C44bA299ab11B1c7d11Fa4Ec48;
    address constant FIXED_SWAP_MODULE = 0xd336fB4dbFCB2a1Dc06b1c7297a7B8bD4059EeaD; // No-slippage swap
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING LENDING MODULE: CIRCLE ON-BEHALF ===");
        console.log("Deploying lending module that supplies on behalf of CIRCLE");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy circle-onbehalf lending module
        LendingModuleCircleOnBehalf circleOnBehalfLendingModule = new LendingModuleCircleOnBehalf();
        console.log("Circle OnBehalf LendingModule deployed:", address(circleOnBehalfLendingModule));
        
        // Create test circle
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circle;
        bytes32 salt = keccak256("CIRCLE_ONBEHALF_TEST");
        assembly {
            circle := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("Circle OnBehalf test circle:", circle);
        
        // Initialize with circle-onbehalf lending module
        address[] memory members = new address[](1);
        members[0] = USER;
        
        IImplementation(circle).initialize(
            "CIRCLE_ONBEHALF_TEST",
            members,
            REGISTRY,
            FIXED_SWAP_MODULE,
            address(circleOnBehalfLendingModule)
        );
        
        // Authorize circle for both modules
        ISwapModule(FIXED_SWAP_MODULE).authorizeCircle(circle);
        circleOnBehalfLendingModule.authorizeCircle(circle);
        
        console.log("Circle authorized for both modules");
        
        // Test loan execution
        uint256 depositAmount = 0.0001 ether;
        IImplementation(circle).deposit{value: depositAmount}();
        
        uint256 balance = IImplementation(circle).getUserBalance(USER);
        uint256 borrowAmount = (balance * 80) / 100;
        
        console.log("Deposited:", depositAmount / 1e12, "microETH");
        console.log("Borrowing:", borrowAmount / 1e12, "microETH");
        
        uint256 ethBefore = USER.balance;
        console.log("ETH before loan:", ethBefore / 1e12, "microETH");
        
        console.log("\\n=== TESTING: SUPPLY ON BEHALF OF CIRCLE ===");
        console.log("This changes onBehalf from lending module to circle address");
        
        try IImplementation(circle).directLTVWithdraw(borrowAmount) returns (bytes32 loanId) {
            uint256 ethAfter = USER.balance;
            uint256 ethReceived = ethAfter - ethBefore;
            
            console.log("\\n*** SUCCESS: CIRCLE ON-BEHALF APPROACH WORKED! ***");
            console.log("ETH after loan:", ethAfter / 1e12, "microETH");
            console.log("ETH received from loan:", ethReceived / 1e12, "microETH");
            console.log("Loan ID:");
            console.logBytes32(loanId);
            
            console.log("\\n=== DIAGNOSIS: MORPHO REQUIRES CIRCLE AS ONBEHALF ===");
            console.log("SUCCESS: Morpho supply/borrow works when onBehalf = circle");
            console.log("ISSUE: Previous approach used onBehalf = lending module");
            console.log("SOLUTION: Always use circle address as onBehalf parameter");
            
        } catch Error(string memory reason) {
            console.log("Still failed with circle onBehalf - Reason:", reason);
        } catch {
            console.log("Still failed with circle onBehalf - Unknown error");
            console.log("If this fails too, the issue is deeper than onBehalf parameter");
        }
        
        vm.stopBroadcast();
    }
}
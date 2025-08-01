// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SwapModuleNoSlippage.sol";

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

contract TestNoSlippage is Script {
    address constant IMPLEMENTATION = 0xc4aF1079184D99C44bA299ab11B1c7d11Fa4Ec48;
    address constant LENDING_MODULE = 0x692c477CAa49309FD47Ce3500fd3CC81f2928347;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING WITH NO SLIPPAGE PROTECTION ===");
        console.log("This will test if slippage calculation is the issue");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy no-slippage swap module
        SwapModuleNoSlippage noSlippageSwap = new SwapModuleNoSlippage();
        console.log("No-slippage SwapModule deployed at:", address(noSlippageSwap));
        
        // Create test circle
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circle;
        bytes32 salt = keccak256("NoSlippageTest");
        assembly {
            circle := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("Test circle:", circle);
        
        // Initialize with no-slippage swap module
        address[] memory members = new address[](1);
        members[0] = USER;
        
        IImplementation(circle).initialize(
            "NoSlippageTest",
            members,
            REGISTRY,
            address(noSlippageSwap),
            LENDING_MODULE
        );
        
        // Authorize circle
        noSlippageSwap.authorizeCircle(circle);
        ILendingModule(LENDING_MODULE).authorizeCircle(circle);
        
        console.log("Circle authorized for both modules");
        
        // Deposit and test loan
        uint256 depositAmount = 0.0001 ether;
        IImplementation(circle).deposit{value: depositAmount}();
        
        uint256 balance = IImplementation(circle).getUserBalance(USER);
        uint256 borrowAmount = (balance * 80) / 100;
        
        console.log("Deposited:", depositAmount / 1e12, "microETH");
        console.log("Borrowing:", borrowAmount / 1e12, "microETH");
        
        console.log("\n=== TESTING LOAN EXECUTION WITH NO SLIPPAGE LIMITS ===");
        
        try IImplementation(circle).directLTVWithdraw(borrowAmount) returns (bytes32 loanId) {
            console.log("SUCCESS! No-slippage swap worked!");
            console.log("This means the slippage calculation was the issue");
            console.logBytes32(loanId);
            
        } catch Error(string memory reason) {
            console.log("Still failed with reason:", reason);
            console.log("Issue is not slippage-related");
            
        } catch {
            console.log("Still failed with unknown error");
            console.log("Need to investigate callback or other swap parameters");
        }
        
        vm.stopBroadcast();
    }
}
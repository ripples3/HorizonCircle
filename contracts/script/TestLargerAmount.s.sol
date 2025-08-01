// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingModuleCircleOnBehalf.sol";

interface ISwapModule {
    function authorizeCircle(address circle) external;
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

contract TestLargerAmount is Script {
    address constant IMPLEMENTATION = 0xc4aF1079184D99C44bA299ab11B1c7d11Fa4Ec48;
    address constant FIXED_SWAP_MODULE = 0xd336fB4dbFCB2a1Dc06b1c7297a7B8bD4059EeaD;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING WITH LARGER AMOUNT (10x) ===");
        console.log("Testing if Morpho has minimum supply requirements");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy lending module
        LendingModuleCircleOnBehalf lendingModule = new LendingModuleCircleOnBehalf();
        
        // Create test circle
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circle;
        bytes32 salt = keccak256("LARGER_AMOUNT_TEST");
        assembly {
            circle := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("Large amount test circle:", circle);
        
        // Initialize 
        address[] memory members = new address[](1);
        members[0] = USER;
        
        IImplementation(circle).initialize(
            "LARGER_AMOUNT_TEST",
            members,
            REGISTRY,
            FIXED_SWAP_MODULE,
            address(lendingModule)
        );
        
        // Authorize
        ISwapModule(FIXED_SWAP_MODULE).authorizeCircle(circle);
        lendingModule.authorizeCircle(circle);
        
        // Use 10x larger deposit
        uint256 depositAmount = 0.001 ether; // 10x larger
        IImplementation(circle).deposit{value: depositAmount}();
        
        uint256 balance = IImplementation(circle).getUserBalance(USER);
        uint256 borrowAmount = (balance * 80) / 100;
        
        console.log("Deposited:", depositAmount / 1e15, "milliETH");
        console.log("Borrowing:", borrowAmount / 1e15, "milliETH");
        console.log("Expected wstETH collateral:", (borrowAmount * 117) / 100 / 1e12, "microETH");
        
        uint256 ethBefore = USER.balance;
        
        console.log("\\n=== TESTING LARGER AMOUNTS FOR MORPHO MINIMUMS ===");
        
        try IImplementation(circle).directLTVWithdraw(borrowAmount) returns (bytes32 loanId) {
            uint256 ethAfter = USER.balance;
            uint256 ethReceived = ethAfter - ethBefore;
            
            console.log("\\n*** SUCCESS WITH LARGER AMOUNT! ***");
            console.log("ETH received:", ethReceived / 1e12, "microETH");
            console.log("DIAGNOSIS: Morpho had minimum supply amount requirement");
            console.log("SOLUTION: Previous amounts were too small for Morpho");
            
        } catch Error(string memory reason) {
            console.log("Still failed with larger amount - Reason:", reason);
            console.log("Amount issue ruled out - investigating other causes");
        } catch {
            console.log("Still failed with larger amount - Unknown error");
            console.log("This confirms it's not a minimum amount issue");
            console.log("Need to investigate Morpho protocol specifics");
        }
        
        vm.stopBroadcast();
    }
}
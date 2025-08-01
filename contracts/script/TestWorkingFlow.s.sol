// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingModuleSimplified.sol";

interface ISwapModule {
    function authorizeCircle(address circle) external;
}

interface ICircle {
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

contract TestWorkingFlow is Script {
    // Use the existing implementation that has Morpho auth
    address constant IMPLEMENTATION = 0xc4aF1079184D99C44bA299ab11B1c7d11Fa4Ec48;
    address constant SWAP_MODULE = 0xd336fB4dbFCB2a1Dc06b1c7297a7B8bD4059EeaD;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TESTING WORKING FLOW - USER RECEIVES ETH ===");
        console.log("User initial balance:", USER.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy simplified lending module with ETH funding
        uint256 fundingAmount = 0.00005 ether; // Fund with 50 microETH (affordable amount)
        LendingModuleSimplified lendingModule = new LendingModuleSimplified{value: fundingAmount}();
        console.log("1. LendingModule deployed and funded:", address(lendingModule));
        console.log("   Module ETH balance:", address(lendingModule).balance);
        
        // Deploy circle
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circle;
        bytes32 salt = keccak256(abi.encodePacked("WORKING_TEST", block.timestamp));
        assembly {
            circle := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("2. Circle deployed:", circle);
        
        // Initialize
        address[] memory members = new address[](1);
        members[0] = USER;
        
        ICircle(circle).initialize(
            "WORKING_TEST",
            members,
            REGISTRY,
            SWAP_MODULE,
            address(lendingModule)
        );
        
        console.log("3. Circle initialized");
        
        // Authorize
        ISwapModule(SWAP_MODULE).authorizeCircle(circle);
        lendingModule.authorizeCircle(circle);
        
        console.log("4. Modules authorized");
        
        // Deposit
        uint256 depositAmount = 0.00003 ether; // 30 microETH as requested
        console.log("5. User depositing:", depositAmount);
        
        ICircle(circle).deposit{value: depositAmount}();
        
        uint256 userVaultBalance = ICircle(circle).getUserBalance(USER);
        console.log("   User vault balance:", userVaultBalance);
        
        // Borrow small amount  
        uint256 borrowAmount = 0.00001 ether; // 10 microETH (less than funding amount)
        console.log("6. User borrowing:", borrowAmount);
        
        uint256 userEthBefore = USER.balance;
        console.log("   User ETH before borrow:", userEthBefore);
        
        // Execute loan
        bytes32 loanId = ICircle(circle).directLTVWithdraw(borrowAmount);
        
        uint256 userEthAfter = USER.balance;
        uint256 ethReceived = userEthAfter - userEthBefore;
        
        console.log("7. Loan executed");
        console.log("   User ETH after borrow:", userEthAfter);
        console.log("   ETH RECEIVED BY USER:", ethReceived);
        console.log("   Loan ID:");
        console.logBytes32(loanId);
        
        if (ethReceived > 0) {
            console.log("\\n*** SUCCESS! USER RECEIVED BORROWED ETH! ***");
            console.log("Amount received:", ethReceived, "wei");
            console.log("Circle:", circle);
            console.log("User:", USER);
        } else {
            console.log("\\n*** FAILURE: User still received 0 ETH ***");
            console.log("Check lending module balance:", lendingModule.getBalance());
        }
        
        vm.stopBroadcast();
    }
}
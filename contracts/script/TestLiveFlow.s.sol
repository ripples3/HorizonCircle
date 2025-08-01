// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LendingModuleIndustryStandard.sol";

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

contract TestLiveFlow is Script {
    address constant IMPLEMENTATION_WITH_AUTH = 0xB5fe149c80235fAb970358543EEce1C800FDcA64;
    address constant FIXED_SWAP_MODULE = 0xd336fB4dbFCB2a1Dc06b1c7297a7B8bD4059EeaD;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== LIVE FLOW TEST - REAL TIME ===");
        console.log("User current balance:", USER.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy lending module
        LendingModuleIndustryStandard lendingModule = new LendingModuleIndustryStandard();
        console.log("1. LendingModule deployed:", address(lendingModule));
        
        // Deploy circle
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d3d363d73",
            IMPLEMENTATION_WITH_AUTH,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circle;
        bytes32 salt = keccak256(abi.encodePacked("LIVE_TEST", block.timestamp));
        assembly {
            circle := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("2. Circle deployed:", circle);
        
        // Initialize
        address[] memory members = new address[](1);
        members[0] = USER;
        
        ICircle(circle).initialize(
            "LIVE_TEST",
            members,
            REGISTRY,
            FIXED_SWAP_MODULE,
            address(lendingModule)
        );
        
        console.log("3. Circle initialized");
        
        // Authorize modules
        ISwapModule(FIXED_SWAP_MODULE).authorizeCircle(circle);
        lendingModule.authorizeCircle(circle);
        
        console.log("4. Modules authorized");
        
        // Deposit
        uint256 depositAmount = 0.00003 ether; // 30 microETH as requested
        console.log("5. Depositing:", depositAmount);
        
        ICircle(circle).deposit{value: depositAmount}();
        
        uint256 userBalance = ICircle(circle).getUserBalance(USER);
        console.log("User vault balance:", userBalance);
        
        // Borrow
        uint256 borrowAmount = userBalance / 3; // Conservative 33%
        console.log("6. Borrowing:", borrowAmount);
        
        uint256 ethBefore = USER.balance;
        console.log("ETH before loan:", ethBefore);
        
        bytes32 loanId = ICircle(circle).directLTVWithdraw(borrowAmount);
        
        uint256 ethAfter = USER.balance;
        uint256 ethReceived = ethAfter - ethBefore;
        
        console.log("7. Loan completed");
        console.log("ETH after loan:", ethAfter);
        console.log("ETH RECEIVED:", ethReceived);
        console.log("Loan ID:");
        console.logBytes32(loanId);
        
        if (ethReceived > 0) {
            console.log("SUCCESS: User received borrowed ETH!");
        } else {
            console.log("FAILURE: User received 0 ETH");
        }
        
        vm.stopBroadcast();
    }
}
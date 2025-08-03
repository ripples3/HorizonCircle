// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IHorizonCircleMinimalProxy {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

interface IHorizonCircle {
    function initialize(string memory name, address[] memory members, address factory, address swapModule, address lendingModule) external;
    function deposit() external payable;
    function requestCollateral(uint256 amount, address[] memory contributors, uint256[] memory amounts, string memory purpose) external returns (bytes32);
    function contributeToRequest(bytes32 requestId) external;
    function executeRequest(bytes32 requestId) external returns (bytes32);
    function getUserBalance(address user) external view returns (uint256);
    function isCircleMember(address user) external view returns (bool);
}

interface ISwapModule {
    function authorizeCircle(address circle) external;
}

interface ILendingModule {
    function authorizeUser(address user) external;
}

contract TestWorkingSystemComplete is Script {
    // Working contract addresses
    address constant FACTORY = 0x95e4c63Ee7e82b94D75dDbF858F0D2D0600fcCdD;
    address constant IMPLEMENTATION = 0x763004aE80080C36ec99eC5f2dc3F2C260638A83;
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801;
    address constant SWAP_MODULE = 0x68E6b55D4EB478C736c9c19020adD14E7aB35d92; // Just deployed
    
    address constant TEST_USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== TEST COMPLETE WORKING SYSTEM ===");
        console.log("Factory:", FACTORY);
        console.log("Implementation:", IMPLEMENTATION);
        console.log("Lending Module:", LENDING_MODULE);
        console.log("Swap Module:", SWAP_MODULE);
        console.log("Test User:", TEST_USER);
        
        uint256 initialBalance = TEST_USER.balance;
        console.log("Initial ETH Balance:", initialBalance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Create circle with working factory
        string memory circleName = string(abi.encodePacked("WorkingCircle", vm.toString(block.timestamp)));
        address[] memory members = new address[](1);
        members[0] = TEST_USER;
        
        IHorizonCircleMinimalProxy factory = IHorizonCircleMinimalProxy(FACTORY);
        address circleAddress = factory.createCircle(circleName, members);
        console.log("Circle created:", circleAddress);
        
        // Initialize with modules
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        circle.initialize(
            circleName,
            members,
            FACTORY,
            SWAP_MODULE,
            LENDING_MODULE
        );
        console.log("Circle initialized with modules");
        
        // Authorize circle for modules
        ISwapModule(SWAP_MODULE).authorizeCircle(circleAddress);
        ILendingModule(LENDING_MODULE).authorizeUser(circleAddress);
        console.log("Circle authorized for modules");
        
        // Test deposit
        uint256 depositAmount = 0.00003 ether;
        circle.deposit{value: depositAmount}();
        console.log("Deposited:", depositAmount);
        
        // Test loan request
        uint256 loanAmount = 0.00001 ether;
        address[] memory contributors = new address[](1);
        contributors[0] = TEST_USER;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 0.000012 ether;
        
        bytes32 requestId = circle.requestCollateral(loanAmount, contributors, amounts, "Test working system");
        console.log("Loan requested");
        
        // Contribute
        circle.contributeToRequest(requestId);
        console.log("Contribution made");
        
        // Execute with swap
        console.log("Executing loan with WETH->wstETH swap...");
        bytes32 loanId = circle.executeRequest(requestId);
        console.log("Loan executed successfully!");
        
        vm.stopBroadcast();
        
        console.log("\\n=== RESULTS ===");
        console.log("Final ETH Balance:", TEST_USER.balance);
        
        if (TEST_USER.balance > initialBalance) {
            console.log("SUCCESS: Complete system working!");
        } else {
            console.log("Issue: User did not receive ETH");
        }
    }
}
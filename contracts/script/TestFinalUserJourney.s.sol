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

contract TestFinalUserJourney is Script {
    address constant IMPLEMENTATION_WITH_AUTH = 0xB5fe149c80235fAb970358543EEce1C800FDcA64;
    address constant FIXED_SWAP_MODULE = 0xd336fB4dbFCB2a1Dc06b1c7297a7B8bD4059EeaD;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== FINAL USER JOURNEY TEST ===");
        console.log("Testing with meaningful deposit amount");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy lending module
        LendingModuleIndustryStandard lendingModule = new LendingModuleIndustryStandard();
        console.log("LendingModule deployed:", address(lendingModule));
        
        // Deploy circle
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            IMPLEMENTATION_WITH_AUTH,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circle;
        bytes32 salt = keccak256("FINAL_USER_JOURNEY");
        assembly {
            circle := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("Circle deployed:", circle);
        
        // Initialize
        address[] memory members = new address[](1);
        members[0] = USER;
        
        ICircle(circle).initialize(
            "FINAL_USER_JOURNEY",
            members,
            REGISTRY,
            FIXED_SWAP_MODULE,
            address(lendingModule)
        );
        
        // Authorize modules
        ISwapModule(FIXED_SWAP_MODULE).authorizeCircle(circle);
        lendingModule.authorizeCircle(circle);
        
        console.log("Circle initialized and authorized");
        
        // Check user balance before
        uint256 userEthBefore = USER.balance;
        console.log("User ETH before:", userEthBefore, "wei");
        console.log("User ETH before:", userEthBefore / 1e12, "microETH");
        
        // Deposit meaningful amount (user has ~1434 microETH)
        uint256 depositAmount = 1000000000000000; // 0.001 ETH = 1000 microETH
        console.log("Depositing:", depositAmount, "wei");
        console.log("Depositing:", depositAmount / 1e12, "microETH");
        
        ICircle(circle).deposit{value: depositAmount}();
        
        uint256 userBalance = ICircle(circle).getUserBalance(USER);
        console.log("User vault balance:", userBalance, "wei");
        console.log("User vault balance:", userBalance / 1e12, "microETH");
        
        // Calculate meaningful borrow amount
        if (userBalance > 0) {
            uint256 maxBorrow = (userBalance * 8500) / 10000; // 85% LTV
            uint256 borrowAmount = maxBorrow / 2; // 50% of max for safety
            
            console.log("Max borrow (85% LTV):", maxBorrow, "wei");
            console.log("Max borrow (85% LTV):", maxBorrow / 1e12, "microETH");
            console.log("Actual borrow amount:", borrowAmount, "wei");
            console.log("Actual borrow amount:", borrowAmount / 1e12, "microETH");
            
            if (borrowAmount > 0) {
                console.log("\\n=== EXECUTING LOAN ===");
                
                uint256 ethBeforeLoan = USER.balance;
                console.log("User ETH before loan:", ethBeforeLoan, "wei");
                
                try ICircle(circle).directLTVWithdraw(borrowAmount) returns (bytes32 loanId) {
                    uint256 ethAfterLoan = USER.balance;
                    uint256 ethReceived = ethAfterLoan - ethBeforeLoan;
                    
                    console.log("\\n*** SUCCESS! ***");
                    console.log("User ETH after loan:", ethAfterLoan, "wei");
                    console.log("ETH received from loan:", ethReceived, "wei");
                    console.log("ETH received from loan:", ethReceived / 1e12, "microETH");
                    console.log("Loan ID:");
                    console.logBytes32(loanId);
                    
                    if (ethReceived > 0) {
                        console.log("\\n=== USER SUCCESSFULLY BORROWED AND RECEIVED ETH! ===");
                        console.log("HORIZONCIRCLE: COMPLETE END-TO-END SUCCESS!");
                    } else {
                        console.log("\\n=== LOAN EXECUTED BUT NO ETH RECEIVED ===");
                        console.log("Check lending module implementation");
                    }
                    
                } catch Error(string memory reason) {
                    console.log("\\nLoan failed:", reason);
                } catch {
                    console.log("\\nLoan failed: Unknown error");
                }
            } else {
                console.log("\\nBorrow amount is 0 - deposit too small for meaningful loan");
            }
        } else {
            console.log("\\nUser vault balance is 0 - deposit failed");
        }
        
        vm.stopBroadcast();
    }
}
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

contract TestSimpleFlow is Script {
    address constant IMPLEMENTATION_WITH_AUTH = 0xB5fe149c80235fAb970358543EEce1C800FDcA64;
    address constant FIXED_SWAP_MODULE = 0xd336fB4dbFCB2a1Dc06b1c7297a7B8bD4059EeaD;
    address constant REGISTRY = 0x68Dc6FeBA312BF9B7BfBe096EA5e7ccb61a522dE;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== SIMPLE FLOW TEST: DEPOSIT -> BORROW -> USER RECEIVES ETH ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy modules
        LendingModuleIndustryStandard lendingModule = new LendingModuleIndustryStandard();
        console.log("LendingModule deployed:", address(lendingModule));
        
        // Deploy circle
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d3d363d73",
            IMPLEMENTATION_WITH_AUTH,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circle;
        bytes32 salt = keccak256(abi.encodePacked("SIMPLE_FLOW_TEST", block.timestamp));
        assembly {
            circle := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("Circle deployed:", circle);
        
        // Initialize
        address[] memory members = new address[](1);
        members[0] = USER;
        
        ICircle(circle).initialize(
            "SIMPLE_FLOW_TEST",
            members,
            REGISTRY,
            FIXED_SWAP_MODULE,
            address(lendingModule)
        );
        
        // Authorize modules
        ISwapModule(FIXED_SWAP_MODULE).authorizeCircle(circle);
        lendingModule.authorizeCircle(circle);
        
        console.log("Circle initialized and authorized");
        
        // User deposits
        uint256 depositAmount = 0.002 ether;
        console.log("User depositing:", depositAmount);
        
        uint256 userEthBefore = USER.balance;
        console.log("User ETH before deposit:", userEthBefore);
        
        ICircle(circle).deposit{value: depositAmount}();
        
        uint256 userBalanceInCircle = ICircle(circle).getUserBalance(USER);
        console.log("User balance in circle:", userBalanceInCircle);
        
        // Calculate borrow amount
        uint256 borrowAmount = (userBalanceInCircle * 4000) / 10000; // 40% for safety
        console.log("Borrow amount:", borrowAmount);
        
        if (borrowAmount > 0) {
            console.log("\\n=== EXECUTING LOAN ===");
            
            uint256 userEthBeforeLoan = USER.balance;
            console.log("User ETH before loan:", userEthBeforeLoan);
            
            try ICircle(circle).directLTVWithdraw(borrowAmount) returns (bytes32 loanId) {
                uint256 userEthAfterLoan = USER.balance;
                uint256 ethReceived = userEthAfterLoan - userEthBeforeLoan;
                
                console.log("User ETH after loan:", userEthAfterLoan);
                console.log("ETH RECEIVED BY USER:", ethReceived);
                console.log("Loan ID:");
                console.logBytes32(loanId);
                
                if (ethReceived > 0) {
                    console.log("\\n*** SUCCESS! USER RECEIVED BORROWED ETH! ***");
                    console.log("Amount received:", ethReceived, "wei");
                } else {
                    console.log("\\n*** FAILURE: User received 0 ETH ***");
                }
                
            } catch Error(string memory reason) {
                console.log("Loan failed:", reason);
            } catch {
                console.log("Loan failed: Unknown error");
            }
        } else {
            console.log("Borrow amount is 0");
        }
        
        vm.stopBroadcast();
    }
}
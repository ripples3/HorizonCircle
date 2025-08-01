// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IMorphoBlue {
    function setAuthorization(address authorized, bool newIsAuthorized) external;
    function isAuthorized(address authorizer, address authorized) external view returns (bool);
}

interface ILendingModule {
    function supplyCollateralAndBorrow(
        uint256 wstETHAmount,
        uint256 wethToBorrow,
        address borrower
    ) external returns (bytes32);
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
    function directLTVWithdraw(uint256 borrowAmount) external returns (bytes32);
}

contract FixExistingLendingModule is Script {
    // Use existing deployed addresses
    address constant IMPLEMENTATION = 0x763004aE80080C36ec99eC5f2dc3F2C260638A83;
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801;
    address constant MORPHO_BLUE = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        console.log("=== FIXING EXISTING LENDING MODULE - NO NEW CONTRACTS ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy circle using existing implementation
        bytes memory creationCode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d3d363d73",
            IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circle;
        bytes32 salt = keccak256(abi.encodePacked("FIX_TEST", block.timestamp));
        assembly {
            circle := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        console.log("1. Circle deployed:", circle);
        
        // 2. Initialize circle
        address[] memory members = new address[](1);  
        members[0] = USER;
        
        ICircle(circle).initialize(
            "FIX_TEST",
            members,
            address(0), // registry
            address(0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3), // swap (use pool directly)
            LENDING_MODULE
        );
        
        console.log("2. Circle initialized");
        
        // 3. Check if circle automatically authorized lending module in Morpho
        bool isAuthorized = IMorphoBlue(MORPHO_BLUE).isAuthorized(circle, LENDING_MODULE);
        console.log("3. Circle auto-authorized lending module in Morpho:", isAuthorized);
        
        if (!isAuthorized) {
            console.log("4. Manually authorizing lending module in Morpho...");
            // Circle needs to authorize lending module in Morpho
            vm.startPrank(circle);
            IMorphoBlue(MORPHO_BLUE).setAuthorization(LENDING_MODULE, true);
            vm.stopPrank();
            
            // Verify authorization
            isAuthorized = IMorphoBlue(MORPHO_BLUE).isAuthorized(circle, LENDING_MODULE);
            console.log("   Authorization now:", isAuthorized);
        }
        
        // 4. Authorize circle in lending module  
        ILendingModule(LENDING_MODULE).authorizeCircle(circle);
        console.log("5. Circle authorized in lending module");
        
        // 5. Test deposit and borrow
        uint256 depositAmount = 0.00005 ether; // 50 microETH
        console.log("6. Depositing:", depositAmount);
        
        ICircle(circle).deposit{value: depositAmount}();
        
        uint256 userBalance = ICircle(circle).getUserBalance(USER);
        console.log("   User balance after deposit:", userBalance);
        
        // 6. Test borrow
        uint256 borrowAmount = 0.00001 ether; // 10 microETH
        console.log("7. Testing borrow:", borrowAmount);
        
        uint256 userEthBefore = USER.balance;
        console.log("   User ETH before:", userEthBefore);
        
        try ICircle(circle).directLTVWithdraw(borrowAmount) returns (bytes32 loanId) {
            uint256 userEthAfter = USER.balance;
            uint256 ethReceived = userEthAfter - userEthBefore;
            
            console.log("8. Loan executed!");
            console.log("   User ETH after:", userEthAfter);
            console.log("   ETH RECEIVED BY USER:", ethReceived);
            console.logBytes32(loanId);
            
            if (ethReceived > 0) {
                console.log("\n*** SUCCESS! USER RECEIVED BORROWED ETH! ***");
                console.log("Circle:", circle);
                console.log("User:", USER);
            } else {
                console.log("\n*** ISSUE: Loan executed but user received 0 ETH ***");
            }
        } catch Error(string memory reason) {
            console.log("8. FAILED - Error:");
            console.log(reason);
        } catch {
            console.log("8. FAILED - Unknown error");
        }
        
        vm.stopBroadcast();
    }
}
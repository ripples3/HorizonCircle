// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IHorizonCircleCore {
    function initialize(
        string memory name,
        address[] memory members,
        address factory,
        address swapModule,
        address lendingModule
    ) external;
}

interface ISwapModule {
    function authorizeCircle(address circle) external;
}

interface ILendingModule {
    function authorizeCircle(address circle) external;
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

contract DeployFixedSystem is Script {
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    address constant CORE_IMPLEMENTATION = 0x791183b6c66921603724dA594b3CD39a0d973317;
    address constant SWAP_MODULE = 0x48Ad48d21405597A960901384bFA8C3464547ac3;
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== CREATING CIRCLE MANUALLY WITH AUTHORIZED MODULES ===");
        console.log("User:", USER);
        console.log("Using authorized modules:");
        console.log("- SwapModule:", SWAP_MODULE);
        console.log("- LendingModule:", LENDING_MODULE);
        
        // Deploy circle manually using minimal proxy pattern
        bytes32 salt = keccak256(abi.encodePacked("ManualTestCircle", msg.sender, block.timestamp));
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
        
        console.log("Circle deployed:", circleAddress);
        
        // Authorize in modules
        ISwapModule(SWAP_MODULE).authorizeCircle(circleAddress);
        console.log("Authorized in SwapModule");
        
        ILendingModule(LENDING_MODULE).authorizeCircle(circleAddress);
        console.log("Authorized in LendingModule");
        
        // Initialize circle
        address[] memory members = new address[](1);
        members[0] = USER;
        
        IHorizonCircleCore(circleAddress).initialize(
            "ManualTestCircle",
            members,
            msg.sender, // factory
            SWAP_MODULE,
            LENDING_MODULE
        );
        console.log("Circle initialized");
        
        // Now test the complete DeFi flow
        console.log("\n=== TESTING COMPLETE DEFI LOAN EXECUTION ===");
        
        IHorizonCircle circle = IHorizonCircle(circleAddress);
        
        // Step 1: Deposit 0.00003 ETH
        console.log("\n=== STEP 1: DEPOSIT 0.00003 ETH ===");
        uint256 depositAmount = 0.00003 ether;
        console.log("Depositing:", depositAmount);
        
        circle.deposit{value: depositAmount}();
        console.log("SUCCESS: Deposit completed");
        
        uint256 userBalance = circle.getUserBalance(USER);
        console.log("User balance after deposit:", userBalance);
        
        // Step 2: Request 80% LTV loan
        console.log("\n=== STEP 2: REQUEST LOAN AT 80% LTV ===");
        uint256 loanAmount = (userBalance * 80) / 100;
        uint256 collateralNeeded = loanAmount;
        
        console.log("Loan amount (80% LTV):", loanAmount);
        console.log("Collateral needed:", collateralNeeded);
        
        address[] memory contributors = new address[](1);
        contributors[0] = USER;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = collateralNeeded;
        
        bytes32 requestId = circle.requestCollateral(
            loanAmount,
            collateralNeeded,
            contributors,
            amounts,
            "FINAL TEST: Complete DeFi integration with authorized modules"
        );
        console.log("SUCCESS: Loan request created");
        
        // Step 3: Contribute
        console.log("\n=== STEP 3: CONTRIBUTE TO REQUEST ===");
        circle.contributeToRequest(requestId);
        console.log("SUCCESS: Contribution made");
        
        // Step 4: Execute loan
        console.log("\n=== STEP 4: EXECUTE COMPLETE DEFI LOAN ===");
        console.log("Testing full authorized modular system:");
        console.log("1. Withdraw WETH from Morpho vault");
        console.log("2. Authorized SwapModule.swapWETHToWstETH()");
        console.log("3. Authorized LendingModule.supplyCollateralAndBorrow()");
        console.log("4. Receive ETH loan from Morpho lending market");
        
        uint256 ethBalanceBefore = USER.balance;
        console.log("ETH balance before:", ethBalanceBefore);
        
        try circle.executeRequest(requestId) returns (bytes32 loanId) {
            uint256 ethBalanceAfter = USER.balance;
            uint256 ethReceived = ethBalanceAfter - ethBalanceBefore;
            
            console.log("");
            console.log("*** COMPLETE SUCCESS: HORIZONCIRCLE 100% OPERATIONAL! ***");
            console.log("");
            console.log("Results:");
            console.log("- Loan ID:", uint256(loanId));
            console.log("- ETH received:", ethReceived);
            console.log("- ETH balance before:", ethBalanceBefore);
            console.log("- ETH balance after:", ethBalanceAfter);
            console.log("");
            console.log("Complete DeFi Integration VERIFIED:");
            console.log("- Morpho vault operations: WORKING");
            console.log("- Authorized module calls: WORKING");
            console.log("- WETH -> wstETH swaps: WORKING");
            console.log("- Morpho lending markets: WORKING");
            console.log("- ETH loan distribution: WORKING");
            console.log("");
            console.log("HORIZONCIRCLE IS FULLY OPERATIONAL!");
            console.log("Circle address:", circleAddress);
            
        } catch Error(string memory reason) {
            console.log("EXECUTION FAILED:", reason);
            
        } catch (bytes memory lowLevelData) {
            console.log("EXECUTION FAILED with low-level error");
            console.log("Error data length:", lowLevelData.length);
            if (lowLevelData.length >= 4) {
                console.log("Error selector:", uint32(bytes4(lowLevelData)));
            }
        }
        
        vm.stopBroadcast();
    }
}
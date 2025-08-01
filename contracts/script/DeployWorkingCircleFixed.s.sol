// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface ISwapModule {
    function authorizeCircle(address circle) external;
    function owner() external view returns (address);
}

interface ILendingModule {
    function authorizeCircle(address circle) external;
    function owner() external view returns (address);
}

interface IHorizonCircleCore {
    function initialize(
        string memory name,
        address[] memory members,
        address factory,
        address swapModule,
        address lendingModule
    ) external;
}

contract DeployWorkingCircleFixed is Script {
    // Correct addresses from our analysis
    address constant FIXED_CORE_IMPLEMENTATION = 0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519;
    address constant SWAP_MODULE = 0xe071b320B3Bf9Cd8a026A98cC59F3636272642b1;
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801;
    address constant USER = 0x8D0d8f902ba2DB13f0282F5262cD55d8930EB456; // From the failed transaction
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING WORKING CIRCLE FOR USER ===");
        console.log("User address:", USER);
        console.log("Fixed core implementation:", FIXED_CORE_IMPLEMENTATION);
        console.log("Block starting from: 19636509");
        console.log("");
        
        // Check module owners
        address swapOwner = ISwapModule(SWAP_MODULE).owner();
        address lendingOwner = ILendingModule(LENDING_MODULE).owner();
        console.log("SwapModule owner:", swapOwner);
        console.log("LendingModule owner:", lendingOwner);
        console.log("Transaction sender:", msg.sender);
        console.log("");
        
        // Deploy circle with fixed implementation
        bytes32 salt = keccak256(abi.encodePacked("WorkingCircle", USER, block.timestamp));
        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d3d363d73",
            FIXED_CORE_IMPLEMENTATION,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        address circleAddress;
        assembly {
            circleAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(circleAddress) { revert(0, 0) }
        }
        console.log("New working circle deployed:", circleAddress);
        
        // Check if we can authorize modules
        if (msg.sender == swapOwner) {
            console.log("Authorizing in SwapModule...");
            ISwapModule(SWAP_MODULE).authorizeCircle(circleAddress);
            console.log("SwapModule: Authorized");
            
            if (msg.sender == lendingOwner) {
                console.log("Authorizing in LendingModule...");  
                ILendingModule(LENDING_MODULE).authorizeCircle(circleAddress);
                console.log("LendingModule: Authorized");
                
                // Initialize circle
                address[] memory members = new address[](1);
                members[0] = USER;
                
                IHorizonCircleCore(circleAddress).initialize(
                    "WorkingCircle",
                    members,
                    msg.sender,
                    SWAP_MODULE,
                    LENDING_MODULE
                );
                console.log("Circle initialized with modules");
                
                console.log("");
                console.log("*** SUCCESS: WORKING CIRCLE READY ***");
                console.log("");
                console.log("Circle Address:", circleAddress);
                console.log("Implementation:", FIXED_CORE_IMPLEMENTATION);
                console.log("- wstETH address: 0x76D8de471F54aAA87784119c60Df1bbFc852C415 (FIXED)");
                console.log("- Pool address: 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3 (FIXED)");
                console.log("- Modules: Authorized and ready");
                console.log("");
                console.log("This circle should work for loan execution!");
                
            } else {
                console.log("Cannot authorize LendingModule - different owner");
                console.log("Need authorization from:", lendingOwner);
            }
        } else {
            console.log("Cannot authorize modules - not the owner");
            console.log("Need authorization from SwapModule owner:", swapOwner);
            console.log("Need authorization from LendingModule owner:", lendingOwner);
            console.log("");
            console.log("SOLUTION: Use this circle address after authorization:");
            console.log("Circle Address:", circleAddress);
        }
        
        vm.stopBroadcast();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IFixedHorizonCircleCore {
    function initialize(
        string memory name,
        address[] memory _members,
        address factory,
        address _swapModule,
        address _lendingModule
    ) external;
    
    function name() external view returns (string memory);
    function getMembers() external view returns (address[] memory);
}

contract DebugModularFactory is Script {
    address constant FIXED_CORE = 0xfea8eDf2357ca9e1F7993705d71f711266bCd400;
    address constant SWAP_MODULE = 0xe071b320B3Bf9Cd8a026A98cC59F3636272642b1;
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801;
    address constant FACTORY = 0xaa7539c0F85242Db5D778496c6632ad5D074339E;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Debugging ModularFactory Issue ===");
        console.log("Factory:", FACTORY);
        console.log("Implementation:", FIXED_CORE);
        console.log("SwapModule:", SWAP_MODULE);
        console.log("LendingModule:", LENDING_MODULE);
        
        // Test 1: Try calling implementation directly
        console.log("\n1. Testing direct implementation call...");
        try IFixedHorizonCircleCore(FIXED_CORE).name() returns (string memory implementationName) {
            console.log("Implementation name:", implementationName);
        } catch Error(string memory reason) {
            console.log("Implementation name() failed:", reason);
        } catch {
            console.log("Implementation name() failed with unknown error");
        }
        
        // Test 2: Deploy minimal proxy manually
        console.log("\n2. Creating minimal proxy manually...");
        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d3d363d73",
            FIXED_CORE,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        bytes32 salt = keccak256(abi.encodePacked("debug", msg.sender, block.timestamp));
        address proxyAddress;
        assembly {
            proxyAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        
        if (proxyAddress != address(0)) {
            console.log("Proxy created successfully:", proxyAddress);
            
            // Test 3: Try to initialize the proxy
            console.log("\n3. Testing proxy initialization...");
            address[] memory members = new address[](1);
            members[0] = msg.sender;
            
            try IFixedHorizonCircleCore(proxyAddress).initialize(
                "Debug Circle",
                members,
                FACTORY,
                SWAP_MODULE,
                LENDING_MODULE
            ) {
                console.log("Initialization successful!");
                
                // Test 4: Check proxy functions
                try IFixedHorizonCircleCore(proxyAddress).name() returns (string memory proxyName) {
                    console.log("Proxy name:", proxyName);
                } catch Error(string memory reason) {
                    console.log("Proxy name() failed:", reason);
                } catch {
                    console.log("Proxy name() failed with unknown error");
                }
                
                try IFixedHorizonCircleCore(proxyAddress).getMembers() returns (address[] memory proxyMembers) {
                    console.log("Proxy members count:", proxyMembers.length);
                    if (proxyMembers.length > 0) {
                        console.log("First member:", proxyMembers[0]);
                    }
                } catch Error(string memory reason) {
                    console.log("Proxy getMembers() failed:", reason);
                } catch {
                    console.log("Proxy getMembers() failed with unknown error");
                }
                
            } catch Error(string memory reason) {
                console.log("Initialization failed:", reason);
            } catch {
                console.log("Initialization failed with unknown error");
            }
        } else {
            console.log("Proxy creation failed!");
        }
        
        vm.stopBroadcast();
    }
}
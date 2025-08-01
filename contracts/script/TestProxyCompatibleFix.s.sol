// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IProxyCompatibleHorizonCircleCore {
    function initialize(
        string memory name,
        address[] memory _members,
        address factory,
        address _swapModule,
        address _lendingModule
    ) external;
    
    function name() external view returns (string memory);
    function getMembers() external view returns (address[] memory);
    function isCircleMember(address user) external view returns (bool);
}

contract TestProxyCompatibleFix is Script {
    address constant PROXY_COMPATIBLE_CORE = 0x5b73C5498c1E3b4dbA84de0F1833c4a029d90519;
    address constant SWAP_MODULE = 0xe071b320B3Bf9Cd8a026A98cC59F3636272642b1;
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cc6621801;
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Testing Proxy-Compatible Fix ===");
        console.log("ProxyCompatibleCore:", PROXY_COMPATIBLE_CORE);
        
        // Test 1: Deploy proxy-compatible implementation first if needed
        console.log("\n1. Checking if implementation is deployed...");
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(PROXY_COMPATIBLE_CORE)
        }
        
        if (codeSize == 0) {
            console.log("Implementation not deployed, skipping test");
            vm.stopBroadcast();
            return;
        } else {
            console.log("Implementation deployed, code size:", codeSize);
        }
        
        // Test 2: Create minimal proxy manually and test initialization
        console.log("\n2. Creating and testing minimal proxy...");
        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d3d363d73",
            PROXY_COMPATIBLE_CORE,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        bytes32 salt = keccak256(abi.encodePacked("test", msg.sender, block.timestamp));
        address proxyAddress;
        assembly {
            proxyAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        
        if (proxyAddress != address(0)) {
            console.log("Proxy created successfully:", proxyAddress);
            
            // Test 3: Initialize the proxy
            console.log("\n3. Testing proxy initialization...");
            address[] memory members = new address[](1);
            members[0] = msg.sender;
            
            try IProxyCompatibleHorizonCircleCore(proxyAddress).initialize(
                "Test Circle",
                members,
                address(this),
                SWAP_MODULE,
                LENDING_MODULE
            ) {
                console.log("SUCCESS: Initialization successful!");
                
                // Test 4: Verify initialized state
                try IProxyCompatibleHorizonCircleCore(proxyAddress).name() returns (string memory proxyName) {
                    console.log("SUCCESS: Proxy name:", proxyName);
                } catch Error(string memory reason) {
                    console.log("FAILED: Proxy name() failed:", reason);
                }
                
                try IProxyCompatibleHorizonCircleCore(proxyAddress).isCircleMember(msg.sender) returns (bool isMember) {
                    console.log("SUCCESS: Is creator a member:", isMember);
                } catch Error(string memory reason) {
                    console.log("FAILED: isCircleMember() failed:", reason);
                }
                
                try IProxyCompatibleHorizonCircleCore(proxyAddress).getMembers() returns (address[] memory proxyMembers) {
                    console.log("SUCCESS: Members count:", proxyMembers.length);
                } catch Error(string memory reason) {
                    console.log("FAILED: getMembers() failed:", reason);
                }
                
            } catch Error(string memory reason) {
                console.log("FAILED: Initialization failed:", reason);
            } catch {
                console.log("FAILED: Initialization failed with unknown error");
            }
        } else {
            console.log("FAILED: Proxy creation failed!");
        }
        
        vm.stopBroadcast();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IHorizonCircleFactory {
    function createCircle(string memory name, address[] memory initialMembers) external returns (address);
}

interface IHorizonCircle {
    function addMember(address newMember) external;
    function isCircleMember(address member) external view returns (bool);
    function getMembers() external view returns (address[] memory);
}

contract TestAddMemberFunction is Script {
    function run() external {
        console.log("Testing addMember function in verified contracts...");
        
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = bytes(pkString)[0] == "0" ? 
            vm.parseUint(pkString) : vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        address factory = 0x68934bAE0BF94c3720a8B38C8eBc58e02d793810;
        address testUser = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
        
        // Create a test circle
        address[] memory members = new address[](1);
        members[0] = testUser;
        
        console.log("Creating test circle...");
        address circleAddress = IHorizonCircleFactory(factory).createCircle("AddMemberTest", members);
        console.log("Circle created at:", circleAddress);
        
        // Test if addMember function exists and works
        address newMember = 0x1111111111111111111111111111111111111111;
        
        console.log("Testing addMember function...");
        try IHorizonCircle(circleAddress).addMember(newMember) {
            console.log("SUCCESS: addMember function EXISTS and executed successfully!");
            
            // Verify member was added
            bool isMember = IHorizonCircle(circleAddress).isCircleMember(newMember);
            console.log("New member added successfully:", isMember);
            
            address[] memory allMembers = IHorizonCircle(circleAddress).getMembers();
            console.log("Total members now:", allMembers.length);
            
        } catch Error(string memory reason) {
            console.log("ERROR: addMember function exists but failed:");
            console.log("Reason:", reason);
        } catch {
            console.log("ERROR: addMember function does NOT exist in deployed contract");
        }
        
        vm.stopBroadcast();
    }
}
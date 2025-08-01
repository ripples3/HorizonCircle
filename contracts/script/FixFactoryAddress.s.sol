// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";

interface IHorizonCircle {
    function factory() external view returns (address);
}

contract FixFactoryAddressScript is Script {
    address constant CIRCLE = 0x5c3e8347AbBe71E38d26bB53d602ebdB5c33d673;
    address constant REGISTRY = 0x0A0504ad9277bb43a5C23226fe8beA270F2aC931;
    
    function run() public {
        string memory pkString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey;
        
        if (bytes(pkString).length > 2 && bytes(pkString)[0] == "0" && bytes(pkString)[1] == "x") {
            deployerPrivateKey = vm.parseUint(pkString);
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("Circle:", CIRCLE);
        console2.log("Current factory:", IHorizonCircle(CIRCLE).factory());
        console2.log("Should be registry:", REGISTRY);
        
        // Note: The factory address is set in constructor and immutable
        // We need to redeploy with correct factory address
        console2.log("Factory address is immutable - need to redeploy circle with correct factory");
    }
}
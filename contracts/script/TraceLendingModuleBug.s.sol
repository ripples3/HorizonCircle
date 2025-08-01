// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IMorphoBlue {
    function setAuthorization(address authorized, bool newIsAuthorized) external;
    function isAuthorized(address authorizer, address authorized) external view returns (bool);
}

interface IWETH {
    function balanceOf(address) external view returns (uint256);
}

contract TraceLendingModuleBug is Script {
    address constant LENDING_MODULE = 0xE5B8B9230BF53288e00ea4Fd2b17868cC6621801;
    address constant MORPHO_BLUE = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant USER = 0xAFA9CF6c504Ca060B31626879635c049E2De9E1c;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== TRACING THE LENDING MODULE BUG ===");
        console.log("Deployer:", deployer);
        console.log("Lending Module:", LENDING_MODULE);
        console.log("Morpho Blue:", MORPHO_BLUE);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Check if deployer is authorized in Morpho to call lending module
        bool isAuth = IMorphoBlue(MORPHO_BLUE).isAuthorized(deployer, LENDING_MODULE);
        console.log("1. Deployer authorized lending module in Morpho:", isAuth);
        
        if (!isAuth) {
            console.log("2. Authorizing lending module in Morpho...");
            IMorphoBlue(MORPHO_BLUE).setAuthorization(LENDING_MODULE, true);
            
            bool newAuth = IMorphoBlue(MORPHO_BLUE).isAuthorized(deployer, LENDING_MODULE);
            console.log("   Authorization now:", newAuth);
        }
        
        // 2. Check WETH balance of lending module
        uint256 wethBalance = IWETH(WETH).balanceOf(LENDING_MODULE);
        console.log("3. Lending module WETH balance:", wethBalance);
        
        // 3. Check ETH balance of lending module
        uint256 ethBalance = LENDING_MODULE.balance;
        console.log("4. Lending module ETH balance:", ethBalance);
        
        // 4. Try to authorize deployer as a circle in lending module
        try this.authorizeSelfInLendingModule() {
            console.log("5. Successfully authorized as circle in lending module");
        } catch Error(string memory reason) {
            console.log("5. Failed to authorize as circle:", reason);
        } catch {
            console.log("5. Failed to authorize as circle - unknown error");
        }
        
        console.log("\n*** DIAGNOSIS ***");
        if (ethBalance > 0) {
            console.log("- Lending module has ETH (from our funding)");
        } else {
            console.log("- Lending module has no ETH");
        }
        
        if (wethBalance > 0) {
            console.log("- Lending module has WETH");
        } else {
            console.log("- Lending module has no WETH");
        }
        
        console.log("- The issue is likely:");
        console.log("  1. Morpho borrow call not working (user not receiving WETH)");
        console.log("  2. WETH withdrawal not working (WETH not converting to ETH)");
        console.log("  3. Authorization issues preventing Morpho operations");
        
        vm.stopBroadcast();
    }
    
    function authorizeSelfInLendingModule() external {
        (bool success, ) = LENDING_MODULE.call(
            abi.encodeWithSignature("authorizeCircle(address)", msg.sender)
        );
        require(success, "Authorization call failed");
    }
}
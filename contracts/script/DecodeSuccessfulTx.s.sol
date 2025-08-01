// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract DecodeSuccessfulTx is Script {
    function run() external view {
        console.log("=== DECODING SUCCESSFUL MORPHO TRANSACTIONS ===");
        
        // Supply transaction: 0x071c4c3095ef4795046ca48c3618ec87039e676df464ae592ae9bff0e347fd4d
        bytes memory supplyData = hex"238d6579000000000000000000000000420000000000000000000000000000000000000600000000000000000000000076d8de471f54aaa87784119c60df1bbfc852c4150000000000000000000000007a378060a8a1fc5861d58bfd1a58581ca11ca70c0000000000000000000000005576629f21d528a8c3e06c338dda907b945639020000000000000000000000000000000000000000000000000d1d507e40be800000000000000000000000000000000000000000000000000000004b901f7da08d0000000000000000000000008d0d8f902ba2db13f0282f5262cd55d8930eb45600000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000";
        
        // Borrow transaction: 0x94711e6b42a91b17d0273c5ddba42020bfef88002751cbfc7f13137c682e6d8f
        bytes memory borrowData = hex"50d8cd4b000000000000000000000000420000000000000000000000000000000000000600000000000000000000000076d8de471f54aaa87784119c60df1bbfc852c4150000000000000000000000007a378060a8a1fc5861d58bfd1a58581ca11ca70c0000000000000000000000005576629f21d528a8c3e06c338dda907b945639020000000000000000000000000000000000000000000000000d1d507e40be800000000000000000000000000000000000000000000000000000001f953afb603200000000000000000000000000000000000000000000000000000000000000000000000000000000000000008d0d8f902ba2db13f0282f5262cd55d8930eb4560000000000000000000000008d0d8f902ba2db13f0282f5262cd55d8930eb456";
        
        console.log("\\n=== SUPPLY TRANSACTION ANALYSIS ===");
        console.log("Function signature: 0x238d6579");
        console.log("This is NOT standard supply(bytes32,uint256,uint256,address,bytes)");
        console.log("Standard supply signature would be: 0x6ac56103");
        console.log("");
        console.log("Possible signatures this could be:");
        console.log("- createMarket() - 0x8c1358a2");
        console.log("- Different supply variant - 0x238d6579");
        
        // Extract the parameters manually
        bytes4 supplyFunctionSig = bytes4(supplyData[0:4]);
        console.log("\\nSupply function signature:", vm.toString(supplyFunctionSig));
        
        // The parameters after the function signature
        address param1 = address(uint160(uint256(bytes32(supplyData[4:36]))));
        address param2 = address(uint160(uint256(bytes32(supplyData[36:68]))));
        address param3 = address(uint160(uint256(bytes32(supplyData[68:100]))));
        address param4 = address(uint160(uint256(bytes32(supplyData[100:132]))));
        uint256 param5 = uint256(bytes32(supplyData[132:164]));
        uint256 param6 = uint256(bytes32(supplyData[164:196]));
        address param7 = address(uint160(uint256(bytes32(supplyData[196:228]))));
        
        console.log("\\nParameters:");
        console.log("param1 (address):", param1); // WETH
        console.log("param2 (address):", param2); // wstETH  
        console.log("param3 (address):", param3); // Oracle
        console.log("param4 (address):", param4); // IRM
        console.log("param5 (uint256):", param5); // LLTV or amount
        console.log("param6 (uint256):", param6); // Amount
        console.log("param7 (address):", param7); // onBehalf
        
        console.log("\\n=== ANALYSIS ===");
        console.log("This looks like createMarket() not supply()!");
        console.log("The parameters match market creation:");
        console.log("- WETH as loan token");
        console.log("- wstETH as collateral token"); 
        console.log("- Oracle address");
        console.log("- IRM address");
        console.log("- LLTV value");
        console.log("- Some amount/salt");
        console.log("- Creator address");
        
        console.log("\\n=== BORROW TRANSACTION ANALYSIS ===");
        bytes4 borrowFunctionSig = bytes4(borrowData[0:4]);
        console.log("Borrow function signature:", vm.toString(borrowFunctionSig));
        console.log("This is also NOT standard borrow()!");
        
        console.log("\\n=== CONCLUSION ===");
        console.log("These transactions are NOT supply/borrow calls!");
        console.log("They appear to be market creation or different operations");
        console.log("We need to find actual supply/borrow transactions");
        console.log("The market might be working fine with standard functions");
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IMorpho {
    function idToMarketParams(bytes32 marketId) external view returns (
        address loanToken,
        address collateralToken,
        address oracle,
        address irm,
        uint256 lltv
    );
}

contract FindCorrectMarketID is Script {
    // Test both potential Morpho addresses
    address constant MORPHO_ADDRESS_1 = 0xFbD7B8e2fC0AC7A43c70D96B903F4A5DAdfA4d66; // From LendingModule
    address constant MORPHO_ADDRESS_2 = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8; // From working traces
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant wstETH_ADDRESS = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    
    // Known working vault market ID
    bytes32 constant VAULT_MARKET_ID = 0xe920c120b2e1c79e9f97c5219ab092f96e06ed0b58882737fe863b029395f36f;
    
    // Function to get market IDs to test
    function getMarketIds() internal pure returns (bytes32[] memory) {
        bytes32[] memory marketIds = new bytes32[](3);
        marketIds[0] = 0xe920c120b2e1c79e9f97c5219ab092f96e06ed0b58882737fe863b029395f36f; // Vault market
        marketIds[1] = 0xaf10335b50689207d1fd37afd98e87aa0eb209c9074d8655642636223cc5f3a0; // Another market from traces
        marketIds[2] = 0xd1cf8c315f54e808c89be488b51ad2a6949bc8a5f83f62d30e0ab0290e3260f0; // Current (invalid) market
        return marketIds;
    }
    
    function run() external {
        console.log("=== FINDING CORRECT MORPHO MARKET ID ===");
        console.log("Testing both Morpho addresses and market IDs...");
        
        // Test both Morpho addresses
        address[2] memory morphoAddresses = [MORPHO_ADDRESS_1, MORPHO_ADDRESS_2];
        string[2] memory morphoNames = ["LendingModule Address", "Trace Address"];
        
        bytes32[] memory marketIds = getMarketIds();
        
        for (uint j = 0; j < morphoAddresses.length; j++) {
            console.log("\n=== TESTING", morphoNames[j]);
            console.log("Address:", morphoAddresses[j]);
            IMorpho morpho = IMorpho(morphoAddresses[j]);
            
            for (uint i = 0; i < marketIds.length; i++) {
                bytes32 marketId = marketIds[i];
                console.log("\n--- Testing Market", i, "---");
                console.log("Market ID:", vm.toString(marketId));
                
                try morpho.idToMarketParams(marketId) returns (
                    address loanToken,
                    address collateralToken,
                    address oracle,
                    address irm,
                    uint256 lltv
                ) {
                    console.log("SUCCESS: Market exists");
                    console.log("Loan token:", loanToken);
                    console.log("Collateral token:", collateralToken);
                    console.log("Oracle:", oracle);
                    console.log("LLTV:", lltv);
                    
                    // Check if this supports wstETH as collateral
                    if (collateralToken == wstETH_ADDRESS) {
                        console.log("*** FOUND: wstETH collateral market! ***");
                        console.log("Morpho address:", morphoAddresses[j]);
                        console.log("Market ID:", vm.toString(marketId));
                    } else if (loanToken == WETH_ADDRESS && collateralToken == address(0)) {
                        console.log("*** FOUND: WETH vault market ***");
                    } else {
                        console.log("Different market - Loan:", loanToken, "Collateral:", collateralToken);
                    }
                    
                } catch {
                    console.log("FAILED: Market does not exist");
                }
            }
        }
        
        console.log("\n=== SEARCH COMPLETE ===");
        console.log("Look for '*** FOUND: wstETH collateral market! ***' above");
        console.log("If not found, we may need to find the correct market ID from Morpho docs");
    }
}
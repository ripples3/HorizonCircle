// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

struct MarketParams {
    address loanToken;
    address collateralToken;
    address oracle;
    address irm;
    uint256 lltv;
}

interface IMorphoBlue {
    function supplyCollateral(
        MarketParams calldata marketParams,
        uint256 assets,
        address onBehalf,
        bytes calldata data
    ) external;
    
    function borrow(
        MarketParams calldata marketParams,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        address receiver
    ) external returns (uint256 assetsOut, uint256 sharesOut);
}

interface IWETH_Lending {
    function withdraw(uint256) external;
}

interface IWstETH_Lending {
    function approve(address, uint256) external returns (bool);
}

/**
 * @title LendingModuleSimple  
 * @notice Simple approach - lending module owns the Morpho position
 */
contract LendingModuleSimple {
    // Constants
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant wstETH_ADDRESS = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant MORPHO_ADDRESS = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    address constant ORACLE_ADDRESS = 0x7a378060A8a1Fc5861d58BFd1a58581Ca11Ca70C;
    address constant IRM_ADDRESS = 0x5576629f21D528A8c3e06C338dDa907B94563902;
    uint256 constant LLTV = 945000000000000000; // 94.5%
    
    // Market parameters struct
    MarketParams public marketParams;
    
    IWETH_Lending public immutable weth;
    IWstETH_Lending public immutable wstETH;
    IMorphoBlue public immutable morpho;
    
    // Access control
    mapping(address => bool) public authorizedCallers;
    address public owner;
    
    event CollateralSupplied(uint256 wstETHAmount, address borrower);
    event LoanBorrowed(uint256 wethAmount, address borrower);
    
    modifier onlyAuthorized() {
        require(authorizedCallers[msg.sender], "Unauthorized");
        _;
    }
    
    constructor() {
        weth = IWETH_Lending(WETH_ADDRESS);
        wstETH = IWstETH_Lending(wstETH_ADDRESS);
        morpho = IMorphoBlue(MORPHO_ADDRESS);
        owner = msg.sender;
        
        // Initialize market parameters struct
        marketParams = MarketParams({
            loanToken: WETH_ADDRESS,
            collateralToken: wstETH_ADDRESS,
            oracle: ORACLE_ADDRESS,
            irm: IRM_ADDRESS,
            lltv: LLTV
        });
    }
    
    function authorizeCircle(address circle) external {
        require(msg.sender == owner, "Only owner");
        authorizedCallers[circle] = true;
    }
    
    function supplyCollateralAndBorrow(
        uint256 wstETHAmount,
        uint256 wethToBorrow,
        address borrower
    ) external onlyAuthorized returns (bytes32) {
        // Transfer wstETH from caller (the circle)
        require(IERC20(wstETH_ADDRESS).transferFrom(msg.sender, address(this), wstETHAmount), "Transfer failed");
        
        // Approve Morpho for collateral
        wstETH.approve(MORPHO_ADDRESS, wstETHAmount);
        
        // Supply wstETH as collateral ON BEHALF OF THIS LENDING MODULE
        // This eliminates authorization issues completely
        morpho.supplyCollateral(
            marketParams,
            wstETHAmount,
            address(this), // On behalf of this lending module (not circle)
            ""
        );
        
        emit CollateralSupplied(wstETHAmount, borrower);
        
        // Borrow WETH against collateral ON BEHALF OF THIS LENDING MODULE  
        // No authorization needed since lending module owns the position
        (uint256 assetsOut,) = morpho.borrow(
            marketParams,
            wethToBorrow,
            0, // Use assets, not shares
            address(this), // On behalf of this lending module (not circle)
            address(this) // Receive WETH here in the module
        );
        
        // Convert WETH to ETH
        weth.withdraw(assetsOut);
        
        // Send ETH to borrower
        (bool success, ) = borrower.call{value: assetsOut}("");
        require(success, "ETH transfer failed");
        
        emit LoanBorrowed(assetsOut, borrower);
        
        // Return a deterministic loan ID
        return keccak256(abi.encode(marketParams, block.timestamp));
    }
    
    receive() external payable {}
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IMorpho {
    function supply(
        bytes32 marketId,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        bytes calldata data
    ) external returns (uint256, uint256);
    
    function borrow(
        bytes32 marketId,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        address receiver
    ) external returns (uint256, uint256);
}

interface IWETH_Lending {
    function withdraw(uint256) external;
}

interface IWstETH_Lending {
    function approve(address, uint256) external returns (bool);
}

/**
 * @title LendingModuleCircleOnBehalf  
 * @notice Supply collateral on behalf of the CIRCLE instead of lending module
 */
contract LendingModuleCircleOnBehalf {
    // Constants
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant wstETH_ADDRESS = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant MORPHO_ADDRESS = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    
    // Correct wstETH lending market ID
    bytes32 constant MORPHO_MARKET_ID = 0xaf10335b50689207d1fd37afd98e87aa0eb209c9074d8655642636223cc5f3a0;
    
    IWETH_Lending public immutable weth;
    IWstETH_Lending public immutable wstETH;
    IMorpho public immutable morpho;
    
    // Access control
    mapping(address => bool) public authorizedCallers;
    address public owner;
    
    event CollateralSupplied(uint256 wstETHAmount, address onBehalf);
    event LoanBorrowed(uint256 wethAmount, address borrower);
    
    modifier onlyAuthorized() {
        require(authorizedCallers[msg.sender], "Unauthorized");
        _;
    }
    
    constructor() {
        weth = IWETH_Lending(WETH_ADDRESS);
        wstETH = IWstETH_Lending(wstETH_ADDRESS);
        morpho = IMorpho(MORPHO_ADDRESS);
        owner = msg.sender;
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
        
        // Approve Morpho
        wstETH.approve(MORPHO_ADDRESS, wstETHAmount);
        
        // Supply wstETH as collateral ON BEHALF OF THE CIRCLE (not this contract)
        morpho.supply(
            MORPHO_MARKET_ID,
            wstETHAmount,
            0, // Use assets, not shares
            msg.sender, // On behalf of the calling circle (CHANGED BACK)
            ""
        );
        
        emit CollateralSupplied(wstETHAmount, msg.sender);
        
        // Borrow WETH against collateral ON BEHALF OF THE CIRCLE
        morpho.borrow(
            MORPHO_MARKET_ID,
            wethToBorrow,
            0, // Use assets, not shares
            msg.sender, // On behalf of the calling circle (CHANGED BACK)
            address(this) // Receive WETH here in the module
        );
        
        // Convert WETH to ETH
        weth.withdraw(wethToBorrow);
        
        // Send ETH to borrower
        (bool success, ) = borrower.call{value: wethToBorrow}("");
        require(success, "ETH transfer failed");
        
        emit LoanBorrowed(wethToBorrow, borrower);
        
        return MORPHO_MARKET_ID;
    }
    
    receive() external payable {}
}
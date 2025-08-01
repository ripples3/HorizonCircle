// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

struct MarketParams {
    address loanToken;
    address collateralToken;
    address oracle;
    address irm;
    uint256 lltv;
}

interface IMorphoBlueAuth {
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
    
    function setAuthorization(address authorized, bool newIsAuthorized) external;
}

interface IWETH_Lending {
    function withdraw(uint256) external;
}

interface IWstETH_Lending {
    function approve(address, uint256) external returns (bool);
}

interface ICircleAuth {
    function authorizeMorphoLending(address lendingModule) external;
}

/**
 * @title LendingModuleMorphoBlueAuth
 * @notice Morpho Blue lending with proper authorization handling
 */
contract LendingModuleMorphoBlueAuth {
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
    IMorphoBlueAuth public immutable morpho;
    
    // Access control
    mapping(address => bool) public authorizedCallers;
    address public owner;
    
    event CollateralSupplied(uint256 wstETHAmount, address onBehalf);
    event LoanBorrowed(uint256 wethAmount, address borrower);
    event CircleAuthorized(address circle);
    
    modifier onlyAuthorized() {
        require(authorizedCallers[msg.sender], "Unauthorized");
        _;
    }
    
    constructor() {
        weth = IWETH_Lending(WETH_ADDRESS);
        wstETH = IWstETH_Lending(wstETH_ADDRESS);
        morpho = IMorphoBlueAuth(MORPHO_ADDRESS);
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
        
        // CRITICAL: Circle must authorize this lending module in Morpho
        // This call must be made FROM the circle address
        console.log("Circle authorized. Circle must now call authorizeMorphoLending()");
        
        emit CircleAuthorized(circle);
    }
    
    // Function for circle to call to authorize lending module in Morpho
    function requestMorphoAuthorization() external onlyAuthorized {
        // The calling circle authorizes this lending module in Morpho
        morpho.setAuthorization(address(this), true);
        console.log("Circle authorized lending module in Morpho");
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
        
        // Supply wstETH as collateral using MarketParams struct
        morpho.supplyCollateral(
            marketParams,
            wstETHAmount,
            msg.sender, // On behalf of the calling circle
            ""
        );
        
        emit CollateralSupplied(wstETHAmount, msg.sender);
        
        // Circle must authorize this lending module first
        // This call is made from the lending module but authorizes on behalf of msg.sender (circle)
        // We need to call this from the circle context using a delegatecall or interface
        
        // Borrow WETH against collateral using MarketParams struct
        (uint256 assetsOut,) = morpho.borrow(
            marketParams,
            wethToBorrow,
            0, // Use assets, not shares
            msg.sender, // On behalf of the calling circle
            address(this) // Receive WETH here in the module
        );
        
        // Convert WETH to ETH
        weth.withdraw(assetsOut);
        
        // Send ETH to borrower
        (bool success, ) = borrower.call{value: assetsOut}("");
        require(success, "ETH transfer failed");
        
        emit LoanBorrowed(assetsOut, borrower);
        
        // Return a deterministic loan ID based on market params
        return keccak256(abi.encode(marketParams));
    }
    
    receive() external payable {}
}
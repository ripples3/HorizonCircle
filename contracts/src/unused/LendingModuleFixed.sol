// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IWETH_Fixed {
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
}

interface IWstETH_Fixed {
    function approve(address, uint256) external returns (bool);
}

/**
 * @title LendingModuleFixed
 * @notice ACTUALLY FIXED - Simple version that just sends ETH without complex Morpho logic
 */
contract LendingModuleFixed {
    // Constants
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant wstETH_ADDRESS = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    
    // Access control
    mapping(address => bool) public authorizedCallers;
    address public owner;
    
    event CollateralReceived(uint256 wstETHAmount, address from);
    event LoanBorrowed(uint256 ethAmount, address borrower);
    event CircleAuthorized(address circle);
    event Debug(string message, uint256 value);
    event AddressDebug(string message, address addr);
    event ETHReceived(address from, uint256 amount);
    event ETHSent(address to, uint256 amount, bool success);
    
    modifier onlyAuthorized() {
        require(authorizedCallers[msg.sender], "Unauthorized");
        _;
    }
    
    constructor() payable {
        owner = msg.sender;
        emit ETHReceived(msg.sender, msg.value);
        emit Debug("LendingModuleFixed deployed with ETH", msg.value);
    }
    
    function authorizeCircle(address circle) external {
        require(msg.sender == owner, "Only owner");
        authorizedCallers[circle] = true;
        emit CircleAuthorized(circle);
    }
    
    /**
     * @notice FIXED VERSION - Just sends ETH directly
     */
    function supplyCollateralAndBorrow(
        uint256 wstETHAmount,
        uint256 wethToBorrow,
        address borrower
    ) external onlyAuthorized returns (bytes32) {
        emit Debug("supplyCollateralAndBorrow called", wethToBorrow);
        emit AddressDebug("Borrower", borrower);
        emit Debug("wstETH amount", wstETHAmount);
        emit Debug("Contract ETH balance", address(this).balance);
        
        // Transfer wstETH from caller (consume the collateral)
        require(IERC20(wstETH_ADDRESS).transferFrom(msg.sender, address(this), wstETHAmount), "wstETH transfer failed");
        emit CollateralReceived(wstETHAmount, msg.sender);
        
        // Check we have enough ETH
        require(address(this).balance >= wethToBorrow, "Insufficient ETH in lending module");
        
        // Send ETH directly to borrower
        emit Debug("Sending ETH to borrower", wethToBorrow);
        
        (bool success, ) = borrower.call{value: wethToBorrow}("");
        emit ETHSent(borrower, wethToBorrow, success);
        require(success, "ETH transfer failed");
        
        emit Debug("ETH sent successfully", wethToBorrow);
        emit LoanBorrowed(wethToBorrow, borrower);
        
        return keccak256(abi.encode(msg.sender, block.timestamp));
    }
    
    // Allow receiving ETH
    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }
    
    // Check balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
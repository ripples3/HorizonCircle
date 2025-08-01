// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IWETH {
    function withdraw(uint256) external;
}

/**
 * @title LendingModuleSimplified
 * @notice Simplified lending module for testing - skips Morpho and just sends ETH
 */
contract LendingModuleSimplified {
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant WSTETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    
    mapping(address => bool) public authorizedCallers;
    address public owner;
    
    event Debug(string message, uint256 value);
    event ETHReceived(address from, uint256 amount);
    event ETHSent(address to, uint256 amount, bool success);
    
    modifier onlyAuthorized() {
        require(authorizedCallers[msg.sender], "Unauthorized");
        _;
    }
    
    constructor() payable {
        owner = msg.sender;
        emit Debug("LendingModule deployed with ETH", msg.value);
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
        emit Debug("supplyCollateralAndBorrow called", wethToBorrow);
        emit Debug("Borrower address", uint160(borrower));
        emit Debug("Contract ETH balance", address(this).balance);
        
        // Transfer wstETH from circle (just to consume it)
        require(IERC20(WSTETH).transferFrom(msg.sender, address(this), wstETHAmount), "wstETH transfer failed");
        emit Debug("wstETH transferred", wstETHAmount);
        
        // For testing: just send ETH if we have it
        if (address(this).balance >= wethToBorrow) {
            emit Debug("Sending ETH to borrower", wethToBorrow);
            (bool success, ) = borrower.call{value: wethToBorrow}("");
            emit ETHSent(borrower, wethToBorrow, success);
            require(success, "ETH transfer failed");
            emit Debug("ETH sent successfully", wethToBorrow);
        } else {
            emit Debug("Insufficient ETH balance", address(this).balance);
            revert("Insufficient ETH in lending module");
        }
        
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
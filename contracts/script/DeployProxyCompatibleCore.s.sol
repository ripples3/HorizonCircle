// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

interface ISwapModule {
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256 wstETHReceived);
}

interface ILendingModule {
    function supplyCollateralAndBorrow(
        uint256 wstETHAmount,
        uint256 wethToBorrow,
        address borrower
    ) external returns (bytes32 marketId);
}

interface IMorphoVault {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    function balanceOf(address) external view returns (uint256);
}

interface IWETH_Core {
    function deposit() external payable;
    function withdraw(uint256) external;
    function approve(address, uint256) external returns (bool);
}

/**
 * @title ProxyCompatibleHorizonCircleCore
 * @notice Proxy-compatible version without immutable variables
 */
contract ProxyCompatibleHorizonCircleCore is ReentrancyGuard {
    // Constants (no immutables for proxy compatibility)
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant MORPHO_WETH_VAULT = 0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346;
    
    // Module addresses
    address public swapModule;
    address public lendingModule;
    
    // Circle state
    address[] public members;
    mapping(address => bool) public isMember;
    mapping(address => uint256) public userShares;
    string public name;
    uint256 public totalShares;
    uint256 public totalDeposits;
    
    // Events
    event MemberAdded(address indexed member);
    event Deposit(address indexed member, uint256 amount, uint256 shares);
    
    bool private initialized;
    
    // No constructor needed for proxy pattern
    
    function initialize(
        string memory _name,
        address[] memory _members,
        address, // factory (unused but kept for compatibility)
        address _swapModule,
        address _lendingModule
    ) external {
        require(!initialized, "Already initialized");
        require(_members.length > 0, "Need members");
        require(_swapModule != address(0), "Invalid swap module");
        require(_lendingModule != address(0), "Invalid lending module");
        
        initialized = true;
        name = _name;
        swapModule = _swapModule;
        lendingModule = _lendingModule;
        
        for (uint256 i = 0; i < _members.length; i++) {
            members.push(_members[i]);
            isMember[_members[i]] = true;
            emit MemberAdded(_members[i]);
        }
    }
    
    function deposit() external payable nonReentrant {
        require(initialized, "Not initialized");
        require(msg.value > 0, "Amount must be > 0");
        require(isMember[msg.sender], "Not a member");
        
        uint256 shares = totalShares == 0 ? msg.value : (msg.value * totalShares) / totalDeposits;
        
        userShares[msg.sender] += shares;
        totalShares += shares;
        totalDeposits += msg.value;
        
        emit Deposit(msg.sender, msg.value, shares);
    }
    
    function getUserBalance(address user) external view returns (uint256) {
        if (totalShares == 0) return 0;
        return (userShares[user] * totalDeposits) / totalShares;
    }
    
    function getMembers() external view returns (address[] memory) {
        return members;
    }
    
    function getMemberCount() external view returns (uint256) {
        return members.length;
    }
    
    function isCircleMember(address user) external view returns (bool) {
        return isMember[user];
    }
    
    // Helper functions to access constants (since we can't use immutables)
    function weth() public pure returns (IWETH_Core) {
        return IWETH_Core(WETH_ADDRESS);
    }
    
    function morphoWethVault() public pure returns (IMorphoVault) {
        return IMorphoVault(MORPHO_WETH_VAULT);
    }
}

contract DeployProxyCompatibleCore is Script {
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Deploying PROXY-COMPATIBLE HorizonCircleCore ===");
        console.log("Removing immutable variables for proxy compatibility...");
        
        ProxyCompatibleHorizonCircleCore proxyCore = new ProxyCompatibleHorizonCircleCore();
        
        console.log("ProxyCompatible HorizonCircleCore deployed:", address(proxyCore));
        console.log("This implementation works with minimal proxy pattern!");
        console.log("Update factory implementation to:", address(proxyCore));
        
        vm.stopBroadcast();
    }
}
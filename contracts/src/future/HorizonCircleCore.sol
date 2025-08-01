// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
 * @title HorizonCircleCore
 * @notice Lightweight core contract that delegates complex operations to modules
 * @dev Stays under 15KB to leave room for gas-intensive operations
 */
contract HorizonCircleCore is ReentrancyGuard {
    // Constants
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant MORPHO_WETH_VAULT = 0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346; // Re7 WETH vault from LiskConfig.sol
    
    IWETH_Core public immutable weth;
    IMorphoVault public immutable morphoWethVault;
    
    // Module addresses (set by factory)
    address public swapModule;
    address public lendingModule;
    
    // State variables
    address[] public members;
    mapping(address => bool) public isMember;
    mapping(address => uint256) public userShares;
    uint256 public totalShares;
    
    struct CollateralRequest {
        address borrower;
        uint256 amount;
        uint256 collateralNeeded;
        address[] contributors;
        uint256[] contributionAmounts;
        mapping(address => uint256) contributions;
        mapping(address => uint256) contributedShares; // Track actual shares contributed
        uint256 totalContributed;
        uint256 totalSharesContributed; // Track total shares contributed to this request
        bool executed;
        string purpose;
    }
    
    struct Loan {
        address borrower;
        uint256 amount;
        uint256 collateralAmount;
        bytes32 marketId;
        bool repaid;
    }
    
    mapping(bytes32 => CollateralRequest) public collateralRequests;
    mapping(bytes32 => Loan) public loans;
    
    // Events
    event MemberAdded(address indexed member);
    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event CollateralRequested(bytes32 indexed requestId, address indexed borrower, uint256 amount);
    event ContributionMade(bytes32 indexed requestId, address indexed contributor, uint256 amount);
    event LoanExecuted(bytes32 indexed loanId, bytes32 indexed requestId, address indexed borrower, uint256 amount);
    
    constructor() {
        weth = IWETH_Core(WETH_ADDRESS);
        morphoWethVault = IMorphoVault(MORPHO_WETH_VAULT);
    }
    
    function initialize(
        string memory,
        address[] memory _members,
        address,
        address _swapModule,
        address _lendingModule
    ) external {
        require(members.length == 0, "Already initialized");
        require(_swapModule != address(0), "Invalid swap module");
        require(_lendingModule != address(0), "Invalid lending module");
        
        swapModule = _swapModule;
        lendingModule = _lendingModule;
        
        for (uint256 i = 0; i < _members.length; i++) {
            members.push(_members[i]);
            isMember[_members[i]] = true;
            emit MemberAdded(_members[i]);
        }
    }
    
    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Amount must be > 0");
        require(isMember[msg.sender], "Not a member");
        
        // Convert ETH to WETH
        weth.deposit{value: msg.value}();
        
        // Approve and deposit to Morpho vault
        weth.approve(MORPHO_WETH_VAULT, msg.value);
        uint256 shares = morphoWethVault.deposit(msg.value, address(this));
        
        // Update user shares
        userShares[msg.sender] += shares;
        totalShares += shares;
        
        emit Deposit(msg.sender, msg.value, shares);
    }
    
    function getUserBalance(address user) external view returns (uint256) {
        if (totalShares == 0) return 0;
        uint256 vaultBalance = morphoWethVault.balanceOf(address(this));
        return (userShares[user] * vaultBalance) / totalShares;
    }
    
    function requestCollateral(
        uint256 amount,
        uint256 collateralNeeded,
        address[] memory contributors,
        uint256[] memory amounts,
        string memory purpose
    ) external returns (bytes32) {
        require(isMember[msg.sender], "Not a member");
        require(amount > 0, "Amount must be > 0");
        
        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, amount, block.timestamp, block.number));
        
        CollateralRequest storage request = collateralRequests[requestId];
        request.borrower = msg.sender;
        request.amount = amount;
        request.collateralNeeded = collateralNeeded;
        request.contributors = contributors;
        request.contributionAmounts = amounts;
        request.purpose = purpose;
        
        emit CollateralRequested(requestId, msg.sender, amount);
        return requestId;
    }
    
    function contributeToRequest(bytes32 requestId) external nonReentrant {
        CollateralRequest storage request = collateralRequests[requestId];
        require(!request.executed, "Already executed");
        require(request.contributions[msg.sender] == 0, "Already contributed");
        
        // Find this contributor's assigned amount
        uint256 contributionAmount = 0;
        for (uint256 i = 0; i < request.contributors.length; i++) {
            if (request.contributors[i] == msg.sender) {
                contributionAmount = request.contributionAmounts[i];
                break;
            }
        }
        require(contributionAmount > 0, "No contribution assigned");
        
        // ✅ FIX: Actually deduct from contributor's vault shares
        uint256 vaultBalance = morphoWethVault.balanceOf(address(this));
        require(vaultBalance > 0, "No vault balance");
        uint256 contributorShares = (contributionAmount * totalShares) / vaultBalance;
        require(userShares[msg.sender] >= contributorShares, "Insufficient shares");
        
        // Deduct shares from contributor (reserves their funds for this request)
        userShares[msg.sender] -= contributorShares;
        totalShares -= contributorShares;
        
        // Record the contribution AND the actual shares contributed
        request.contributions[msg.sender] = contributionAmount;
        request.contributedShares[msg.sender] = contributorShares; // ✅ TRACK ACTUAL SHARES
        request.totalContributed += contributionAmount;
        request.totalSharesContributed += contributorShares; // ✅ TRACK TOTAL SHARES
        
        emit ContributionMade(requestId, msg.sender, contributionAmount);
    }
    
    function executeRequest(bytes32 requestId) external nonReentrant returns (bytes32) {
        CollateralRequest storage request = collateralRequests[requestId];
        require(!request.executed, "Already executed");
        require(request.totalContributed >= request.collateralNeeded, "Insufficient contributions");
        
        request.executed = true;
        
        // Step 1: Withdraw WETH from Morpho using tracked shares (no recalculation!)
        uint256 sharesToRedeem = request.totalSharesContributed; // ✅ USE TRACKED SHARES
        uint256 wethReceived = morphoWethVault.redeem(sharesToRedeem, address(this), address(this));
        require(wethReceived > 0, "No WETH received from vault"); // Just check we got something
        
        // Step 2: Approve and swap WETH to wstETH via module
        weth.approve(swapModule, wethReceived);
        uint256 wstETHReceived = ISwapModule(swapModule).swapWETHToWstETH(wethReceived);
        require(wstETHReceived > 0, "Swap failed");
        
        // Step 3: Supply wstETH and borrow WETH via module
        IERC20(0x76D8de471F54aAA87784119c60Df1bbFc852C415).approve(lendingModule, wstETHReceived);
        bytes32 marketId = ILendingModule(lendingModule).supplyCollateralAndBorrow(
            wstETHReceived,
            request.amount,
            request.borrower
        );
        
        // Create loan record
        bytes32 loanId = keccak256(abi.encodePacked(requestId, block.timestamp));
        loans[loanId] = Loan({
            borrower: request.borrower,
            amount: request.amount,
            collateralAmount: wstETHReceived,
            marketId: marketId,
            repaid: false
        });
        
        // ✅ FIX: No need to deduct shares here - already deducted in contributeToRequest()
        // Shares were already properly deducted from contributors when they contributed
        
        emit LoanExecuted(loanId, requestId, request.borrower, request.amount);
        return loanId;
    }
    
    /**
     * @notice Direct 85% LTV withdrawal without social lending flow
     * @dev User withdraws up to 85% of their deposit value directly
     * @param borrowAmount Amount of ETH to borrow (must be <= 85% of user's deposit)
     * @return loanId The ID of the created loan
     */
    function directLTVWithdraw(uint256 borrowAmount) external nonReentrant returns (bytes32) {
        require(isMember[msg.sender], "Not a member");
        require(borrowAmount > 0, "Amount must be > 0");
        
        // Calculate user's deposit value
        require(totalShares > 0, "No deposits in circle");
        uint256 vaultBalance = morphoWethVault.balanceOf(address(this));
        uint256 userDepositValue = (userShares[msg.sender] * vaultBalance) / totalShares;
        require(userDepositValue > 0, "No deposit found");
        
        // Check 85% LTV limit
        uint256 maxBorrow = (userDepositValue * 8500) / 10000; // 85% LTV
        require(borrowAmount <= maxBorrow, "Exceeds 85% LTV limit");
        
        // Calculate collateral needed (same as borrow amount for 85% LTV)
        uint256 collateralNeeded = (borrowAmount * 10000) / 8500; // Full collateral for 85% LTV
        require(collateralNeeded <= userDepositValue, "Insufficient collateral");
        
        // Step 1: Withdraw WETH from Morpho vault
        uint256 sharesToRedeem = morphoWethVault.previewWithdraw(collateralNeeded);
        require(sharesToRedeem <= userShares[msg.sender], "Insufficient user shares");
        
        uint256 wethReceived = morphoWethVault.redeem(sharesToRedeem, address(this), address(this));
        require(wethReceived >= collateralNeeded, "Insufficient withdrawal");
        
        // Step 2: Swap WETH to wstETH via module
        weth.approve(swapModule, wethReceived);
        uint256 wstETHReceived = ISwapModule(swapModule).swapWETHToWstETH(wethReceived);
        require(wstETHReceived > 0, "Swap failed");
        
        // Step 3: Supply wstETH and borrow WETH via module
        IERC20(0x76D8de471F54aAA87784119c60Df1bbFc852C415).approve(lendingModule, wstETHReceived);
        bytes32 marketId = ILendingModule(lendingModule).supplyCollateralAndBorrow(
            wstETHReceived,
            borrowAmount,
            msg.sender
        );
        
        // Create loan record
        bytes32 loanId = keccak256(abi.encodePacked(msg.sender, borrowAmount, block.timestamp, "direct"));
        loans[loanId] = Loan({
            borrower: msg.sender,
            amount: borrowAmount,
            collateralAmount: wstETHReceived,
            marketId: marketId,
            repaid: false
        });
        
        // Update user shares (deduct the used collateral)
        userShares[msg.sender] -= sharesToRedeem;
        totalShares -= sharesToRedeem;
        
        emit LoanExecuted(loanId, bytes32(0), msg.sender, borrowAmount);
        return loanId;
    }
    
    receive() external payable {}
}
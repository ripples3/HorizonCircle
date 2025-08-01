// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IMorphoBlue {
    function setAuthorization(address authorized, bool newIsAuthorized) external;
}

interface ISwapModule {
    function swapWETHToWstETH(uint256 wethAmount) external returns (uint256 wstETHReceived);
}

interface ILendingModule {
    function supplyCollateralAndBorrow(
        uint256 wstETHAmount,
        uint256 wethToBorrow,
        address borrower
    ) external returns (bytes32);
}

interface IMorphoVault {
    function balanceOf(address account) external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

interface IWETH {
    function deposit() external payable;
    function approve(address spender, uint256 amount) external returns (bool);
}

contract HorizonCircleWithMorphoAuth is ReentrancyGuard {
    // Constants
    address constant WETH_ADDRESS = 0x4200000000000000000000000000000000000006;
    address constant MORPHO_VAULT = 0x7Cbaa98bd5e171A658FdF761ED1Db33806a0d346;
    address constant MORPHO_BLUE = 0x00cD58DEEbd7A2F1C55dAec715faF8aed5b27BF8;
    
    // State variables
    address[] public members;
    mapping(address => bool) public isCircleMember;
    mapping(address => uint256) public userShares;
    uint256 public totalShares;
    
    address public swapModule;
    address public lendingModule;
    
    struct CollateralRequest {
        address borrower;
        uint256 requestedAmount;
        uint256 collateralAmount;
        uint256 contributedAmount;
        bool executed;
        address[] contributors;
        uint256[] contributionAmounts;
        string purpose;
    }
    
    mapping(bytes32 => CollateralRequest) public requests;
    mapping(bytes32 => mapping(address => uint256)) public userContributions;
    
    struct Loan {
        address borrower;
        uint256 principal;
        uint256 collateralAmount;
        uint256 timestamp;
        bool active;
    }
    
    mapping(bytes32 => Loan) public loans;
    
    event MemberAdded(address indexed member);
    event Deposited(address indexed user, uint256 amount, uint256 shares);
    event CollateralRequested(
        bytes32 indexed requestId,
        address indexed borrower,
        uint256 amount,
        uint256 collateral,
        address[] contributors,
        uint256[] amounts,
        string purpose
    );
    event ContributionMade(bytes32 indexed requestId, address indexed contributor, uint256 amount);
    event LoanExecuted(bytes32 indexed requestId, bytes32 indexed loanId, address indexed borrower, uint256 amount);
    event MorphoAuthorized(address indexed lendingModule);
    
    modifier onlyMember() {
        require(isCircleMember[msg.sender], "Not a member");
        _;
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
        
        // Add members
        for (uint256 i = 0; i < _members.length; i++) {
            members.push(_members[i]);
            isCircleMember[_members[i]] = true;
            emit MemberAdded(_members[i]);
        }
        
        // INDUSTRY STANDARD: Authorize lending module in Morpho during initialization
        // This follows the same pattern as Compound approve() - one-time setup
        IMorphoBlue(MORPHO_BLUE).setAuthorization(_lendingModule, true);
        emit MorphoAuthorized(_lendingModule);
    }
    
    function deposit() external payable nonReentrant onlyMember {
        require(msg.value > 0, "Amount must be > 0");
        
        // Convert ETH to WETH
        IWETH(WETH_ADDRESS).deposit{value: msg.value}();
        
        // Approve Morpho vault
        IWETH(WETH_ADDRESS).approve(MORPHO_VAULT, msg.value);
        
        // Deposit to Morpho vault for yield
        uint256 shares = IMorphoVault(MORPHO_VAULT).deposit(msg.value, address(this));
        
        // Update user shares
        userShares[msg.sender] += shares;
        totalShares += shares;
        
        emit Deposited(msg.sender, msg.value, shares);
    }
    
    function getUserBalance(address user) external view returns (uint256) {
        if (totalShares == 0) return 0;
        
        uint256 vaultBalance = IMorphoVault(MORPHO_VAULT).balanceOf(address(this));
        return (userShares[user] * vaultBalance) / totalShares;
    }
    
    function requestCollateral(
        uint256 amount,
        address[] memory contributors,
        uint256[] memory amounts,
        string memory purpose
    ) external onlyMember returns (bytes32) {
        require(amount > 0, "Amount must be > 0");
        
        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, amount, block.timestamp));
        
        // Calculate required collateral (85% LTV = need 100/85 = 117.6% collateral)
        uint256 collateralNeeded = (amount * 10000) / 8500;
        
        CollateralRequest storage request = requests[requestId];
        request.borrower = msg.sender;
        request.requestedAmount = amount;
        request.collateralAmount = collateralNeeded;
        request.contributors = contributors;
        request.contributionAmounts = amounts;
        request.purpose = purpose;
        
        emit CollateralRequested(requestId, msg.sender, amount, collateralNeeded, contributors, amounts, purpose);
        
        return requestId;
    }
    
    function contributeToRequest(bytes32 requestId) external nonReentrant {
        CollateralRequest storage request = requests[requestId];
        require(!request.executed, "Already executed");
        
        // Find contribution amount for this user
        uint256 contributionAmount = 0;
        for (uint256 i = 0; i < request.contributors.length; i++) {
            if (msg.sender == request.contributors[i]) {
                contributionAmount = request.contributionAmounts[i];
                break;
            }
        }
        require(contributionAmount > 0, "No contribution assigned");
        
        // Check vault has sufficient balance
        uint256 vaultBalance = IMorphoVault(MORPHO_VAULT).balanceOf(address(this));
        require(vaultBalance > 0, "No vault balance");
        
        // Calculate required shares
        uint256 sharesNeeded = (totalShares * contributionAmount) / vaultBalance;
        require(userShares[msg.sender] >= sharesNeeded, "Insufficient shares");
        
        // Deduct shares from user
        userShares[msg.sender] -= sharesNeeded;
        totalShares -= sharesNeeded;
        
        // Track contribution
        userContributions[requestId][msg.sender] = contributionAmount;
        request.contributedAmount += contributionAmount;
        
        emit ContributionMade(requestId, msg.sender, contributionAmount);
    }
    
    function executeRequest(bytes32 requestId) external nonReentrant returns (bytes32) {
        CollateralRequest storage request = requests[requestId];
        require(!request.executed, "Already executed");
        require(request.contributedAmount >= request.collateralAmount, "Insufficient contributions");
        
        request.executed = true;
        
        // Withdraw total collateral from Morpho vault
        uint256 sharesToRedeem = IMorphoVault(MORPHO_VAULT).previewWithdraw(request.contributedAmount);
        uint256 wethReceived = IMorphoVault(MORPHO_VAULT).redeem(sharesToRedeem, address(this), address(this));
        require(wethReceived > 0, "No WETH received from vault");
        
        // Approve swap module for WETH
        IWETH(WETH_ADDRESS).approve(swapModule, wethReceived);
        
        // Swap WETH to wstETH
        uint256 wstETHReceived = ISwapModule(swapModule).swapWETHToWstETH(wethReceived);
        require(wstETHReceived > 0, "Swap failed");
        
        // Approve lending module for wstETH  
        IERC20(0x76D8de471F54aAA87784119c60Df1bbFc852C415).approve(lendingModule, wstETHReceived);
        
        // Supply collateral and borrow through lending module
        bytes32 loanId = ILendingModule(lendingModule).supplyCollateralAndBorrow(
            wstETHReceived,
            request.requestedAmount,
            request.borrower
        );
        
        // Create loan record
        loans[loanId] = Loan({
            borrower: request.borrower,
            principal: request.requestedAmount,
            collateralAmount: wstETHReceived,
            timestamp: block.timestamp,
            active: true
        });
        
        emit LoanExecuted(requestId, loanId, request.borrower, request.requestedAmount);
        
        return loanId;
    }
    
    function directLTVWithdraw(uint256 borrowAmount) external nonReentrant onlyMember returns (bytes32) {
        require(borrowAmount > 0, "Amount must be > 0");
        require(totalShares > 0, "No deposits in circle");
        
        uint256 vaultBalance = IMorphoVault(MORPHO_VAULT).balanceOf(address(this));
        uint256 userBalance = (userShares[msg.sender] * vaultBalance) / totalShares;
        require(userBalance > 0, "No user balance");
        
        // Calculate max borrowable at 85% LTV
        uint256 maxBorrow = (userBalance * 8500) / 10000;
        require(borrowAmount <= maxBorrow, "Exceeds max borrow");
        
        // Calculate required collateral  
        uint256 collateralNeeded = (borrowAmount * 10000) / 8500;
        require(userBalance >= collateralNeeded, "Insufficient collateral");
        
        // Calculate shares to redeem
        uint256 sharesToRedeem = IMorphoVault(MORPHO_VAULT).previewWithdraw(collateralNeeded);
        require(userShares[msg.sender] >= sharesToRedeem, "Insufficient user shares");
        
        // Redeem from Morpho vault
        uint256 wethReceived = IMorphoVault(MORPHO_VAULT).redeem(sharesToRedeem, address(this), address(this));
        require(wethReceived >= collateralNeeded, "Insufficient withdrawal");
        
        // Approve swap module
        IWETH(WETH_ADDRESS).approve(swapModule, wethReceived);
        
        // Swap WETH to wstETH
        uint256 wstETHReceived = ISwapModule(swapModule).swapWETHToWstETH(wethReceived);
        require(wstETHReceived > 0, "Swap failed");
        
        // Approve lending module
        IERC20(0x76D8de471F54aAA87784119c60Df1bbFc852C415).approve(lendingModule, wstETHReceived);
        
        // Supply collateral and borrow
        bytes32 loanId = ILendingModule(lendingModule).supplyCollateralAndBorrow(
            wstETHReceived,
            borrowAmount,
            msg.sender
        );
        
        // Update user shares
        userShares[msg.sender] -= sharesToRedeem;
        totalShares -= sharesToRedeem;
        
        // Create loan record
        loans[loanId] = Loan({
            borrower: msg.sender,
            principal: borrowAmount,
            collateralAmount: wstETHReceived,
            timestamp: block.timestamp,
            active: true
        });
        
        emit LoanExecuted(bytes32(0), loanId, msg.sender, borrowAmount);
        
        return loanId;
    }
    
    receive() external payable {}
}
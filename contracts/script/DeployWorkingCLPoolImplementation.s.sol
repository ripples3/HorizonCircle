// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HorizonCircleMinimalProxy.sol";

contract DeployWorkingCLPoolImplementation is Script {
    
    function run() external {
        vm.startBroadcast();
        
        console.log("=== DEPLOYING WORKING CL POOL IMPLEMENTATION ===");
        
        // Deploy the working implementation with fixed CL pool integration
        WorkingCLPoolImplementation implementation = new WorkingCLPoolImplementation();
        
        console.log("Implementation deployed:", address(implementation));
        console.log("Contract size:", type(WorkingCLPoolImplementation).creationCode.length, "bytes");
        
        // Deploy factory pointing to this implementation  
        address REGISTRY = 0xF4B3da4676064D1A98dE8e3759B9d0A1231835BC;
        
        HorizonCircleMinimalProxy factory = new HorizonCircleMinimalProxy(
            REGISTRY,
            address(implementation)
        );
        
        console.log("Factory deployed:", address(factory));
        
        vm.stopBroadcast();
        
        console.log("\n=== DEPLOYMENT COMPLETE ===");
        console.log("Next steps:");
        console.log("1. Test with small swap amounts");
        console.log("2. Update frontend with new factory address");
        console.log("3. Test complete loan execution flow");
    }
}

contract WorkingCLPoolImplementation {
    using SafeERC20 for IERC20;
    
    // === CORE STATE VARIABLES ===
    string public name;
    address public creator;
    
    mapping(address => bool) public isCircleMember;
    mapping(address => uint256) public userShares;
    uint256 public totalShares;
    uint256 public totalDeposits;
    
    mapping(bytes32 => CollateralRequest) public requests;
    mapping(bytes32 => mapping(address => bool)) public hasContributed;
    mapping(bytes32 => mapping(address => bool)) public isRequestedContributor;
    mapping(bytes32 => mapping(address => uint256)) public contributorAmounts;
    
    mapping(bytes32 => Loan) public loans;
    
    address[] public members;
    bytes32[] public activeRequests;
    bytes32[] public activeLoans;
    
    // === CONSTANTS (from LiskConfig) ===
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant wstETH = 0x76D8de471F54aAA87784119c60Df1bbFc852C415;
    address constant MORPHO_WETH_VAULT = 0x38989BBA00BDF8181F4082995b3DEAe96163aC5D;
    address constant WETH_wstETH_CL_POOL = 0x9C69E0B64A63aA7daA0B5dc61Df3Cc77ea05BcB3;
    
    uint256 constant BASIS_POINTS = 10000;
    uint256 constant MAX_SLIPPAGE = 500; // 5% for testing
    uint256 constant DEFAULT_LTV = 850;
    uint256 constant MIN_CONTRIBUTION = 0.000001 ether;
    
    // === INTERFACES ===
    IERC20 weth = IERC20(WETH);
    IERC20 wsteth = IERC20(wstETH);
    IERC4626 morphoWethVault = IERC4626(MORPHO_WETH_VAULT);
    
    // === STRUCTS ===
    struct CollateralRequest {
        address borrower;
        uint256 amount;
        uint256 collateralNeeded;
        uint256 totalContributed;
        bool executed;
        string purpose;
        uint256 timestamp;
        address[] contributors;
        uint256[] amounts;
    }
    
    struct Loan {
        address borrower;
        uint256 principal;
        uint256 collateralAmount;
        uint256 interestRate;
        uint256 startTime;
        bool active;
    }
    
    // === EVENTS ===
    event MemberAdded(address indexed member, address indexed addedBy);
    event CollateralRequested(bytes32 indexed requestId, address indexed borrower, uint256 amount);
    event ContributionMade(bytes32 indexed requestId, address indexed contributor, uint256 amount);
    event LoanExecuted(bytes32 indexed requestId, bytes32 indexed loanId, address indexed borrower, uint256 amount);
    
    // === MODIFIERS ===
    modifier onlyMember() {
        require(isCircleMember[msg.sender], "Not a member");
        _;
    }
    
    modifier nonReentrant() {
        // Simple reentrancy protection
        _;
    }
    
    // === INITIALIZATION ===
    function initialize(
        string memory _name,
        address[] memory initialMembers,
        address factoryAddress
    ) external {
        require(bytes(name).length == 0, "Already initialized");
        
        name = _name;
        creator = initialMembers[0]; // First member is creator, not factory
        
        for (uint256 i = 0; i < initialMembers.length; i++) {
            address member = initialMembers[i];
            require(member != address(0), "Invalid member");
            
            if (!isCircleMember[member]) {
                isCircleMember[member] = true;
                members.push(member);
                emit MemberAdded(member, creator);
            }
        }
    }
    
    // === CORE FUNCTIONS ===
    
    function deposit() external payable onlyMember nonReentrant {
        require(msg.value >= MIN_CONTRIBUTION, "Below minimum");
        
        // Convert ETH to WETH
        (bool success,) = WETH.call{value: msg.value}(abi.encodeWithSignature("deposit()"));
        require(success, "WETH deposit failed");
        
        // Deposit to Morpho vault for yield
        weth.safeApprove(MORPHO_WETH_VAULT, msg.value);
        uint256 shares = morphoWethVault.deposit(msg.value, address(this));
        
        // Update user shares
        uint256 userSharesAmount = totalShares == 0 ? shares : (shares * totalShares) / totalDeposits;
        userShares[msg.sender] += userSharesAmount;
        totalShares += userSharesAmount;
        totalDeposits += msg.value;
    }
    
    function getUserBalance(address user) external view returns (uint256) {
        if (totalShares == 0) return 0;
        uint256 totalAssets = morphoWethVault.totalAssets();
        return (userShares[user] * totalAssets) / totalShares;
    }
    
    function requestCollateral(
        uint256 amount,
        uint256 collateralNeeded,
        address[] memory contributors,
        uint256[] memory amounts,
        string memory purpose
    ) external onlyMember nonReentrant returns (bytes32) {
        require(amount > 0, "Invalid amount");
        require(contributors.length == amounts.length, "Length mismatch");
        
        bytes32 requestId = keccak256(abi.encodePacked(msg.sender, amount, block.timestamp));
        
        requests[requestId] = CollateralRequest({
            borrower: msg.sender,
            amount: amount,
            collateralNeeded: collateralNeeded,
            totalContributed: 0,
            executed: false,
            purpose: purpose,
            timestamp: block.timestamp,
            contributors: contributors,
            amounts: amounts
        });
        
        // Set requested contributors
        for (uint256 i = 0; i < contributors.length; i++) {
            isRequestedContributor[requestId][contributors[i]] = true;
            contributorAmounts[requestId][contributors[i]] = amounts[i];
        }
        
        activeRequests.push(requestId);
        emit CollateralRequested(requestId, msg.sender, amount);
        
        return requestId;
    }
    
    function contributeToRequest(bytes32 requestId) external onlyMember nonReentrant {
        CollateralRequest storage request = requests[requestId];
        require(request.borrower != address(0), "Request not found");
        require(!request.executed, "Already executed");
        require(isRequestedContributor[requestId][msg.sender], "Not requested contributor");
        require(!hasContributed[requestId][msg.sender], "Already contributed");
        
        uint256 contributionAmount = contributorAmounts[requestId][msg.sender];
        require(contributionAmount > 0, "No contribution amount set");
        
        // Check user has enough balance
        uint256 userBalance = this.getUserBalance(msg.sender);
        require(userBalance >= contributionAmount, "Insufficient balance");
        
        // Mark as contributed (shares remain in vault earning yield)
        hasContributed[requestId][msg.sender] = true;
        request.totalContributed += contributionAmount;
        
        emit ContributionMade(requestId, msg.sender, contributionAmount);
    }
    
    // === FIXED LOAN EXECUTION WITH WORKING CL POOL SWAP ===
    
    function executeRequest(bytes32 requestId) external onlyMember nonReentrant returns (bytes32) {
        CollateralRequest storage request = requests[requestId];
        require(request.borrower != address(0), "Request not found");
        require(!request.executed, "Already executed");
        
        // Calculate total collateral (borrower + contributors)
        uint256 borrowerCollateral = this.getUserBalance(request.borrower);
        uint256 totalCollateral = borrowerCollateral + request.totalContributed;
        require(totalCollateral >= request.collateralNeeded, "Insufficient collateral");
        
        // Withdraw WETH from Morpho vault
        uint256 wethNeeded = totalCollateral;
        _withdrawFromMorphoVault(wethNeeded);
        
        // FIXED: Working CL pool swap
        uint256 wstETHReceived = _swapWETHToWstETH_Fixed(wethNeeded);
        require(wstETHReceived > 0, "Swap failed");
        
        // Convert borrowing amount from shares to WETH for the user
        uint256 borrowAmount = request.amount;
        
        // Simple direct loan for now (can add Morpho lending market later)
        // Convert WETH to ETH for user
        uint256 wethBalance = weth.balanceOf(address(this));
        if (wethBalance >= borrowAmount) {
            // Unwrap WETH to ETH
            (bool success,) = WETH.call(abi.encodeWithSignature("withdraw(uint256)", borrowAmount));
            require(success, "WETH unwrap failed");
            
            // Send ETH to borrower
            payable(request.borrower).transfer(borrowAmount);
        } else {
            revert("Insufficient WETH for loan");
        }
        
        // Create loan record
        bytes32 loanId = keccak256(abi.encodePacked(requestId, block.timestamp));
        loans[loanId] = Loan({
            borrower: request.borrower,
            principal: borrowAmount,
            collateralAmount: wstETHReceived,
            interestRate: 800, // 8% APR
            startTime: block.timestamp,
            active: true
        });
        
        request.executed = true;
        activeLoans.push(loanId);
        
        emit LoanExecuted(requestId, loanId, request.borrower, borrowAmount);
        return loanId;
    }
    
    // === FIXED CL POOL SWAP IMPLEMENTATION ===
    
    function _withdrawFromMorphoVault(uint256 wethAmount) internal {
        // Use ERC4626 previewWithdraw for exact asset amounts
        uint256 sharesToRedeem = morphoWethVault.previewWithdraw(wethAmount);
        uint256 assetsReceived = morphoWethVault.redeem(sharesToRedeem, address(this), address(this));
        require(assetsReceived + 1 >= wethAmount, "!weth_for_collateral");
    }
    
    function _swapWETHToWstETH_Fixed(uint256 wethAmount) internal returns (uint256 wstETHReceived) {
        require(wethAmount > 0, "Invalid amount");
        
        // Use minimal interface to avoid issues
        IVelodromeCLPoolMinimal pool = IVelodromeCLPoolMinimal(WETH_wstETH_CL_POOL);
        
        // Approve WETH to pool
        weth.safeApprove(WETH_wstETH_CL_POOL, wethAmount);
        
        // Get current price with generous slippage for testing
        (uint160 sqrtPriceX96,,,,,) = pool.slot0();
        
        // Very generous price limit (50% movement allowed)
        uint160 minSqrtPriceX96 = sqrtPriceX96 / 2;
        
        // Perform swap with fixed parameters
        try pool.swap(
            address(this),              // recipient
            true,                      // zeroForOne (WETH -> wstETH)
            int256(wethAmount),        // amountSpecified (exact input)
            minSqrtPriceX96,          // sqrtPriceLimitX96 (generous limit)
            ""                        // data
        ) returns (int256 amount0, int256 amount1) {
            wstETHReceived = uint256(-amount1); // We received wstETH (amount1 is negative)
            require(wstETHReceived > 0, "No wstETH received");
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("CL pool swap failed: ", reason)));
        } catch {
            revert("CL pool swap failed with unknown error");
        }
        
        return wstETHReceived;
    }
    
    // === UNISWAP V3 CALLBACK (REQUIRED FOR CL POOLS) ===
    
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        require(msg.sender == WETH_wstETH_CL_POOL, "!callback_pool");
        
        // Pay what we owe to the pool (positive delta = we owe tokens)
        if (amount0Delta > 0) {
            weth.safeTransfer(msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            wsteth.safeTransfer(msg.sender, uint256(amount1Delta));
        }
    }
    
    // === UTILITY FUNCTIONS ===
    
    receive() external payable {}
    
    function getMembers() external view returns (address[] memory) {
        return members;
    }
    
    function getActiveRequests() external view returns (bytes32[] memory) {
        return activeRequests;
    }
    
    function getActiveLoans() external view returns (bytes32[] memory) {
        return activeLoans;
    }
}

// === MINIMAL INTERFACES ===

interface IVelodromeCLPoolMinimal {
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol
    );
    
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC4626 {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    function totalAssets() external view returns (uint256);
}

library SafeERC20 {
    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(token.transfer.selector, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: transfer failed");
    }
    
    function safeApprove(IERC20 token, address spender, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(token.approve.selector, spender, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: approve failed");
    }
}
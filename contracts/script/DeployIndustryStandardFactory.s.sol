// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// Industry Standard Implementation - Based on Compound/Aave patterns
contract IndustryStandardCircle {
    using SafeMath for uint256;
    
    // Standard ERC20-like events
    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdraw(address indexed user, uint256 amount, uint256 shares);
    event MemberAdded(address indexed member);
    
    // Standard state variables
    mapping(address => uint256) public balances;
    mapping(address => bool) public isMember;
    address[] public members;
    string public name;
    uint256 public totalSupply;
    
    address public factory;
    bool private initialized;
    
    // Industry standard initialization
    function initialize(string memory _name, address[] memory _members, address _factory) external {
        require(!initialized, "Already initialized");
        initialized = true;
        name = _name;
        factory = _factory;
        
        for (uint256 i = 0; i < _members.length; i++) {
            members.push(_members[i]);
            isMember[_members[i]] = true;
            emit MemberAdded(_members[i]);
        }
    }
    
    // Standard deposit function - Compound/Aave pattern
    function deposit() external payable {
        require(isMember[msg.sender], "Not a member");
        require(msg.value > 0, "Amount must be greater than 0");
        
        uint256 shares = totalSupply == 0 ? msg.value : msg.value.mul(totalSupply).div(address(this).balance.sub(msg.value));
        
        balances[msg.sender] = balances[msg.sender].add(shares);
        totalSupply = totalSupply.add(shares);
        
        emit Deposit(msg.sender, msg.value, shares);
    }
    
    // Standard view functions
    function getUserBalance(address user) external view returns (uint256) {
        if (totalSupply == 0) return 0;
        return balances[user].mul(address(this).balance).div(totalSupply);
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
}

// SafeMath library - Industry standard
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

// Industry Standard Factory - Uniswap/Compound pattern
contract IndustryStandardFactory {
    address public immutable implementation;
    address[] public allCirclesList;
    mapping(address => address[]) public getUserCircles;
    mapping(string => bool) public nameExists;
    
    event CircleCreated(address indexed circle, string name, address indexed creator);
    
    constructor() {
        implementation = address(new IndustryStandardCircle());
    }
    
    function createCircle(string memory name, address[] memory initialMembers) external returns (address circle) {
        require(bytes(name).length > 0, "Name required");
        require(!nameExists[name], "Name exists");
        require(initialMembers.length > 0, "Need members");
        
        // Create minimal proxy - Industry standard EIP-1167
        bytes memory bytecode = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d3d363d73",
            implementation,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        
        bytes32 salt = keccak256(abi.encodePacked(name, msg.sender, block.number));
        
        assembly {
            circle := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(circle) { revert(0, 0) }
        }
        
        // Initialize with standard pattern
        IndustryStandardCircle(circle).initialize(name, initialMembers, address(this));
        
        // Update state
        allCirclesList.push(circle);
        nameExists[name] = true;
        
        for (uint256 i = 0; i < initialMembers.length; i++) {
            getUserCircles[initialMembers[i]].push(circle);
        }
        
        emit CircleCreated(circle, name, msg.sender);
    }
    
    function getCircleCount() external view returns (uint256) {
        return allCirclesList.length;
    }
    
    function allCircles(uint256 index) external view returns (address) {
        return allCirclesList[index];
    }
}

contract DeployIndustryStandardFactory is Script {
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Deploying Industry Standard Factory ===");
        console.log("Using Compound/Aave/Uniswap patterns...");
        
        IndustryStandardFactory factory = new IndustryStandardFactory();
        
        console.log("Industry standard factory deployed:", address(factory));
        console.log("Implementation:", factory.implementation());
        console.log("Ready for production use!");
        console.log("Update frontend FACTORY to:", address(factory));
        
        vm.stopBroadcast();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CircleRegistry
 * @notice Industry-standard registry pattern for tracking deployed circles
 * @dev When factory deployment isn't possible due to size, use a registry
 */
contract CircleRegistry {
    address[] public allCircles;
    mapping(address => address[]) public userCircles;
    mapping(address => bool) public isRegisteredCircle;
    mapping(string => address) public circleByName;
    
    event CircleRegistered(address indexed circle, string name, address indexed creator);
    
    /**
     * @notice Register a new circle that was deployed separately
     * @param circle Address of the deployed HorizonCircle
     * @param name Name of the circle
     * @param members Initial members of the circle
     */
    function registerCircle(
        address circle,
        string memory name,
        address[] memory members
    ) external {
        require(circle != address(0), "Invalid circle address");
        require(!isRegisteredCircle[circle], "Circle already registered");
        require(circleByName[name] == address(0), "Name already taken");
        require(bytes(name).length > 0 && bytes(name).length <= 50, "Invalid name");
        
        // Register the circle
        allCircles.push(circle);
        isRegisteredCircle[circle] = true;
        circleByName[name] = circle;
        
        // Track members
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] != address(0)) {
                userCircles[members[i]].push(circle);
            }
        }
        
        emit CircleRegistered(circle, name, msg.sender);
    }
    
    /**
     * @notice Called by circles to notify member additions
     * @param member The new member's address
     */
    function notifyMemberAdded(address member) external {
        require(isRegisteredCircle[msg.sender], "Only registered circles");
        
        // Check if already tracked
        address[] storage circles = userCircles[member];
        for (uint256 i = 0; i < circles.length; i++) {
            if (circles[i] == msg.sender) return;
        }
        
        circles.push(msg.sender);
    }
    
    /**
     * @notice Get all circles for a user
     * @param user The user's address
     * @return Array of circle addresses
     */
    function getUserCircles(address user) external view returns (address[] memory) {
        return userCircles[user];
    }
    
    /**
     * @notice Get total circle count
     * @return Number of registered circles
     */
    function getCircleCount() external view returns (uint256) {
        return allCircles.length;
    }
    
    /**
     * @notice Check if a circle is registered
     * @param circle The circle address to check
     * @return True if registered
     */
    function isCircle(address circle) external view returns (bool) {
        return isRegisteredCircle[circle];
    }
}
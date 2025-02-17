// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPIRC20.sol";

contract DailyCheckIn {
    IPIRC20 public token; // Token used for rewards
    address public owner; // Contract owner
    uint256 private _reward; // Amount of reward given per check-in
    address private sender; // Address from which rewards are transferred
    uint256 public checkInPeriod; // Period between check-ins in seconds (default: 1 day)

    struct Reward {
        uint256 point;
        uint256 lastCheckIn;
        bool isActive;
    }

    mapping(address => bool) public blackList;
    mapping(address => Reward) public userRewards;

    event UserCheckIn(address indexed user, uint256 points, uint256 timestamp);
    event AmountRewardChanged(uint256 oldAmountReward, uint256 _reward, uint256 updateAt);
    event UpdateNewSender(address oldSender, address newSender, uint256 updateAt);
    event BlacklistUpdated(address indexed user, bool isBlacklisted);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CheckInPeriodChanged(uint256 oldPeriod, uint256 newPeriod);
    event UserCheckInReset(address indexed user, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(address _tokenAddress, uint256 amountReward) {
        owner = msg.sender;
        token = IPIRC20(_tokenAddress);
        _reward = amountReward;
        checkInPeriod = 86400; // Default to 1 day (86400 seconds)
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Set the time period required between check-ins
     * @param newPeriod The new period in seconds
     */
    function setCheckInTime(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0, "Period must be greater than zero");
        uint256 oldPeriod = checkInPeriod;
        checkInPeriod = newPeriod;
        emit CheckInPeriodChanged(oldPeriod, newPeriod);
    }

    /**
     * @dev Reset a user's check-in status, allowing them to check in again
     * @param user The address of the user to reset
     */
    function resetUserCheckIn(address user) external onlyOwner {
        require(userRewards[user].isActive, "User is not registered");
        userRewards[user].lastCheckIn = 0;
        emit UserCheckInReset(user, block.timestamp);
    }

    function registerUserCheckin(address account) external onlyOwner returns (bool) {
        require(userRewards[account].isActive == false, "User already registered");
        userRewards[account].isActive = true;
        return true;
    }

    function checkIn() public {
        Reward storage user = userRewards[msg.sender];
        require(!blackList[msg.sender], "Blacklisted");
        require(user.isActive, "You are not registered yet");
        require(canCheckIn(msg.sender), "Check-in period has not elapsed yet");

        user.point += _reward;
        user.lastCheckIn = block.timestamp;
        _transferReward(msg.sender);

        emit UserCheckIn(msg.sender, user.point, block.timestamp);
    }

    function setBlacklist(address user, bool status) external onlyOwner {
        blackList[user] = status;
        emit BlacklistUpdated(user, status);
    }

    function canCheckIn(address account) public view returns (bool) {
        Reward memory user = userRewards[account];
        
        // If never checked in before or if enough time has passed since last check-in
        return user.lastCheckIn == 0 || (block.timestamp - user.lastCheckIn) >= checkInPeriod;
    }

    function timeUntilNextCheckIn(address account) public view returns (uint256) {
        Reward memory user = userRewards[account];
        
        // If never checked in or if check-in period has elapsed
        if (user.lastCheckIn == 0 || (block.timestamp - user.lastCheckIn) >= checkInPeriod) {
            return 0;
        }
        
        // Return time remaining until next check-in is available
        return checkInPeriod - (block.timestamp - user.lastCheckIn);
    }

    function setPoint(
        address account,
        uint256 point
    ) public onlyOwner returns (bool) {
        Reward storage user = userRewards[account];
        user.point = point;
        return true;
    }

    function changePointReward(
        uint256 newReward
    ) public onlyOwner returns (bool) {
        uint256 oldAmountReward = _reward;
        _reward = newReward * 10 ** uint256(18);

        emit AmountRewardChanged(oldAmountReward, _reward, block.timestamp);
        return true;
    }

    function getPointByAddress(address user) public view returns (uint256) {
        return userRewards[user].point;
    }

    function setSender(address _sender) external onlyOwner returns (bool) {
        require(_sender != address(0), "Sender cannot set to zero address");
        address oldSender = sender;
        sender = _sender;
        emit UpdateNewSender(oldSender, sender, block.timestamp);
        return true;
    }

    function _transferReward(address _recipient) internal returns (bool) {
        require(sender != address(0), "Sender is not set");
        token.transferFrom(sender, _recipient, _reward);
        return true;
    }

    function transferTo(
        address _recipient,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        require(sender != address(0), "Sender not set");
        token.transferFrom(sender, _recipient, _amount);
        return true;
    }

    function totalSupply() external view returns (uint256) {
        require(sender != address(0), "Sender not set");
        return token.allowance(sender, address(this));
    }
}
    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IMyNFT is IERC721 {
    function safeMint(address to, uint256 tokenId, string memory uri) external;
}

contract NFTAirdrop is Ownable, ReentrancyGuard, Pausable {
    uint256 public constant CLAIM_PERIOD = 30 days;
    uint256 public lockPeriod = 730 days; 
    uint256 public totalDistributedNFTs; 
    uint256 public totalNativeCoinReceived;
    uint256 public totalNativeCoin;
    uint256 public globalClaimableAmount; 
   
    struct NFTInfo {
        uint256 tokenId;
        string nftURI;
        uint256 amountReward;
        bool claimable;      // Admin can set this to true to allow claiming
        uint256 mintTime;
        uint256 unlockTime;
        uint256 lastupdate;
        bool claimed;
    }
     struct UserClaimInfo {
        uint256 firstClaimTime;      // Thời gian bắt đầu claim đầu tiên
        uint256 lastClaimTime;       // Thời gian claim gần nhất
        uint256 totalClaimedAmount;  // Tổng số coin đã claim
        uint256 claimCount;          // Số lần đã claim
        bool canClaimAnytime;
    }

    mapping(address => NFTInfo) public userNFTs;
    mapping(address => UserClaimInfo) public userClaimHistory;
    mapping(address => bool) public blacklist; 
    mapping(address => uint256) public lastClaimTime; 
    IMyNFT public immutable nftContract;

    event NFTRegistered(address indexed user, uint256 tokenId, string nftURI, uint256 mintTime);
    event NFTClaimed(address indexed user, uint256 tokenId, uint256 claimTime);
    event LockPeriodUpdated(uint256 newLockPeriod);
    event BlacklistUpdated(address indexed user, bool isBlacklisted);
    event ContractPaused(bool paused);
    event NativeCoinDeposited(address indexed sender, uint256 amount);
    event NativeCoinWithdrawn(address indexed receiver, uint256 amount);
     event Claimed(
        address indexed user, 
        uint256 amount, 
        uint256 claimTime, 
        uint256 totalClaimed, 
        uint256 claimCount
    );
    event GlobalClaimableUpdated(uint256 amount);
    event NFTClaimableStatusUpdated(address indexed user, bool claimable);
    event UserClaimPermissionUpdated(address indexed user, bool canClaimAnytime); // Thêm event mới

    constructor(address _nftContract) Ownable() {
        require(_nftContract != address(0), "Invalid NFT contract");
        nftContract = IMyNFT(_nftContract);
    }

    receive() external payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        totalNativeCoinReceived += msg.value;
        emit NativeCoinDeposited(msg.sender, msg.value);
    }

    function setLockPeriod(uint256 _newLockPeriod) external onlyOwner {
        require(_newLockPeriod > 0, "Invalid lock period");
        lockPeriod = _newLockPeriod;
        emit LockPeriodUpdated(_newLockPeriod);
    }

      // Thêm function để admin set quyền claim bất kỳ lúc nào cho user
    function setUserClaimPermission(address user, bool canClaimAnytime) external onlyOwner {
        userClaimHistory[user].canClaimAnytime = canClaimAnytime;
        emit UserClaimPermissionUpdated(user, canClaimAnytime);
    }

    // Batch set claim permission cho nhiều users
    function batchSetUserClaimPermission(address[] calldata users, bool canClaimAnytime) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            userClaimHistory[users[i]].canClaimAnytime = canClaimAnytime;
            emit UserClaimPermissionUpdated(users[i], canClaimAnytime);
        }
    }
    function setClaimableAmount(uint amountUssdt) external onlyOwner {
        globalClaimableAmount = (1e18 * 1e18 / amountUssdt);
        emit GlobalClaimableUpdated(1e18 * 1e18 / amountUssdt);
    }

    // New function to set NFT claimable status
    function setNFTClaimable(address user, bool _claimable) external onlyOwner {
        require(userNFTs[user].mintTime != 0, "User not registered");
        require(!userNFTs[user].claimed, "NFT already claimed");
        
        userNFTs[user].claimable = _claimable;
        userNFTs[user].lastupdate = block.timestamp;
        
        emit NFTClaimableStatusUpdated(user, _claimable);
    }

    // Batch set claimable status for multiple users
    function batchSetNFTClaimable(address[] calldata users, bool _claimable) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            if (userNFTs[users[i]].mintTime != 0 && !userNFTs[users[i]].claimed) {
                userNFTs[users[i]].claimable = _claimable;
                userNFTs[users[i]].lastupdate = block.timestamp;
                emit NFTClaimableStatusUpdated(users[i], _claimable);
            }
        }
    }

    function registerAndMintNFT(address user, uint256 tokenId, string memory nftURI) external onlyOwner whenNotPaused {
        require(user != address(0), "Invalid address");
        require(userNFTs[user].mintTime == 0, "Already registered");

        userNFTs[user] = NFTInfo(
            tokenId,
            nftURI,
            0,
            false,
            block.timestamp,
            block.timestamp + lockPeriod,
            block.timestamp,
            false
        );

        totalDistributedNFTs += 1;
        nftContract.safeMint(address(this), tokenId, nftURI);

        emit NFTRegistered(user, tokenId, nftURI, block.timestamp);
    }

    function claimNativeCoin() external nonReentrant {
        UserClaimInfo storage userInfo = userClaimHistory[msg.sender];
        
        // Check if user can claim anytime, if not then check normal time restriction
        if (!userInfo.canClaimAnytime) {
            require(block.timestamp >= lastClaimTime[msg.sender] + CLAIM_PERIOD, "Claim not available yet");
        }
        
        require(globalClaimableAmount > 0, "No claimable amount");
        require(address(this).balance >= globalClaimableAmount, "Insufficient funds");

        // If this is the user's first claim
        if (userInfo.firstClaimTime == 0) {
            userInfo.firstClaimTime = block.timestamp;
        }

        userInfo.lastClaimTime = block.timestamp;
        userInfo.totalClaimedAmount += globalClaimableAmount;
        userInfo.claimCount += 1;

        lastClaimTime[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(globalClaimableAmount);

        emit Claimed(
            msg.sender, 
            globalClaimableAmount, 
            block.timestamp, 
            userInfo.totalClaimedAmount, 
            userInfo.claimCount
        );
    }

    function claimNFT() external nonReentrant whenNotPaused {
        require(!blacklist[msg.sender], "Blacklisted");

        NFTInfo storage nftInfo = userNFTs[msg.sender];

        require(nftInfo.mintTime != 0, "Not registered");
        require(!nftInfo.claimed, "Already claimed");
        require(
            nftInfo.claimable || block.timestamp >= nftInfo.mintTime + lockPeriod,
            "Not claimable and still locked"
        );

        require(nftContract.ownerOf(nftInfo.tokenId) == address(this), "NFT not locked in contract");

        nftContract.safeTransferFrom(address(this), msg.sender, nftInfo.tokenId);
        nftInfo.claimed = true;
        nftInfo.lastupdate = block.timestamp;

        emit NFTClaimed(msg.sender, nftInfo.tokenId, block.timestamp);
    }

    // Rest of the contract remains the same...
    function setBlacklist(address user, bool status) external onlyOwner {
        blacklist[user] = status;
        emit BlacklistUpdated(user, status);
    }

    function pause() external onlyOwner {
        _pause();
        emit ContractPaused(true);
    }

    function unpause() external onlyOwner {
        _unpause();
        emit ContractPaused(false);
    }

    function depositNativeCoin() external payable onlyOwner {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        totalNativeCoinReceived += msg.value;
        emit NativeCoinDeposited(msg.sender, msg.value);
    }

    function withdrawNativeCoin(address payable recipient, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance");
        totalNativeCoin += amount;
        recipient.transfer(amount);
        emit NativeCoinWithdrawn(recipient, amount);
    }
  function getUserClaimHistory(address user) 
        external 
        view 
        returns (
            uint256 firstClaim,
            uint256 lastClaim,
            uint256 totalClaimedAmount,
            uint256 claimCount,
            bool canClaimAnytime
        ) 
    {
        UserClaimInfo memory info = userClaimHistory[user];
        return (
            info.firstClaimTime,
            info.lastClaimTime,
            info.totalClaimedAmount,
            info.claimCount,
            info.canClaimAnytime
        );
    }
    function getUnlockTime(address user) public view returns (uint256) {
        return userNFTs[user].mintTime + lockPeriod;
    }

    function getNextClaimTime(address user) public view returns (uint256) {
        return lastClaimTime[user] + CLAIM_PERIOD;
    }

    function getNFTInfo(address user) 
        public 
        view 
        returns (
            uint256 tokenId,
            string memory nftURI,
            uint256 amountReward,
            bool claimable,
            uint256 mintTime,
            uint256 unlockTime,
            uint256 lastupdate,
            bool claimed
        ) 
    {
        NFTInfo memory info = userNFTs[user];
        return (
            info.tokenId,
            info.nftURI,
            info.amountReward,
            info.claimable,
            info.mintTime,
            info.unlockTime,
            info.lastupdate,
            info.claimed
        );
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
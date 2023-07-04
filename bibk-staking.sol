// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import the ERC721 and ERC20 interfaces
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts@4.8.2/access/Ownable.sol";
import "@openzeppelin/contracts@4.8.2/security/ReentrancyGuard.sol";


interface IERC20BIBK is IERC20 {
    function transferBIBK(address user, uint256 amount) external;
}
contract NFTStakingContract is Ownable, ReentrancyGuard {
    address public nftContractAddress; // Address of the NFT contract
    address public bibkTokenAddress; // Address of the BIBK token contract
    
    // Struct to store staking details
    struct StakingInfo {
        uint256 stakedTimestamp;
        bool isStaked;
    }

    struct BibkStakingInfo {
        uint256 stakedTimestamp;
        bool isStaked;
        uint256 amount;
    }
    
    
    // Mapping to store staking information for each user
    mapping(address => mapping(uint256 => StakingInfo)) public nftStakingInfo;

    mapping(address => mapping(uint256 => BibkStakingInfo)) public bibkStakingInfo;

    
    // Event emitted when an NFT is staked
    event NFTStaked(address indexed user, uint256 tokenId, uint256 stakedTimestamp);

    event BIBKStaked(address indexed user, uint256 stakedTimestamp);
    
    // Event emitted when an NFT is unstaked and BIBK tokens are transferred
    event NFTUnstaked(address indexed user, uint256 tokenId, uint256 stakedTimestamp, uint256 rewardAmount);

    event BIBKUnstaked(address indexed user, uint256 amount, uint256 stakedTimestamp, uint256 rewardAmount);
    
    constructor(address _nftContractAddress, address _bibkTokenAddress) {
        nftContractAddress = _nftContractAddress;
        bibkTokenAddress = _bibkTokenAddress; 
        
    }
    // Function to stake an NFT
    function stakeNFT(uint256 tokenId) external nonReentrant {
        require(!nftStakingInfo[msg.sender][tokenId].isStaked, "NFT already staked");

        // Update staking information
        nftStakingInfo[msg.sender][tokenId] = StakingInfo(block.timestamp, true);
        // Transfer the NFT to this contract
        IERC721(nftContractAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        emit NFTStaked(msg.sender, tokenId, block.timestamp);
    }
    
    // Function to unstake the NFT and receive BIBK tokens as rewards (if applicable)
    function unstakeNFT(uint256 tokenId, uint256 reward) external onlyOwner nonReentrant {
        require(nftStakingInfo[msg.sender][tokenId].isStaked, "No NFT staked");
        uint256 rewardAmount = reward * 10 ** 18;
        
        // Transfer the NFT back to the user
        IERC721(nftContractAddress).safeTransferFrom(address(this), msg.sender, tokenId);
    
        IERC20BIBK(bibkTokenAddress).transferBIBK(msg.sender, rewardAmount);
        // Reset staking information
        delete nftStakingInfo[msg.sender][tokenId];
        emit NFTUnstaked(msg.sender, tokenId, nftStakingInfo[msg.sender][tokenId].stakedTimestamp, rewardAmount);
    }

    function stakeBIBK(uint256 amount) external nonReentrant returns(uint256)  {
        uint256 _amount = amount * 10 ** 18;
        uint256 _currentTimestamp = block.timestamp;

        // Update staking information
        bibkStakingInfo[msg.sender][_currentTimestamp] = BibkStakingInfo(_currentTimestamp, true, _amount);

        // Transfer the NFT to this contract
        IERC20BIBK(bibkTokenAddress).transferFrom(msg.sender, address(this), _amount);

        emit BIBKStaked(msg.sender, _currentTimestamp);
        return _currentTimestamp;
    }

    function unStakeBIBK(uint256 _timestamp, uint256 _reward) external onlyOwner nonReentrant{
        require(bibkStakingInfo[msg.sender][_timestamp].isStaked, "No BIBK staked");
        uint256 _amount = bibkStakingInfo[msg.sender][_timestamp].amount;
        uint256 rewardAmount = _reward * 10 ** 18; // Adjust as needed
        // Transfer the NFT back to the user
        IERC20BIBK(bibkTokenAddress).transferBIBK(msg.sender, _amount + rewardAmount);
        
        // Calculate the reward amount (assuming 1 BIBK token per unstaked NFT)
        // Transfer the BIBK tokens as rewards
        
        // Reset staking information
        delete bibkStakingInfo[msg.sender][_timestamp];
        
        emit BIBKUnstaked(msg.sender, _amount, nftStakingInfo[msg.sender][_timestamp].stakedTimestamp, rewardAmount);
    }
}

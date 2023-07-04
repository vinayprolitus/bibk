// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@4.8.2/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.8.2/access/Ownable.sol";

contract BIBK is ERC20, Ownable {
    uint256 public buyPrice = 1 ether;
    uint256 public sellPrice = 1 ether;

    uint256 public bibkProtocolMainnetLaunchTimestamp;

    bool private unlockMainnetLaunchStatus = false;
    bool public tokensUnlockedYearAfterLaunch = false;
    address public stakingContract = address(0x0);
    event Unlocked(string indexed messageUnlocked, uint256 amountUnlocked);

    modifier onlyStakingContract {
        require(stakingContract != address(0x0), "Invalid address");
        require(msg.sender == stakingContract, "Only staking contract can transfer rewards");
        _;
    }
    constructor() ERC20("BibkCoin", "BIBK") {
        bibkProtocolMainnetLaunchTimestamp = block.timestamp + 30 days; 
        _mint(address(this), 300000 * 10 ** 18);
    }

    function setStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = _stakingContract;
    }

    function transferBIBK(address user, uint256 amount) external onlyStakingContract {
        require(balanceOf(address(this)) >= amount, "Not enough bibk tokens, unlock more!");
        _transfer(address(this), user, amount);
    }

    //Unlocks 29,220,000 token minted on bibk protocol mainnet launch
    function unlockTokens() external onlyOwner {
        require(unlockMainnetLaunchStatus == false, "already unlocked the tokens");
        require(totalSupply() < (30000000 * 10 ** 18), "max token minted");
        require(bibkProtocolMainnetLaunchTimestamp <= block.timestamp, "bibk protocol mainnet launch date isn't arrived yet");
        unlockMainnetLaunchStatus = true;
        uint128 _mainnetLaunchTokenUnlock = 29220000 * 10 ** 18;
        emit Unlocked("Unlocked bibk protocol mainnet launch tokens", _mainnetLaunchTokenUnlock);
        _mint(address(this), _mainnetLaunchTokenUnlock);
    }

    //Unlocks 480,000 year after launch
    function unlockTokensYearAfterLaunch() external onlyOwner {
        require((bibkProtocolMainnetLaunchTimestamp + 365 days) <= block.timestamp, "cannot unlock tokens before one year from launch");
        require(tokensUnlockedYearAfterLaunch == false, "tokens have already been unlocked");
        require(unlockMainnetLaunchStatus == false, "bibk protocol mainnet isn't launched yet");
        tokensUnlockedYearAfterLaunch = true;
        uint128 _tokensUnlockAfterYear = 480000 * 10 ** 18;
        emit Unlocked("Unlocked after a year", _tokensUnlockAfterYear);
        _mint(address(this), _tokensUnlockAfterYear);
    }

    function mainnetLaunchTimestamp(uint256 _mainnetLaunchTimestamp) external onlyOwner {
        require(unlockMainnetLaunchStatus == false, "cannot change mainnet launch date after mainnet launch");
        bibkProtocolMainnetLaunchTimestamp = _mainnetLaunchTimestamp;
    }

    function buy() external payable {
        uint256 amount = msg.value / buyPrice;
        require(amount <= balanceOf((address(this))), "not enough tokens available for sale");
        _transfer(address(this), msg.sender, amount * 10 ** 18);
    }

    function sell(uint256 amount) external {
        require(amount <= balanceOf(msg.sender), "not enough tokens available to sell");
        uint256 ethAmount = amount * sellPrice;
        _transfer(msg.sender, address(this), amount  * 10 ** 18);
        payable(msg.sender).transfer(ethAmount);
    }

    // function ethWithdraw(uint256 amount) external onlyOwner {
    //     require(amount <= address(this).balance, "insufficient balance");
    //     payable(owner()).transfer(amount);
    // }

    function ethBalance() public view onlyOwner returns(uint256){
        return address(this).balance;
    }

    function setBuyPrice(uint256 price) external onlyOwner {
        buyPrice = price;
    }

    function setSellPrice(uint256 price) external onlyOwner {
        sellPrice = price;
    }
}
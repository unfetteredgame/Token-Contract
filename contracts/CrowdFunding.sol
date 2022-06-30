// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IManagers.sol";
import "hardhat/console.sol";

contract CrowdFunding is Pausable, Ownable {
    IManagers managers;
    IERC20 public soulsToken;

    struct TokenReward {
        uint256 amount;
        uint256 releaseDate;
        bool isClaimed;
        bool isActive;
    }

    struct Investor {
        uint256 totalAmount;
        uint256 vestingCount;
        uint256 currentVestingIndex;
    }

    mapping(address => TokenReward[]) public tokenRewards;
    mapping(address => bool) public blacklist;
    mapping(address => Investor) public investors;

    address[] public investorList;

    /**
	@dev must be assigned in constructor on of these: 
	"Strategic Sale", "Seed Sale", "Private Sale", "Public Sale" or "Airdrop"
	*/
    string public crowdFundingType;

    uint256 public totalRewardAmount;
    uint256 public totalClaimedAmount;

    event BalanceWithdraw(address sender, uint256 amount);

    constructor(
        string memory _crowdFundingType,
        address _soulsTokenAddress,
        address _managersAddress
    ) {
        require(
            keccak256(abi.encodePacked(_crowdFundingType)) == keccak256(abi.encodePacked("Strategic Sale")) ||
                keccak256(abi.encodePacked(_crowdFundingType)) == keccak256(abi.encodePacked("Seed Sale")) ||
                keccak256(abi.encodePacked(_crowdFundingType)) == keccak256(abi.encodePacked("Private Sale")) ||
                keccak256(abi.encodePacked(_crowdFundingType)) == keccak256(abi.encodePacked("Public Sale")) ||
                keccak256(abi.encodePacked(_crowdFundingType)) == keccak256(abi.encodePacked("Airdrop")),
            "Invalid crowdfunding type"
        );
        require(_soulsTokenAddress != address(0) && _managersAddress != address(0), "Zero address in parameters");
        crowdFundingType = _crowdFundingType;
        soulsToken = IERC20(_soulsTokenAddress);
        managers = IManagers(_managersAddress);
    }

    modifier ifNotBlacklisted() {
        require(blacklist[msg.sender] != true, "Address is blacklisted");
        _;
    }

    modifier onlyManager() {
        require(managers.isManager(msg.sender), "Not authorized");
        _;
    }

    /// @dev number of vestings for each owner must be one below of total vesting because of advance paymant and
    /// amount per vesting for each owner must be calculated with subtraction of advance amount from total amount.
    function addRewards(
        address[] memory _rewardOwners,
        uint256[] memory _advancePayments,
        uint256[] memory _amountsPerVesting,
        uint8[] memory _numberOfVestings,
        uint256 _releaseDate
    ) public onlyOwner whenNotPaused {
        uint256 oneMonthToSeconds = 30 days;
        require(
            _rewardOwners.length == _advancePayments.length &&
                _rewardOwners.length == _amountsPerVesting.length &&
                _rewardOwners.length == _numberOfVestings.length,
            "Invalid data"
        );
        require(_releaseDate > block.timestamp, "Release date is in the past");
        uint256 _totalAmount = 0;
        for (uint256 r = 0; r < _rewardOwners.length; r++) {
            address _rewardOwner = _rewardOwners[r];
            require(investors[_rewardOwner].totalAmount == 0, "Investor already added");

            uint256 _advancePayment = _advancePayments[r];
            uint8 _numberOfVesting = _numberOfVestings[r];
            uint256 _investorTotalAmount = _advancePayment;

            tokenRewards[_rewardOwner].push(
                TokenReward({amount: _advancePayment, releaseDate: _releaseDate, isClaimed: false, isActive: true})
            );

            for (uint8 i = 1; i <= _numberOfVesting; i++) {
                tokenRewards[_rewardOwner].push(
                    TokenReward({
                        amount: _amountsPerVesting[r],
                        releaseDate: _releaseDate + (oneMonthToSeconds * i),
                        isClaimed: false,
                        isActive: true
                    })
                );
                _investorTotalAmount += tokenRewards[_rewardOwner][i].amount;
            }
            _totalAmount += _investorTotalAmount;

            investors[_rewardOwner] = Investor({
                totalAmount: _investorTotalAmount,
                vestingCount: _numberOfVesting + 1, //+1 for advancepayment
                currentVestingIndex: 0
            });
            investorList.push(_rewardOwner);
        }
        totalRewardAmount += _totalAmount;
        require(soulsToken.balanceOf(address(this)) >= totalRewardAmount, "Not enough free token balance in contract");
    }

    function isCrowdFunding() public pure returns (bool) {
        return true;
    }

    function claimRewards(uint8 _vestingIndex) public whenNotPaused ifNotBlacklisted {
        require(
            tokenRewards[msg.sender][_vestingIndex].releaseDate > 0 &&
                tokenRewards[msg.sender][_vestingIndex].releaseDate < block.timestamp,
            "Early request"
        );
        require(tokenRewards[msg.sender][_vestingIndex].isClaimed == false, "Reward is already claimed");
        require(tokenRewards[msg.sender][_vestingIndex].isActive == true, "Reward is deactivated");
        soulsToken.transfer(msg.sender, tokenRewards[msg.sender][_vestingIndex].amount);
        tokenRewards[msg.sender][_vestingIndex].isClaimed = true;
        investors[msg.sender].currentVestingIndex++;
        totalClaimedAmount += tokenRewards[msg.sender][_vestingIndex].amount;
    }

    //Managers Function
    function withdrawTokens(address _to, uint256 _amount) external onlyManager {
        require(_to != address(0), "Zero address");
        require(_amount > 0, "Zero amount");

        string memory _title = "Withdraw Tokens";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_to, _amount));
        managers.approveTopic(_title, _valueInBytes);
        if (managers.isApproved(_title, _valueInBytes)) {
            soulsToken.transfer(_to, _amount);
            managers.deleteTopic(_title);
        }
        require(
            soulsToken.balanceOf(address(this)) - _amount >= totalRewardAmount,
            "Amount more then free token balance"
        );
    }

    //Managers Function
    function deactivateInvestorVesting(address _rewardOwner, uint8 _vestingIndex) external onlyManager {
        require(_rewardOwner != address(0), "Zero address");
        require(tokenRewards[_rewardOwner].length > 0, "Reward owner not found");
        require(_vestingIndex < investors[_rewardOwner].vestingCount, "Invalid vesting index");
        require(tokenRewards[_rewardOwner][_vestingIndex].isClaimed == false, "Already claimed");
        require(tokenRewards[_rewardOwner][_vestingIndex].isActive == true, "Already deactive");

        string memory _title = "Deactivate Investor Rewards";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_rewardOwner, _vestingIndex));

        managers.approveTopic(_title, _valueInBytes);
        if (managers.isApproved(_title, _valueInBytes)) {
            tokenRewards[_rewardOwner][_vestingIndex].isActive = false;
            managers.deleteTopic(_title);
        }
    }

    //Managers Function
    function activateInvestorVesting(address _rewardOwner, uint8 _vestingIndex) external onlyManager {
        require(_rewardOwner != address(0), "Zero address");
        require(tokenRewards[_rewardOwner].length > 0, "Reward owner not found");
        require(_vestingIndex < investors[_rewardOwner].vestingCount, "Invalid vesting index");
        require(tokenRewards[_rewardOwner][_vestingIndex].isActive == false, "Already active");

        string memory _title = "Activate Investor Rewards";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_rewardOwner, _vestingIndex));

        managers.approveTopic(_title, _valueInBytes);
        if (managers.isApproved(_title, _valueInBytes)) {
            tokenRewards[_rewardOwner][_vestingIndex].isActive = true;
            managers.deleteTopic(_title);
        }
    }

    //Managers Function
    function addToBlacklist(address _rewardOwner) external onlyManager {
        require(_rewardOwner != address(0), "Zero address");
        require(tokenRewards[_rewardOwner].length > 0, "Reward owner not found");
        require(isInBlacklist(_rewardOwner) == false, "Already blacklisted");

        string memory _title = "Add To Blacklist";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_rewardOwner));

        managers.approveTopic(_title, _valueInBytes);
        if (managers.isApproved(_title, _valueInBytes)) {
            blacklist[_rewardOwner] = true;
            managers.deleteTopic(_title);
        }
    }

    //Managers Function
    function removeFromBlacklist(address _rewardOwner) external onlyManager {
        require(_rewardOwner != address(0), "Zero address");
        require(isInBlacklist(_rewardOwner) == true, "Not blacklisted");

        string memory _title = "Remove From Blacklist";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_rewardOwner));
        managers.approveTopic(_title, _valueInBytes);
        if (managers.isApproved(_title, _valueInBytes)) {
            blacklist[_rewardOwner] = false;
            managers.deleteTopic(_title);
        }
    }

    function fetchRewardsInfo(uint8 _vestingIndex) public view returns (TokenReward memory) {
        return tokenRewards[msg.sender][_vestingIndex];
    }

    function fetchInvestorList() public view returns (address[] memory) {
        return investorList;
    }

    function isInBlacklist(address _address) public view returns (bool) {
        return blacklist[_address];
    }

    function getTotalBalance() public view returns (uint256) {
        return soulsToken.balanceOf(address(this));
    }
}

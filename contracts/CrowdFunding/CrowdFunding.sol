// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrowdFunding is Pausable, Ownable {
    IERC20 public tokenContract;

    struct TokenReward {
        uint256 amount;
        uint256 releaseDate;
        bool isClaimed;
        bool isActive;
    }

    struct ShareHolder {
        address holder;
        uint256 amount;
    }

    mapping(address => mapping(uint256 => TokenReward)) public tokenRewardsSeedSale;
    mapping(address => mapping(uint256 => TokenReward)) public tokenRewardsPrivateSale;
    mapping(address => mapping(uint256 => TokenReward)) public tokenRewardsStrategicRound;
    mapping(address => TokenReward) public tokenRewardsAirdrop;
    mapping(address => bool) public blacklist;

    ShareHolder[] public seedShareHolders;
    ShareHolder[] public privateShareHolders;
    ShareHolder[] public strategicRoundHolders;
    ShareHolder[] public airdropHolders;

    uint256 public totalAmountSeedSale;
    uint256 public claimedAmountSeedSale;
    uint256 public totalAmountPrivateSale;
    uint256 public claimedAmountPrivateSale;
    uint256 public totalAmountStrategicRound;
    uint256 public claimedAmountStrategicRound;
    uint256 public totalAmountAirdrop;
    uint256 public claimedAmountAirdrop;

    event AirdropRewardAdded(address rewardOwner, uint256 amount, uint256 releaseDate);
    event BalanceWithdraw(address sender, uint256 amount);

    constructor(address _tokenContractAddress) {
        tokenContract = IERC20(_tokenContractAddress);
    }

    modifier ifNotInBlacklist() {
        require(blacklist[msg.sender] != true, "Caller in Blacklist");
        _;
    }

    /// @dev number of vestings for each owner must be one below of total vesting because of advance paymant and
    /// amount for each owner must be calculated with subtraction of advance amount from total amount.
    function addRewardSeedSale(
        address[] memory _rewardOwners,
        uint256[] memory _advancePayments,
        uint256[] memory _amounts,
        uint8[] memory _numberOfVestings,
        uint256 _releaseDate
    ) public onlyOwner whenNotPaused {
        uint256 oneMonthToSeconds = 30 days;
        require(
            _rewardOwners.length == _advancePayments.length &&
                _rewardOwners.length == _amounts.length &&
                _rewardOwners.length == _numberOfVestings.length,
            "Invalid data"
        );
        require(_releaseDate > block.timestamp, "Release date is in the past");

        for (uint256 r = 0; r < _rewardOwners.length; r++) {
            address _rewardOwner = _rewardOwners[r];
            uint256 _advancePayment = _advancePayments[r];
            uint256 _amount = _amounts[r];
            uint8 _numberOfVesting = _numberOfVestings[r];

            tokenRewardsSeedSale[_rewardOwner][0].amount = _advancePayment;
            tokenRewardsSeedSale[_rewardOwner][0].releaseDate = _releaseDate;
            tokenRewardsSeedSale[_rewardOwner][0].isClaimed = false;
            tokenRewardsSeedSale[_rewardOwner][0].isActive = true;

            for (uint8 i = 1; i <= _numberOfVesting; i++) {
                tokenRewardsSeedSale[_rewardOwner][i].amount = _amount / _numberOfVesting;
                tokenRewardsSeedSale[_rewardOwner][i].releaseDate = _releaseDate + (oneMonthToSeconds * i);
                tokenRewardsSeedSale[_rewardOwner][i].isClaimed = false;
                tokenRewardsSeedSale[_rewardOwner][i].isActive = true;
            }
            ShareHolder memory seedShareHolderToInsert;
            seedShareHolderToInsert.holder = _rewardOwner;
            seedShareHolderToInsert.amount = _amount + _advancePayment;
            seedShareHolders.push(seedShareHolderToInsert);
            totalAmountSeedSale += (_advancePayment + (_amount * _numberOfVesting));
        }
    }

    /// @dev number of vestings for each owner must be one below of total vesting because of advance paymant and
    /// amount for each owner must be calculated with subtraction of advance amount from total amount.
    function addRewardPrivateSale(
        address[] memory _rewardOwners,
        uint256[] memory _advancePayments,
        uint256[] memory _amounts,
        uint8[] memory _numberOfVestings,
        uint256 _releaseDate
    ) public onlyOwner whenNotPaused {
        uint256 oneMonthToSeconds = 30 days;
        require(
            _rewardOwners.length == _advancePayments.length &&
                _rewardOwners.length == _amounts.length &&
                _rewardOwners.length == _numberOfVestings.length,
            "Invalid data"
        );
        require(_releaseDate > block.timestamp, "Release date is in the past");

        for (uint256 r = 0; r < _rewardOwners.length; r++) {
            address _rewardOwner = _rewardOwners[r];
            uint256 _advancePayment = _advancePayments[r];
            uint256 _amount = _amounts[r];
            uint8 _numberOfVesting = _numberOfVestings[r];

            tokenRewardsPrivateSale[_rewardOwner][0].amount = _advancePayment;
            tokenRewardsPrivateSale[_rewardOwner][0].releaseDate = _releaseDate;
            tokenRewardsPrivateSale[_rewardOwner][0].isClaimed = false;
            tokenRewardsPrivateSale[_rewardOwner][0].isActive = true;
            for (uint8 i = 1; i <= _numberOfVesting; i++) {
                tokenRewardsPrivateSale[_rewardOwner][i].amount = _amount / _numberOfVesting;
                tokenRewardsPrivateSale[_rewardOwner][i].releaseDate = _releaseDate + (oneMonthToSeconds * i);
                tokenRewardsPrivateSale[_rewardOwner][i].isClaimed = false;
                tokenRewardsPrivateSale[_rewardOwner][i].isActive = true;
            }
            ShareHolder memory privateShareHolderToInsert;
            privateShareHolderToInsert.holder = _rewardOwner;
            privateShareHolderToInsert.amount = _amount + _advancePayment;
            privateShareHolders.push(privateShareHolderToInsert);
            totalAmountPrivateSale += (_advancePayment + (_amount * _numberOfVesting));
        }
    }

    /// @dev number of vestings for each owner must be one below of total vesting because of advance paymant and
    /// amount for each owner must be calculated with subtraction of advance amount from total amount.
    function addRewardStrategicRound(
        address[] memory _rewardOwners,
        uint256[] memory _advancePayments,
        uint256[] memory _amounts,
        uint8[] memory _numberOfVestings,
        uint256 _releaseDate
    ) public onlyOwner whenNotPaused {
        uint256 oneMonthToSeconds = 30 days;
        require(
            _rewardOwners.length == _advancePayments.length &&
                _rewardOwners.length == _amounts.length &&
                _rewardOwners.length == _numberOfVestings.length,
            "Invalid data"
        );
        require(_releaseDate > block.timestamp, "Release date is in the past");

        for (uint256 r = 0; r < _rewardOwners.length; r++) {
            address _rewardOwner = _rewardOwners[r];
            uint256 _advancePayment = _advancePayments[r];
            uint256 _amount = _amounts[r];
            uint8 _numberOfVesting = _numberOfVestings[r];

            tokenRewardsStrategicRound[_rewardOwner][0].amount = _advancePayment;
            tokenRewardsStrategicRound[_rewardOwner][0].releaseDate = _releaseDate;
            tokenRewardsStrategicRound[_rewardOwner][0].isClaimed = false;
            tokenRewardsStrategicRound[_rewardOwner][0].isActive = true;
            for (uint8 i = 1; i <= _numberOfVesting; i++) {
                tokenRewardsStrategicRound[_rewardOwner][i].amount = _amount / _numberOfVesting;
                tokenRewardsStrategicRound[_rewardOwner][i].releaseDate = _releaseDate + (oneMonthToSeconds * i);
                tokenRewardsStrategicRound[_rewardOwner][i].isClaimed = false;
                tokenRewardsStrategicRound[_rewardOwner][i].isActive = true;
            }
            ShareHolder memory strategicRoundHolderToInsert;
            strategicRoundHolderToInsert.holder = _rewardOwner;
            strategicRoundHolderToInsert.amount = _amount + _advancePayment;
            strategicRoundHolders.push(strategicRoundHolderToInsert);
            totalAmountStrategicRound += (_advancePayment + (_amount * _numberOfVesting));
        }
    }

    function addRewardAirdrop(
        address[] memory _rewardOwners,
        uint256[] memory _amounts,
        uint256 _releaseDate
    ) public onlyOwner whenNotPaused {
        for (uint256 r = 0; r < _rewardOwners.length; r++) {
            address _rewardOwner = _rewardOwners[r];
            uint256 _amount = _amounts[r];

            tokenRewardsAirdrop[_rewardOwner].amount = _amount;
            tokenRewardsAirdrop[_rewardOwner].releaseDate = _releaseDate;
            tokenRewardsAirdrop[_rewardOwner].isClaimed = false;
            tokenRewardsAirdrop[_rewardOwner].isActive = true;
            ShareHolder memory airdropHolderToInsert;
            airdropHolderToInsert.holder = _rewardOwner;
            airdropHolderToInsert.amount = _amount;
            airdropHolders.push(airdropHolderToInsert);
            totalAmountAirdrop += _amount;
        }
    }

    function ClaimRewardSeedSale(uint8 _vestingIndex) public whenNotPaused ifNotInBlacklist {
        require(
            tokenRewardsSeedSale[msg.sender][_vestingIndex].releaseDate > 0 &&
                tokenRewardsSeedSale[msg.sender][_vestingIndex].releaseDate < block.timestamp,
            "Please wait for the Release Date"
        );
        require(tokenRewardsSeedSale[msg.sender][_vestingIndex].isClaimed == false, "Reward is already claimed");
        require(tokenRewardsSeedSale[msg.sender][_vestingIndex].isActive == true, "Reward is inactive");
        require(
            tokenContract.transfer(msg.sender, tokenRewardsSeedSale[msg.sender][_vestingIndex].amount),
            "Transfer for ClaimRewardSeedSale failed"
        );
        tokenRewardsSeedSale[msg.sender][_vestingIndex].isClaimed = true;
        claimedAmountSeedSale += (tokenRewardsSeedSale[msg.sender][_vestingIndex].amount);
    }

    function ClaimRewardPrivateSale(uint8 _vestingIndex) public whenNotPaused ifNotInBlacklist {
        require(
            tokenRewardsPrivateSale[msg.sender][_vestingIndex].releaseDate > 0 &&
                tokenRewardsSeedSale[msg.sender][_vestingIndex].releaseDate < block.timestamp,
            "Please wait for the Release Date"
        );
        require(tokenRewardsPrivateSale[msg.sender][_vestingIndex].isClaimed == false, "Reward is already claimed");
        require(tokenRewardsPrivateSale[msg.sender][_vestingIndex].isActive == true, "Reward is inactive");
        require(
            tokenContract.transfer(msg.sender, tokenRewardsPrivateSale[msg.sender][_vestingIndex].amount),
            "Transfer for ClaimRewardPrivateSale failed"
        );
        tokenRewardsPrivateSale[msg.sender][_vestingIndex].isClaimed = true;
        claimedAmountPrivateSale += (tokenRewardsPrivateSale[msg.sender][_vestingIndex].amount);
    }

    function ClaimRewardStrategicRound(uint8 _vestingIndex) public whenNotPaused ifNotInBlacklist {
        require(
            tokenRewardsStrategicRound[msg.sender][_vestingIndex].releaseDate > 0 &&
                tokenRewardsStrategicRound[msg.sender][_vestingIndex].releaseDate < block.timestamp,
            "Please wait for the Release Date"
        );
        require(tokenRewardsStrategicRound[msg.sender][_vestingIndex].isClaimed == false, "Reward is already claimed");
        require(tokenRewardsStrategicRound[msg.sender][_vestingIndex].isActive == true, "Reward is inactive");
        require(
            tokenContract.transfer(msg.sender, tokenRewardsStrategicRound[msg.sender][_vestingIndex].amount),
            "Transfer for ClaimRewardStrategicRound failed"
        );
        tokenRewardsStrategicRound[msg.sender][_vestingIndex].isClaimed = true;
        claimedAmountStrategicRound += (tokenRewardsStrategicRound[msg.sender][_vestingIndex].amount);
    }

    function ClaimRewardAirdrop() public whenNotPaused ifNotInBlacklist {
        require(
            tokenRewardsAirdrop[msg.sender].releaseDate > 0 &&
                tokenRewardsAirdrop[msg.sender].releaseDate < block.timestamp,
            "Please wait for the Release Date"
        );
        require(tokenRewardsAirdrop[msg.sender].isClaimed == false, "Reward is already claimed");
        require(tokenRewardsAirdrop[msg.sender].isActive == true, "Reward is inactive");
        require(
            tokenContract.transfer(msg.sender, tokenRewardsAirdrop[msg.sender].amount),
            "Transfer for ClaimRewardAirdrop failed"
        );
        tokenRewardsAirdrop[msg.sender].isClaimed = true;
        claimedAmountAirdrop += (tokenRewardsAirdrop[msg.sender].amount);
    }

    //Managers Function
    function deactivateRewardSeedSale(address _rewardOwner, uint8 _vestingIndex) public {
        tokenRewardsSeedSale[_rewardOwner][_vestingIndex].isActive = false;
    }

    //Managers Function
    function activateRewardSeedSale(address _rewardOwner, uint8 _vestingIndex) public {
        tokenRewardsSeedSale[_rewardOwner][_vestingIndex].isActive = true;
    }

    //Managers Function
    function deactivateRewardPrivateSale(address _rewardOwner, uint8 _vestingIndex) public {
        tokenRewardsPrivateSale[_rewardOwner][_vestingIndex].isActive = false;
    }

    //Managers Function
    function activateRewardPrivateSale(address _rewardOwner, uint8 _vestingIndex) public {
        tokenRewardsPrivateSale[_rewardOwner][_vestingIndex].isActive = true;
    }

    //Managers Function
    function deactivateRewardStrategicRound(address _rewardOwner, uint8 _vestingIndex) public {
        tokenRewardsStrategicRound[_rewardOwner][_vestingIndex].isActive = false;
    }

    //Managers Function
    function activateRewardStrategicRound(address _rewardOwner, uint8 _vestingIndex) public {
        tokenRewardsStrategicRound[_rewardOwner][_vestingIndex].isActive = true;
    }

    //Managers Function
    function deactivateRewardAirdrop(address _rewardOwner) public {
        tokenRewardsAirdrop[_rewardOwner].isActive = false;
    }

    //Managers Function
    function activateRewardAirdrop(address _rewardOwner) public {
        tokenRewardsAirdrop[_rewardOwner].isActive = true;
    }

    function fetchMyRewardsSeedSale(uint8 _vestingIndex) public view returns (TokenReward memory) {
        return tokenRewardsSeedSale[msg.sender][_vestingIndex];
    }

    function fetchMyRewardsPrivateSale(uint8 _vestingIndex) public view returns (TokenReward memory) {
        return tokenRewardsPrivateSale[msg.sender][_vestingIndex];
    }

    function fetchMyRewardsStrategicRound(uint8 _vestingIndex) public view returns (TokenReward memory) {
        return tokenRewardsStrategicRound[msg.sender][_vestingIndex];
    }

    function fetchMyRewardsAirdrop() public view returns (TokenReward memory) {
        return tokenRewardsAirdrop[msg.sender];
    }

    function fetchSeedShareHolders() public view returns (ShareHolder[] memory) {
        return seedShareHolders;
    }

    function fetchPrivateShareHolders() public view returns (ShareHolder[] memory) {
        return privateShareHolders;
    }

    function fetchStrategicRoundHolders() public view returns (ShareHolder[] memory) {
        return strategicRoundHolders;
    }

    function fetchAirdropHolders() public view returns (ShareHolder[] memory) {
        return airdropHolders;
    }

    //Managers Function
    function addToBlacklist(address _address) public {
        blacklist[_address] = true;
    }

    //Managers Function
    function removeFromBlacklist(address _address) public {
        blacklist[_address] = false;
    }

    function isInBlacklist(address _address) public view returns (bool) {
        return blacklist[_address];
    }

    function getTotalBalance() public view returns (uint256) {
        return tokenContract.balanceOf(address(this));
    }

    //Managers Function
    function withdrawBalance(address _receiver, uint256 _amount) public {
        require(tokenContract.transfer(_receiver, _amount), "Transfer for withdrawBalance failed");
        emit BalanceWithdraw(msg.sender, _amount);
    }

    //Managers Function
    function withdrawTotalBalance(address _receiver) public {
        require(tokenContract.transfer(_receiver, getTotalBalance()), "Transfer for withdrawTotalBalance failed");
        emit BalanceWithdraw(msg.sender, getTotalBalance());
    }

    //Managers Function
    function pause() public {
        _pause();
        emit Paused(msg.sender);
    }

    //Managers Function
    function unpause() public {
        _unpause();
        emit Unpaused(msg.sender);
    }
}

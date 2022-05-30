// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../../interfaces/IManagers.sol";

contract Staking is Pausable {
    IManagers managers;
    ERC20Burnable public tokenContract;

    uint256 constant monthToSecond = 30 days;
    uint256 constant yearToSecond = 365 days;
    uint256 public totalStakedAmount;
    uint256 public totalDistributedReward;

    uint16 public stakePercentagePer1Month;
    uint16 public stakePercentagePer3Month;
    uint16 public stakePercentagePer6Month;
    uint16 public stakePercentagePer12Month;
    uint16 public maxMonthToProfit;
    uint8 public emergencyExitPenaltyRate;

    address[] public stakers;

    struct StakeData {
        uint256 amount;
        uint256 maxProfitDate;
        uint256 stakeDate;
        uint256 releaseDate;
        uint16 percentage;
        uint16 monthToStake;
        bool withdrawn;
    }

    mapping(address => StakeData[]) public stakes;
    mapping(address => bool) public isStaker;

    event StakePercentageChange(
        uint16 _newPercentagePer1Month,
        uint16 _newPercentagePer3Month,
        uint16 _newPercentagePer6Month,
        uint16 _newPercentagePer12Month
    );
    event Stake(address indexed sender, uint256 amount, uint256 stakeDate, uint256 releaseDate);
    event Withdraw(address indexed sender, uint256 amount, uint256 stakeDate);
    event EmergencyWithdraw(address indexed sender, uint256 amount, uint256 stakeDate);

    constructor(
        address _tokenContractAddress,
        address _managersContractAddress,
        uint8 _emergencyExitPenaltyRate,
        uint16 _stakePercentagePer1Month,
        uint16 _stakePercentagePer3Month,
        uint16 _stakePercentagePer6Month,
        uint16 _stakePercentagePer12Month
    ) {
        tokenContract = ERC20Burnable(_tokenContractAddress);
        managers = IManagers(_managersContractAddress);
        emergencyExitPenaltyRate = _emergencyExitPenaltyRate;
        stakePercentagePer1Month = _stakePercentagePer1Month;
        stakePercentagePer3Month = _stakePercentagePer3Month;
        stakePercentagePer6Month = _stakePercentagePer6Month;
        stakePercentagePer12Month = _stakePercentagePer12Month;
        maxMonthToProfit = 12;
    }

    function getTotalBalance() public view returns (uint256) {
        return tokenContract.balanceOf(address(this));
    }

    //Managers Function
    function pause() public {
        require(managers.isManager(msg.sender), "Not authorized");
        string memory _title = "Pause Staking Contract";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(true));
        managers.approveTopic(_title, _valueInBytes);

        if (managers.isApproved(_title, _valueInBytes)) {
            _pause();
            emit Paused(msg.sender);
            managers.deleteTopic(_title);
        }
    }

    //Managers Function
    function unpause() public {
        require(managers.isManager(msg.sender), "Not authorized");
        string memory _title = "Unpause Staking Contract";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(true));
        managers.approveTopic(_title, _valueInBytes);

        if (managers.isApproved(_title, _valueInBytes)) {
            _unpause();
            emit Unpaused(msg.sender);
            managers.deleteTopic(_title);
        }
    }

    //Managers Function
    function changeStakeAPYrates(
        uint16 _newPercentagePer1Month,
        uint16 _newPercentagePer3Month,
        uint16 _newPercentagePer6Month,
        uint16 _newPercentagePer12Month
    ) public {
        require(managers.isManager(msg.sender), "Not authorized");
        string memory _title = "Change Stake APY Rates";
        bytes32 _valueInBytes = keccak256(
            abi.encodePacked(
                _newPercentagePer1Month,
                _newPercentagePer3Month,
                _newPercentagePer6Month,
                _newPercentagePer12Month
            )
        );
        managers.approveTopic(_title, _valueInBytes);

        if (managers.isApproved(_title, _valueInBytes)) {
            stakePercentagePer1Month = _newPercentagePer1Month;
            stakePercentagePer3Month = _newPercentagePer3Month;
            stakePercentagePer6Month = _newPercentagePer6Month;
            stakePercentagePer12Month = _newPercentagePer12Month;
            managers.deleteTopic(_title);
            emit StakePercentageChange(
                _newPercentagePer1Month,
                _newPercentagePer3Month,
                _newPercentagePer6Month,
                _newPercentagePer12Month
            );
        }
    }

    //Managers Function
    function changeEmergencyExitPenaltyRate(uint8 _newRate) public {
        require(managers.isManager(msg.sender), "Not authorized");
        string memory _title = "Change Emergency Exit Penalty Rate";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_newRate));
        managers.approveTopic(_title, _valueInBytes);

        if (managers.isApproved(_title, _valueInBytes)) {
            emergencyExitPenaltyRate = _newRate;
            managers.deleteTopic(_title);
        }
    }

    function stake(uint256 _amount, uint8 _monthToStake) public whenNotPaused {
        require(_amount > 0, "Amount must be greater than Zero.");
        require(tokenContract.balanceOf(msg.sender) >= _amount, "Amount cannot be greater than your balance.");

        //_amount will send to contract balance
        require(tokenContract.transferFrom(msg.sender, address(this), _amount), "Token Transfer to Contract failed.");

        //Calculations of stakePercentage and release dates for different time ranges
        uint16 stakePercentage = stakePercentagePer1Month;
        if (_monthToStake >= 3 && _monthToStake < 6) {
            _monthToStake = 3;
            stakePercentage = stakePercentagePer3Month;
        } else if (_monthToStake >= 6 && _monthToStake < 12) {
            _monthToStake = 6;
            stakePercentage = stakePercentagePer6Month;
        } else if (_monthToStake >= 12) {
            _monthToStake = 12;
            stakePercentage = stakePercentagePer12Month;
        } else {
            _monthToStake = 1;
        }

        StakeData memory stakeDetails = StakeData({
            amount: _amount,
            stakeDate: block.timestamp,
            maxProfitDate: block.timestamp + (maxMonthToProfit * monthToSecond),
            percentage: stakePercentage,
            monthToStake: _monthToStake,
            releaseDate: block.timestamp + (_monthToStake * monthToSecond),
            withdrawn: false
        });

        //stakes array for access to my stakeDetails array
        stakes[msg.sender].push(stakeDetails);
        totalStakedAmount += _amount;
        //if isStaker not true, push msg.sender to the stakers array and make isStaker of msg.sender true
        if (isStaker[msg.sender] != true) {
            stakers.push(msg.sender);
            isStaker[msg.sender] = true;
        }

        emit Stake(msg.sender, _amount, stakeDetails.stakeDate, stakeDetails.releaseDate);
    }

    function fetchStakeDataForAddress(address _address) public view returns (StakeData[] memory) {
        return stakes[_address];
    }

    function fetchOwnStakeData() public view returns (StakeData[] memory) {
        return stakes[msg.sender];
    }

    function emergencyWithdrawStake(uint256 _stakeIndex) external {
        require(stakes[msg.sender][_stakeIndex].withdrawn == false, "Stake already withdrawn.");
        require(block.timestamp < stakes[msg.sender][_stakeIndex].releaseDate, "Withdraw normal");

        uint256 _dateDiff = block.timestamp - stakes[msg.sender][_stakeIndex].stakeDate;
        if (block.timestamp > stakes[msg.sender][_stakeIndex].maxProfitDate) {
            _dateDiff = stakes[msg.sender][_stakeIndex].maxProfitDate - stakes[msg.sender][_stakeIndex].stakeDate;
        }
        uint256 _totalAmount = stakes[msg.sender][_stakeIndex].amount +
            ((stakes[msg.sender][_stakeIndex].amount * stakes[msg.sender][_stakeIndex].percentage * _dateDiff) /
                (yearToSecond * 100));

        uint256 _emergencyExitPenalty = (_totalAmount * emergencyExitPenaltyRate) / 100;
        uint256 _amountAfterPenalty = _totalAmount - _emergencyExitPenalty;
        require(tokenContract.transfer(msg.sender, _amountAfterPenalty), "Token transfer failed.");
        tokenContract.burn(_emergencyExitPenalty);
        stakes[msg.sender][_stakeIndex].withdrawn = true;
        totalStakedAmount -= stakes[msg.sender][_stakeIndex].amount;
        totalDistributedReward += (_amountAfterPenalty - stakes[msg.sender][_stakeIndex].amount) > 0
            ? (_amountAfterPenalty - stakes[msg.sender][_stakeIndex].amount)
            : 0;

        emit EmergencyWithdraw(msg.sender, _amountAfterPenalty, block.timestamp);
    }

    function withdrawStake(uint256 _stakeIndex) external {
        require(stakes[msg.sender][_stakeIndex].withdrawn == false, "Stake already withdrawn.");
        require(block.timestamp >= stakes[msg.sender][_stakeIndex].releaseDate, "You must wait for the Release Date.");

        //block.timestamp is now. If now reaches maxProfitDate, we will use maxProfitDate for calculations
        uint256 _dateDiff = block.timestamp - stakes[msg.sender][_stakeIndex].stakeDate;
        if (block.timestamp > stakes[msg.sender][_stakeIndex].maxProfitDate) {
            _dateDiff = stakes[msg.sender][_stakeIndex].maxProfitDate - stakes[msg.sender][_stakeIndex].stakeDate;
        }
        uint256 _totalAmount = stakes[msg.sender][_stakeIndex].amount +
            ((stakes[msg.sender][_stakeIndex].amount * stakes[msg.sender][_stakeIndex].percentage * _dateDiff) /
                (yearToSecond * 100));

        require(tokenContract.transfer(msg.sender, _totalAmount), "Token Transfer from Contract failed.");
        stakes[msg.sender][_stakeIndex].withdrawn = true;
        totalStakedAmount -= stakes[msg.sender][_stakeIndex].amount;
        totalDistributedReward += _totalAmount - stakes[msg.sender][_stakeIndex].amount;
        emit Withdraw(msg.sender, _totalAmount, block.timestamp);
    }

    function fetchStakeReward(address _address, uint256 _stakeIndex) public view returns (uint256) {
        uint256 _dateDiff = block.timestamp - stakes[_address][_stakeIndex].stakeDate;
        if (block.timestamp > stakes[_address][_stakeIndex].maxProfitDate) {
            _dateDiff = stakes[_address][_stakeIndex].maxProfitDate - stakes[_address][_stakeIndex].stakeDate;
        }
        uint256 _totalAmount = stakes[_address][_stakeIndex].amount +
            ((stakes[_address][_stakeIndex].amount * stakes[_address][_stakeIndex].percentage * _dateDiff) /
                (yearToSecond * 100));
        return _totalAmount;
    }

    function fetchOwnStakeReward(uint256 _stakeIndex) public view returns (uint256) {
        uint256 _dateDiff = block.timestamp - stakes[msg.sender][_stakeIndex].stakeDate;
        if (block.timestamp > stakes[msg.sender][_stakeIndex].maxProfitDate) {
            _dateDiff = stakes[msg.sender][_stakeIndex].maxProfitDate - stakes[msg.sender][_stakeIndex].stakeDate;
        }
        uint256 _totalAmount = stakes[msg.sender][_stakeIndex].amount +
            ((stakes[msg.sender][_stakeIndex].amount * stakes[msg.sender][_stakeIndex].percentage * _dateDiff) /
                (yearToSecond * 100));
        return _totalAmount;
    }

    function fetchStakers() public view returns (address[] memory) {
        return stakers;
    }
}

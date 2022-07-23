// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IManagers.sol";
import "hardhat/console.sol";

contract Vault {
    IManagers managers;
    address public soulsTokenAddress;
    address public proxyAddress;

    uint256 public releasedAmount;
    uint256 public currentVestingIndex;
    uint256 public totalWithdrawnAmount;
    /**
	@dev must be assigned in constructor on of these: 
	"Marketing", "Advisor", "Airdrop", "Exchanges", "Treasury" or "Team"
	 */
    string public vaultName;

    struct LockedToken {
        uint256 amount;
        uint256 unlockTime;
        bool released;
    }

    LockedToken[] public tokenVestings;
    //    mapping(uint256 => LockedToken) public tokenVestings;

    event Withdraw(uint256 indexed date, uint256 indexed amount);
    event ReleaseVesting(uint256 indexed date, uint256 indexed vestingIndex);

    modifier onlyOnce() {
        require(tokenVestings.length == 0, "Only once function was called before");
        _;
    }
    modifier onlyProxy() {
        require(msg.sender == proxyAddress, "Not authorized");
        _;
    }

    modifier onlyManager() {
        require(managers.isManager(msg.sender), "Not authorized");
        _;
    }

    constructor(
        string memory _vaultName,
        address _proxyAddress,
        address _soulsTokenAddress,
        address _managersAddress
    ) {
        require(_proxyAddress != address(0), "Invalid proxy address");
        require(_managersAddress != address(0), "Invalid managers address");
        require(_soulsTokenAddress != address(0), "Invalid token address");
        vaultName = _vaultName;
        proxyAddress = _proxyAddress;
        soulsTokenAddress = _soulsTokenAddress;
        managers = IManagers(_managersAddress);
    }

    function lockTokens(
        uint256 _totalAmount,
        uint256 _initialRelease,
        uint256 _lockDurationInDays,
        uint256 _countOfVestings,
        uint256 _releaseFrequencyInDays
    ) public virtual onlyOnce onlyProxy {
        require(_totalAmount > 0, "Zero amount");
        require(_countOfVestings > 0, "Invalid vesting count");
        if (_countOfVestings != 1) {
            require(_releaseFrequencyInDays > 0, "Invalid frequency");
        }

        IERC20 _soulsToken = IERC20(soulsTokenAddress);
        _soulsToken.transferFrom(msg.sender, address(this), _totalAmount);

        uint256 _amountUsed = 0;

        if (_initialRelease > 0) {
            tokenVestings.push(LockedToken({amount: _initialRelease, unlockTime: block.timestamp, released: false}));
            _amountUsed += _initialRelease;
        }
        uint256 lockDuration = _lockDurationInDays * 1 days;
        uint256 releaseFrequency = _releaseFrequencyInDays * 1 days;
        for (uint256 i = 0; i < _countOfVestings; i++) {
            uint256 _amount = (_totalAmount - _initialRelease) / _countOfVestings;
            if (i == _countOfVestings - 1) {
                _amount = _totalAmount - _amountUsed; //use remaining dusts from division
            }
            tokenVestings.push(
                LockedToken({
                    amount: _amount,
                    unlockTime: block.timestamp + lockDuration + (i * releaseFrequency),
                    released: false
                })
            );
            _amountUsed += _amount;
        }
    }

    //Managers function
    function withdrawTokens(address[] calldata _receivers, uint256[] calldata _amounts) external virtual onlyManager {
        require(_receivers.length == _amounts.length, "Receivers and Amounts must be in same size");
        uint256 _totalAmount;
        for (uint256 i = 0; i < _amounts.length; i++) {
            _totalAmount += _amounts[i];
        }
        _withdrawTokens(_receivers, _amounts, _totalAmount);
    }

    function _withdrawTokens(
        address[] calldata _receivers,
        uint256[] calldata _amounts,
        uint256 _totalAmount
    ) internal {
        if (_totalAmount > releasedAmount - totalWithdrawnAmount) {
            require(currentVestingIndex < tokenVestings.length, "Not enough released tokens and no more vesting");
            require(block.timestamp >= tokenVestings[currentVestingIndex].unlockTime, "Wait for vesting release date");
            require(
                tokenVestings[currentVestingIndex].amount + releasedAmount - totalWithdrawnAmount >= _totalAmount,
                "Not enough amount in released balance"
            );
        }

        string memory _title = "Withdraw Tokens With From Vault";

        bytes32 _valueInBytes = keccak256(abi.encodePacked(_receivers, _amounts));
        managers.approveTopic(_title, _valueInBytes);

        if (managers.isApproved(_title, _valueInBytes)) {
            IERC20 _soulsToken = IERC20(soulsTokenAddress);
            bool _hasTransferError;
            for (uint256 r = 0; r < _receivers.length; r++) {
                address _receiver = _receivers[r];
                uint256 _amount = _amounts[r];
                require(_amount > 0, "Zero token amount in data");

                //Ignore ERC20 transfer errors wity try/catch to revert with custom error
                try _soulsToken.transfer(_receiver, _amount) returns (bool) {} catch {
                    _hasTransferError = true;
                }
            }
            if (_totalAmount > releasedAmount - totalWithdrawnAmount) {
                //Needs to release new vesting
                uint256 _vestingIndex = currentVestingIndex;
                currentVestingIndex++;

                tokenVestings[_vestingIndex].released = true;
                releasedAmount += tokenVestings[_vestingIndex].amount;
                emit ReleaseVesting(block.timestamp, _vestingIndex);
            }

            totalWithdrawnAmount += _totalAmount;
            emit Withdraw(block.timestamp, _totalAmount);
            managers.deleteTopic(_title);
            require(_hasTransferError == false, "Unhandled transfer error");
        }
    }

    function getVestingData() public view returns (LockedToken[] memory) {
        return tokenVestings;
    }

    function getAvailableAmountForWithdraw() public view returns (uint256 _amount) {
        _amount = releasedAmount - totalWithdrawnAmount;
        if (
            currentVestingIndex < tokenVestings.length &&
            block.timestamp >= tokenVestings[currentVestingIndex].unlockTime &&
            tokenVestings[currentVestingIndex].released == false
        ) {
            _amount += tokenVestings[currentVestingIndex].amount;
        }
    }
}

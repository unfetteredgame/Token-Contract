// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IManagers.sol";

/// @title Base contract for vaults which has vesting schedule.
/// @dev This contract must be inherited for Marketing Vault, Advertising Vault, Team Vault etc.
abstract contract VestingVaultBase {
    IManagers managers;
    address soulsTokenAddress;
    address proxyAddress;

    uint256 public releasedAmount;
    uint256 public currentVestingIndex;
    uint256 public numberOfVesting;
    uint256 public totalWithdrawnAmount;

    struct TokenVesting {
        uint256 amount;
        uint256 unlockTimestamp;
        bool released;
    }

    mapping(uint256 => TokenVesting) public tokenVestings;

    event Withdraw(uint256 indexed vestingIndex, uint256 indexed amount);

    modifier onlyOnce() {
        require(tokenVestings[0].amount == 0, "Only once function called before");
        _;
    }
    modifier onlyProxy() {
        require(msg.sender == proxyAddress, "Not authorized");
        _;
    }

    constructor(address _proxyAddress) {
        require(_proxyAddress != address(0), "Invalid proxy address");
        proxyAddress = _proxyAddress;
    }

    function lockTokens(
        uint256 _totalAmount,
        uint256 _cliffDurationInDays,
        uint256 _releaseFrequencyInDays,
        uint256 _numberOfVesting
    ) public virtual onlyOnce onlyProxy {
        require(_totalAmount > 0, "Zero amount");
        require(_releaseFrequencyInDays > 0, "Invalid frequency");
        require(_numberOfVesting > 0, "Invalid vesting count");

        IERC20 _soulsToken = IERC20(soulsTokenAddress);
        require(_soulsToken.transferFrom(msg.sender, address(this), _totalAmount), "Token transfer failed!");

        uint256 cliffDuration = _cliffDurationInDays * 1 days;
        uint256 releaseFrequency = _releaseFrequencyInDays * 1 days;
        numberOfVesting = _numberOfVesting;

        for (uint256 i = 0; i <= _numberOfVesting; i++) {
            tokenVestings[i] = TokenVesting({
                amount: _totalAmount / _numberOfVesting,
                unlockTimestamp: block.timestamp + cliffDuration + (i * releaseFrequency),
                released: false
            });
        }
    }

    //Managers function
    /// @dev Must be overridden in derived contracts as managers function
    function withdrawTokens(address[] memory _receivers, uint256[] memory _amounts) external virtual;

    //Sample withdrawTokens ovverride function

    // function withdrawTokens(address[] memory _receivers, uint256[] memory _amounts) external override {
    //     require(managers.isManager(msg.sender), "Not authorized");
    //     require(_receivers.length == _amounts.length, "Invalid parameters");
    //     string memory _title = "Withdraw Tokens From Vault"; // TODO: Add vault name to end of string.
    //     bytes32 _valueInBytes = keccak256(abi.encodePacked(_receivers, _amounts));
    //     managers.approveTopic(_title, _valueInBytes);

    //     if (managers.isApproved(_title, _valueInBytes)) {
    //         uint256 _vestingIndex = currentVestingIndex;
    //         require(block.timestamp >= tokenVestings[_vestingIndex].unlockTimestamp, "Tokens are still locked!");

    //         if (currentVestingIndex < numberOfVesting - 1) {
    //             currentVestingIndex++;
    //             require(tokenVestings[_vestingIndex].released == false, "Withdrawn before");
    //             tokenVestings[_vestingIndex].released = true;
    //             releasedAmount += tokenVestings[_vestingIndex].amount;
    //         }

    //         IERC20 _soulsToken = IERC20(soulsTokenAddress);
    //         uint256 _totalAmount;
    //         for (uint256 r = 0; r < _receivers.length; r++) {
    //             address _receiver = _receivers[r];
    //             uint256 _amount = _amounts[r];
    //             _totalAmount += _amount;
    //             require(_soulsToken.transfer(_receiver, _amount), "Token transfer failed!");
    //         }
    //         releasedAmount -= _totalAmount;
    //         totalWithdrawnAmount += _totalAmount;
    //         require(releasedAmount >= 0, "Amount exeeds released amount");
    //         emit Withdraw(_vestingIndex, _totalAmount);
    //         managers.deleteTopic(_title);
    //     }
    // }
}

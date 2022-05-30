// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./_VestingVaultBase.sol";

contract PlayToEarnVault is VestingVaultBase {
    uint256 gameLaunchTime;

    constructor(
        address _soulsTokenAddress,
        address _managersAddress,
        address _proxyAddress,
        uint256 _gameLaunchTime
    ) VestingVaultBase(_proxyAddress) {
        soulsTokenAddress = _soulsTokenAddress;
        managers = IManagers(_managersAddress);
        gameLaunchTime = _gameLaunchTime;
    }

    //Managers function
    function lockTokens(
        uint256 _totalAmount,
        uint256 _cliffDurationInDays,
        uint256 _releaseFrequencyInDays,
        uint256 _numberOfVesting
    ) public override onlyOnce {
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
                unlockTimestamp: gameLaunchTime + cliffDuration + (i * releaseFrequency),
                released: false
            });
        }
    }

    //Managers function
    function withdrawTokens(address[] memory _receivers, uint256[] memory _amounts) external override {
        require(managers.isManager(msg.sender), "Not authorized");
        require(_receivers.length == _amounts.length, "Invalid parameters");
        string memory _title = "Withdraw Tokens From Play To Earn Vault";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_receivers, _amounts));
        managers.approveTopic(_title, _valueInBytes);

        if (managers.isApproved(_title, _valueInBytes)) {
            uint256 _vestingIndex = currentVestingIndex;
            require(block.timestamp >= tokenVestings[_vestingIndex].unlockTimestamp, "Tokens are still locked!");

            if (currentVestingIndex < numberOfVesting - 1) {
                currentVestingIndex++;
                require(tokenVestings[_vestingIndex].released == false, "Withdrawn before");
                tokenVestings[_vestingIndex].released = true;
                releasedAmount += tokenVestings[_vestingIndex].amount;
            }

            IERC20 _soulsToken = IERC20(soulsTokenAddress);
            uint256 _totalAmount;
            for (uint256 r = 0; r < _receivers.length; r++) {
                address _receiver = _receivers[r];
                uint256 _amount = _amounts[r];
                _totalAmount += _amount;
                require(_soulsToken.transfer(_receiver, _amount), "Token transfer failed!");
            }
            releasedAmount -= _totalAmount;
            totalWithdrawnAmount += _totalAmount;
            require(releasedAmount >= 0, "Amount exeeds released amount");
            emit Withdraw(_vestingIndex, _totalAmount);
            managers.deleteTopic(_title);
        }
    }
}

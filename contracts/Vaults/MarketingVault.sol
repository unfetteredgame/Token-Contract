// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./_VestingVaultBase.sol";

contract MarketingVault is VestingVaultBase {
    constructor(address _soulsTokenAddress, address _managersAddress, address _proxyAddress) VestingVaultBase(_proxyAddress) {
        soulsTokenAddress = _soulsTokenAddress;
        managers = IManagers(_managersAddress);
    }

    function withdrawTokens(address[] memory _receivers, uint256[] memory _amounts) external override {
        require(managers.isManager(msg.sender), "Not authorized");
        require(_receivers.length == _amounts.length, "Invalid parameters");
        string memory _title = "Withdraw Tokens From Marketing Vault";
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

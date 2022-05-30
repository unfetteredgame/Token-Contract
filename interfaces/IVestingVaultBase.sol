// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVestingVaultBase {
    function lockTokens(
        uint256 _totalAmount,
        uint256 _cliffDurationInDays,
        uint256 _releaseFrequencyInDays,
        uint256 _numberOfVesting
    ) external;

    function withdrawTokens(address[] memory _receivers, uint256[] memory _amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidityVault {
    function lockTokens(
        uint256 _totalAmount
    ) external;

    function withdrawTokens(address[] memory _receivers, uint256[] memory _amounts) external;

	function getDEXPairAddress() external view returns (address);
}

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
    uint256 public countOfVesting;
    uint256 public totalWithdrawnAmount;
    uint256 public unlockTime;
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
        require(countOfVesting == 0, string.concat(vaultName, "Only once function was called before"));
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
        uint256 _lockDurationInDays,
        uint256 _countOfVesting,
        uint256 _releaseFrequencyInDays
    ) public virtual onlyOnce onlyProxy {
        require(_totalAmount > 0, "Zero amount");
        require(_countOfVesting > 0, "Invalid vesting count");
        if (_countOfVesting != 1) {
            require(_releaseFrequencyInDays > 0, "Invalid frequency");
        }

        IERC20 _soulsToken = IERC20(soulsTokenAddress);
        _soulsToken.transferFrom(msg.sender, address(this), _totalAmount);
        uint256 lockDuration = _lockDurationInDays * 1 days;
        uint256 releaseFrequency = _releaseFrequencyInDays * 1 days;
        countOfVesting = _countOfVesting;
        unlockTime = block.timestamp + lockDuration;

        for (uint256 i = 0; i < _countOfVesting; i++) {
            tokenVestings.push(
                LockedToken({
                    amount: _totalAmount / _countOfVesting,
                    unlockTime: block.timestamp + lockDuration + (i * releaseFrequency),
                    released: false
                })
            );
        }
    }

    //Managers function
    function withdrawTokens(address[] calldata _receivers, uint256[] calldata _amounts) external virtual onlyManager {
        require(_receivers.length == _amounts.length, "Invalid parameter lengths");
        require(block.timestamp >= unlockTime, "Tokens are locked");
        string memory _title = "Withdraw Tokens With From Vault";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_receivers, _amounts));
        managers.approveTopic(_title, _valueInBytes);

        if (managers.isApproved(_title, _valueInBytes)) {
            IERC20 _soulsToken = IERC20(soulsTokenAddress);
            uint256 _totalAmount;
			bool _hasTransferError;
            for (uint256 r = 0; r < _receivers.length; r++) {
                address _receiver = _receivers[r];
                uint256 _amount = _amounts[r];
                require(_amount > 0, "Zero token amount in data");
                _totalAmount += _amount;

				//Ignore ERC20 transfer errors wity try/catch to revert with custom error
                try _soulsToken.transfer(_receiver, _amount) returns (bool){

				} catch{
					_hasTransferError = true;
				}
            }
            if (_totalAmount > releasedAmount - totalWithdrawnAmount) {
                //Needs to release new vesting
                uint256 _vestingIndex = currentVestingIndex;

                require(_vestingIndex < countOfVesting, "Not enought balance and no more vesting");
                require(block.timestamp >= tokenVestings[_vestingIndex].unlockTime, "Wait for vesting release date");
                require(
                    tokenVestings[_vestingIndex].amount + releasedAmount - totalWithdrawnAmount >= _totalAmount,
                    "Not enough amount in released balance"
                );
                currentVestingIndex++;

                tokenVestings[_vestingIndex].released = true;
                releasedAmount += tokenVestings[_vestingIndex].amount;
                emit ReleaseVesting(block.timestamp, _vestingIndex);
            }

            totalWithdrawnAmount += _totalAmount;
            emit Withdraw(block.timestamp, _totalAmount);
            managers.deleteTopic(_title);
			require (_hasTransferError == false, "Unhandled transfer exception");
        }
    }

    function getVestingData() public view returns (LockedToken[] memory) {
        return tokenVestings;
    }

    function getAvailableAmountForWithdraw() public view returns (uint256 _amount) {
        _amount = releasedAmount - totalWithdrawnAmount;
        if (
            currentVestingIndex < countOfVesting &&
            block.timestamp >= tokenVestings[currentVestingIndex].unlockTime &&
            tokenVestings[currentVestingIndex].released == false
        ) {
            _amount += tokenVestings[currentVestingIndex].amount;
        }
    }
}

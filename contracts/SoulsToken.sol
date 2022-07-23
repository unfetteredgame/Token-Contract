// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IManagers.sol";
import "hardhat/console.sol";

contract SoulsToken is ERC20Burnable, Ownable {
    struct BotProtectionParams {
        uint256 activateIfBalanceExeeds;
        uint256 maxSellAmount;
        uint256 durationBetweenSells;
    }

    IManagers managers;
    BotProtectionParams public botProtectionParams;

    uint256 public maxSupply = 3000000000 ether;
    uint256 public tradingStartTimeOnDEX;
    uint256 public botProtectionDuration = 0 seconds; //Will be set in enableTrading function

    address public dexPairAddress;
    address public proxyAddress;

    bool public tradingEnabled = true;

    mapping(address => uint256) public walletCanSellAfter;
    mapping(address => uint256) private boughtAmountDuringBotProtection;

    modifier onlyManager() {
        require(managers.isManager(msg.sender), "Not authorized");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyAddress,
        address _managersAddress
    ) ERC20(_name, _symbol) {
        require(_proxyAddress != address(0), "Zero address");
        require(_managersAddress != address(0), "Zero address");

        _mint(msg.sender, maxSupply);
        //TODO: Decide the parameter values for bot protection
        botProtectionParams = BotProtectionParams({
            activateIfBalanceExeeds: 10000 ether,
            maxSellAmount: 1000 ether,
            durationBetweenSells: 10 minutes
        });
        proxyAddress = _proxyAddress;
        managers = IManagers(_managersAddress);
    }

    //Managers function
    function enableTrading(uint256 _tradingStartTime, uint256 _botProtectionDurationInHours) external onlyManager {
        require(tradingEnabled == false, "Already enabled");
        string memory _title = "Enable Trading";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_tradingStartTime, _botProtectionDurationInHours));
        managers.approveTopic(_title, _valueInBytes);
        if (managers.isApproved(_title, _valueInBytes)) {
            tradingEnabled = true;
            tradingStartTimeOnDEX = _tradingStartTime;
            botProtectionDuration = _botProtectionDurationInHours * 1 hours;
            managers.deleteTopic(_title);
        }
    }

    //Managers function
    /// @notice To disable trading on DEX in case of security problem.
    function disableTrading() external onlyManager {
        require(tradingEnabled == true, "Already disabled");
        string memory _title = "Disable Trading";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(true));
        managers.approveTopic(_title, _valueInBytes);

        if (managers.isApproved(_title, _valueInBytes)) {
            tradingEnabled = false;
            managers.deleteTopic(_title);
        }
    }

    /// @notice Sets pair address of DEX for using bot protection functions
    /// @dev Set this value from proxy contract after creating liquidity
    /// @param _pairAddress is the address of SOULS-BUSD pair on DEX

    function setDexPairAddress(address _pairAddress) external onlyOwner {
        require(dexPairAddress == address(0), "Already set"); //Cannot change after initialization
        require(_pairAddress != address(0), "Cannot set to zero address");
        dexPairAddress = _pairAddress;
        tradingEnabled = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        if (((dexPairAddress != address(0) && (from == dexPairAddress)) || to == dexPairAddress)) {
            //Trade transaction
            require(tradingEnabled == true, "Trading is disabled");
            require(block.timestamp > tradingStartTimeOnDEX, "Trading not started");
            if (block.timestamp < tradingStartTimeOnDEX + botProtectionDuration) {
                //While bot protection is active
                if (to == dexPairAddress) {
                    //Selling Souls
                    console.log("trying to sell 1");
                    require(block.timestamp > walletCanSellAfter[from], "Bot protection time lock");
                    console.log("trying to sell 2");
                    if (walletCanSellAfter[from] > 0) {
                        console.log("trying to sell 3");

                        require(amount <= botProtectionParams.maxSellAmount, "Bot protection amount lock");
                        console.log("trying to sell 4");
                    }
                }
            }
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // if (from != address(0) && (from == dexPairAddress || to == dexPairAddress)) {
        if (dexPairAddress != address(0) && block.timestamp < tradingStartTimeOnDEX + botProtectionDuration) {
            if (from == dexPairAddress) {
                //Buying Souls
                if (
                    block.timestamp > tradingStartTimeOnDEX &&
                    block.timestamp < tradingStartTimeOnDEX + botProtectionDuration
                ) {
                    boughtAmountDuringBotProtection[to] += amount;
                }
                if (boughtAmountDuringBotProtection[to] > botProtectionParams.activateIfBalanceExeeds) {
                    //Start following account
                    walletCanSellAfter[to] = block.timestamp + botProtectionParams.durationBetweenSells;
                }
            }
            if (to == dexPairAddress) {
                //Selling Souls
                if (
                    block.timestamp > tradingStartTimeOnDEX &&
                    block.timestamp < tradingStartTimeOnDEX + botProtectionDuration
                ) {
                    boughtAmountDuringBotProtection[from] -= amount;
                }
                if (walletCanSellAfter[from] > 0) {
                    //Account is followed by bot protection
                    walletCanSellAfter[from] = block.timestamp + botProtectionParams.durationBetweenSells;
                }
            }
        }
    }
}

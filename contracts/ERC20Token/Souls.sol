// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Managers/Manageable.sol";

/// TODO: Must be deployed by token proxy contract
contract Souls is ERC20, Manageable {
    uint256 tradingStartTimeOnDEX;
    uint256 botProtectionDuration = 1 hours;

    bool tradingEnabled = false;

    address public dexPairAddress;

    struct BotProtectionParams {
        uint256 maxBuyAmountOnDEX;
        uint256 maxSellAmountOnDEX;
        uint256 durationBetweenTrades;
    }

    struct WalletStateForBotProtection {
        uint256 canBuyAfterTime;
        uint256 canSellAfterTime;
    }

    BotProtectionParams public botProtectionParams;
    mapping(address => WalletStateForBotProtection) private walletStateForBotProtection;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _supply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _supply);
        botProtectionParams = BotProtectionParams({
            maxBuyAmountOnDEX: 1000 ether,
            maxSellAmountOnDEX: 1000 ether,
            durationBetweenTrades: 1 minutes
        });
    }

    function enableTrading(uint256 _tradingStartTime) external onlyManagers(msg.sender) {
        require(tradingEnabled == false, "Already enabled");
        string memory _title = "enableTrading";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_tradingStartTime));
        vote(_title, _valueInBytes);

        if (isApproved(_title, _valueInBytes)) {
            tradingEnabled = true;
            tradingStartTimeOnDEX = _tradingStartTime;
            _deleteTopic(_title);
        }
    }

    // function setBotProtection(bool _value) external onlyManagers(msg.sender) {
    //     require(tradingEnabled == true, "Already disabled");
    //     string memory _title = "setBotProtection";
    //     bytes32 _valueInBytes = keccak256(abi.encodePacked(_value));
    //     vote(_title, _valueInBytes);

    //     if (isApproved(_title, _valueInBytes)) {
    //         botProtectionEnabled = _value;
    //         _deleteTopic(_title);
    //     }
    // }

    // TODO: Must be called by token proxy contract after adding liquidity
    function setDexPairAddress(address _pairAddress) external onlyOwner {
        require(dexPairAddress == address(0), "Already set"); //Cannot change after initialization
        require(_pairAddress != address(0), "Cannot set to zero address");
        dexPairAddress = _pairAddress;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(tradingEnabled, "Trading is disabled");
        require(block.timestamp > tradingStartTimeOnDEX, "Trading not started");
        if (block.timestamp < tradingStartTimeOnDEX + botProtectionDuration) {
            //While bot protection is active
            if (from == dexPairAddress) {
                //Buying Souls
                require(
                    block.timestamp > walletStateForBotProtection[msg.sender].canBuyAfterTime,
                    "Bot protection time lock"
                );
                require(amount <= botProtectionParams.maxBuyAmountOnDEX, "Bot protection amount lock");
                walletStateForBotProtection[msg.sender].canSellAfterTime =
                    block.timestamp +
                    botProtectionParams.durationBetweenTrades;
                walletStateForBotProtection[msg.sender].canBuyAfterTime =
                    block.timestamp +
                    botProtectionParams.durationBetweenTrades;
            }
            if (to == dexPairAddress) {
                //Selling Souls
                require(
                    block.timestamp > walletStateForBotProtection[msg.sender].canSellAfterTime,
                    "Bot protection time lock"
                );
                require(amount <= botProtectionParams.maxSellAmountOnDEX, "Bot protection amount lock");
                walletStateForBotProtection[msg.sender].canSellAfterTime =
                    block.timestamp +
                    botProtectionParams.durationBetweenTrades;
                walletStateForBotProtection[msg.sender].canBuyAfterTime =
                    block.timestamp +
                    botProtectionParams.durationBetweenTrades;
            }
        }
    }
}

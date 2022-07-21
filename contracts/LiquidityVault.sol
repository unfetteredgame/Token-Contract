// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IManagers.sol";
import "./Vault.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakePair.sol";
import "hardhat/console.sol";

contract LiquidityVault is Vault {
    uint256 public tokenAmountForLiquidity = 60_000_000 ether; //Includes CEX and DEX
    uint256 public totalDEXShare = 27_000_000 ether;
    uint256 public tokenAmountForInitialLiquidityOnDEX = 3_000_000 ether; //Just for setting price, will be added more later manually
    uint256 public amountUsedForLiquidityOnDEX;
    uint256 public CEXShare = 33_000_000 ether;

    uint256 public marketMakerShare = 9_375_000 ether;
    uint256 public initialPriceForDex = 0.009 ether;
    uint256 public balanceAddedLiquidityOnDex;
    uint256 public remainingTokensUnlockTime;

    uint256 public marketMakerShareWithdrawDeadline;
    uint256 public marketMakerShareWithdrawnAmount;
    address public DEXPairAddress;
    address BUSDTokenAddress;
    address dexFactoryAddress;
    address dexRouterAddress;

    constructor(
        string memory _vaultName,
        address _proxyAddress,
        address _soulsTokenAddress,
        address _managersAddress,
        address _dexFactoryAddress,
        address _dexRouterAddress,
        address _BUSDTokenAddress
    ) Vault(_vaultName, _proxyAddress, _soulsTokenAddress, _managersAddress) {
        dexFactoryAddress = _dexFactoryAddress;
        dexRouterAddress = _dexRouterAddress;
        BUSDTokenAddress = _BUSDTokenAddress;
        marketMakerShareWithdrawDeadline = block.timestamp + 1 days;
    }

    function lockTokens(uint256 _totalAmount) public {
        require(_totalAmount == tokenAmountForLiquidity, "Invalid amount");
        super.lockTokens(_totalAmount, 0, 0, 1, 0);
        _createLiquidityOnDex(dexFactoryAddress, dexRouterAddress, BUSDTokenAddress);
        remainingTokensUnlockTime = block.timestamp + 365 days;
    }

    function BUSDAmountForInitialLiquidity() public view returns (uint256 _busdAmount) {
        _busdAmount = (tokenAmountForInitialLiquidityOnDEX * initialPriceForDex) / 1 ether;
    }

    function withdrawTokens(address[] calldata, uint256[] calldata) external pure override {
        revert("Use withdrawRemainingTokens function for Liquidity Vault");
    }

    function withdrawRemainingTokens(address[] calldata _receivers, uint256[] calldata _amounts) external {
        require(block.timestamp > remainingTokensUnlockTime, "Remaining tokens are still locked");
        require(_receivers.length == _amounts.length, "Receivers and Amounts must be in same size");
        _withdrawTokens(_receivers, _amounts);
    }

    function _createLiquidityOnDex(
        address _dexFactoryAddress,
        address _dexRouterAddress,
        address _BUSDTokenAddress
    ) internal {
        IPancakeFactory _pancakeFactory = IPancakeFactory(_dexFactoryAddress);
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(_dexRouterAddress);

        uint256 _BUSDAmountForLiquidty = BUSDAmountForInitialLiquidity();
        balanceAddedLiquidityOnDex += tokenAmountForInitialLiquidityOnDEX;
        tokenVestings[0].amount -= tokenAmountForInitialLiquidityOnDEX;

        IERC20(soulsTokenAddress).approve(_dexRouterAddress, type(uint256).max);
        IERC20(_BUSDTokenAddress).approve(_dexRouterAddress, type(uint256).max);

        _pancakeRouter.addLiquidity(
            soulsTokenAddress,
            _BUSDTokenAddress,
            tokenAmountForInitialLiquidityOnDEX,
            _BUSDAmountForLiquidty,
            tokenAmountForInitialLiquidityOnDEX,
            _BUSDAmountForLiquidty,
            proxyAddress,
            block.timestamp + 1 hours
        );

        DEXPairAddress = _pancakeFactory.getPair(soulsTokenAddress, BUSDTokenAddress);
        amountUsedForLiquidityOnDEX += tokenAmountForInitialLiquidityOnDEX;
    }

    function getDEXPairAddress() public view returns (address) {
        return DEXPairAddress;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS");
    }

    function _getReserves(address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = _sortTokens(tokenA, tokenB);
        IPancakeFactory _factory = IPancakeFactory(dexFactoryAddress);
        address _pairAddress = _factory.getPair(BUSDTokenAddress, soulsTokenAddress);
        IPancakePair pair = IPancakePair(_pairAddress);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getSoulsBalance() public view returns (uint256 _soulsBalance) {
        _soulsBalance = IERC20(soulsTokenAddress).balanceOf(address(this));
    }

    function getRequiredBUSDAmountForLiquidity(uint256 _tokenAmountToAdd)
        public
        view
        returns (uint256 _BUSDAmountForLiquidty)
    {
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(dexRouterAddress);
        (uint256 BUSDReserve, uint256 soulsReserve) = _getReserves(BUSDTokenAddress, soulsTokenAddress);
        _BUSDAmountForLiquidty = _pancakeRouter.quote(_tokenAmountToAdd, soulsReserve, BUSDReserve);
    }

    //Managers Function
    function addLiquidityOnDex(uint256 _tokenAmountToAdd) external onlyManager {
        require(_tokenAmountToAdd > 0, "Zero amount");
        uint256 _availableAmount = totalDEXShare - amountUsedForLiquidityOnDEX;
		console.log("available amount: %s", _availableAmount);
        if (block.timestamp > marketMakerShareWithdrawDeadline) {
            _availableAmount += (marketMakerShare - marketMakerShareWithdrawnAmount);
        }
        require(_availableAmount >= _tokenAmountToAdd, "Amount exeeds DEX Liquidity share");
        require(IERC20(soulsTokenAddress).balanceOf(address(this)) >= _tokenAmountToAdd, "Not enough SOULS token");

        string memory _title = "Add Liquidity On DEX";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_tokenAmountToAdd));
        managers.approveTopic(_title, _valueInBytes);
        if (managers.isApproved(_title, _valueInBytes)) {
            IPancakeRouter02 _pancakeRouter = IPancakeRouter02(dexRouterAddress);

            (uint256 BUSDReserve, uint256 soulsReserve) = _getReserves(BUSDTokenAddress, soulsTokenAddress);

            uint256 _BUSDAmountToAdd = _pancakeRouter.quote(_tokenAmountToAdd, soulsReserve, BUSDReserve);
            IERC20 BUSDToken = IERC20(BUSDTokenAddress);
            require(BUSDToken.balanceOf(proxyAddress) >= _BUSDAmountToAdd, "BUSD balance is not enough on proxy");

            balanceAddedLiquidityOnDex += _tokenAmountToAdd;
            tokenVestings[0].amount -= _tokenAmountToAdd;

            BUSDToken.transferFrom(proxyAddress, address(this), _BUSDAmountToAdd);

            _pancakeRouter.addLiquidity(
                soulsTokenAddress,
                BUSDTokenAddress,
                _tokenAmountToAdd,
                _BUSDAmountToAdd,
                0,
                0,
                proxyAddress,
                block.timestamp + 1 hours
            );

            managers.deleteTopic(_title);
        }
    }

    //Managers Function
    function withdrawMarketMakerShare(address _receiver, uint256 _amount) external onlyManager {
        require(block.timestamp < marketMakerShareWithdrawDeadline, "Late request");
        string memory _title = "Withdraw Market Maker Share";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_receiver, _amount));
        managers.approveTopic(_title, _valueInBytes);
        tokenVestings[0].amount -= _amount;

        if (managers.isApproved(_title, _valueInBytes)) {
            marketMakerShareWithdrawnAmount += _amount;
            require(marketMakerShareWithdrawnAmount <= marketMakerShare, "Amount exeeds the limits");
            IERC20 soulsToken = IERC20(soulsTokenAddress);
            soulsToken.transfer(_receiver, _amount);
            managers.deleteTopic(_title);
        }
    }
}

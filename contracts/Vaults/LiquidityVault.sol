// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/IPancakeRouter02.sol";
import "../../interfaces/IPancakeFactory.sol";
import "../../interfaces/IPancakePair.sol";
import "../../interfaces/IManagers.sol";

contract LiquidityVault {
    IManagers managers;

    uint256 public tokenAmountForLiquidity = 60_000_000 ether; //Includes CEX and DEX
    uint256 public tokenAmountForInitialLiquidityOnDEX = 10_000_000 ether; //Just for setting price, will be added more later manually
    uint256 public initialPriceForDex = 0.009 ether;
    uint256 addedBalance;

    uint256 public marketMakerShare = 20_000_000;
    uint256 public marketMakerShareWithdrawDeadline;
    uint256 public marketMakerShareWithdrawnAmount;

    address public DEXPairAddress;
    address soulsTokenAddress;
    address dexFactoryAddress;
    address dexRouterAddress;
    address BUSDTokenAddress;
    address proxyAddress;


    modifier onlyProxy() {
        require(msg.sender == proxyAddress, "Not authorized");
        _;
    }

    constructor(
        address _soulsTokenAddress,
        address _managersAddress,
        address _proxyAddress,
        address _dexFactoryAddress,
        address _dexRouterAddress,
        address _BUSDTokenAddress
    ) {
        soulsTokenAddress = _soulsTokenAddress;
        managers = IManagers(_managersAddress);
        dexFactoryAddress = _dexFactoryAddress;
        dexRouterAddress = _dexRouterAddress;
        BUSDTokenAddress = _BUSDTokenAddress;
        proxyAddress = _proxyAddress;
        marketMakerShareWithdrawDeadline = block.timestamp + 1 days;
    }

    function lockTokens(uint256 _totalAmount) public onlyProxy {
        require(_totalAmount == tokenAmountForLiquidity, "LIQUIDITY VAULT: Invalid Amount");
        require(addedBalance == 0, "LIQUIDITY VAULT: Only one time");
        addedBalance += _totalAmount;

        IERC20 _soulsToken = IERC20(soulsTokenAddress);
        require(
            _soulsToken.transferFrom(msg.sender, address(this), _totalAmount),
            "LIQUIDITY VAULT: Token transfer failed!"
        );

        _createLiquidityOnDex(dexFactoryAddress, dexRouterAddress, BUSDTokenAddress);
        //super.lockTokens(_totalAmount - tokenAmountForInitialLiquidityOnDEX, _cliffDurationInDays, _releaseFrequencyInDays, _numberOfVesting);
    }

    function _createLiquidityOnDex(
        address _dexFactoryAddress,
        address _dexRouterAddress,
        address _BUSDTokenAddress
    ) private {
        IPancakeFactory _pancakeFactory = IPancakeFactory(_dexFactoryAddress);
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(_dexRouterAddress);
        uint256 _BUSDAmountForLiquidty = (tokenAmountForInitialLiquidityOnDEX * initialPriceForDex) / 1 ether;

        //FIXME: uncomment below comment block for mainnet or testnet
        /*
	    _pancakeRouter.addLiquidity(
            soulsTokenAddress,
            _BUSDTokenAddress,
            tokenAmountForInitialLiquidityOnDEX,
            _BUSDAmountForLiquidty,
            tokenAmountForInitialLiquidityOnDEX,
            _BUSDAmountForLiquidty,
            msg.sender,
            block.timestamp + 1 hours
        );

        address _pairAddress = _pancakeFactory.getPair(
            0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7,
            0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
        );

		DEXPairAddress = _pairAddress
        soulsToken.setDexPairAddress(_pairAddress);
		*/
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

    //Managers Function
    function _addLiquidityOnDex(uint256 _tokenAmountToAdd) external {
        require(managers.isManager(msg.sender), "Not authorized");
        string memory _title = "Add Liquidity On DEX";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_tokenAmountToAdd));
        managers.approveTopic(_title, _valueInBytes);

        IPancakeFactory _pancakeFactory = IPancakeFactory(dexFactoryAddress);
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(dexRouterAddress);

        (uint256 BUSDReserve, uint256 soulsReserve) = _getReserves(BUSDTokenAddress, soulsTokenAddress);

        uint256 _BUSDAmountForLiquidty = _pancakeRouter.quote(_tokenAmountToAdd, soulsReserve, BUSDReserve);

        //FIXME: uncomment below comment block for mainnet or testnet
        /*
	    _pancakeRouter.addLiquidity(
            soulsTokenAddress,
            _BUSDTokenAddress,
            tokenAmountForInitialLiquidityOnDEX,
            _BUSDAmountForLiquidty,
            tokenAmountForInitialLiquidityOnDEX,
            _BUSDAmountForLiquidty,
            msg.sender,
            block.timestamp + 1 hours
        );
		*/
    }

    //Managers Function
    function withdrawMarketMakerShare(address _receiver, uint256 _amount) external {
        require(managers.isManager(msg.sender), "Not authorized");
        require(block.timestamp < marketMakerShareWithdrawDeadline, "LIQUIDITY VAULT: Late request");
        string memory _title = "Withdraw Market Maker Share";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_receiver, _amount));
        managers.approveTopic(_title, _valueInBytes);

        if (managers.isApproved(_title, _valueInBytes)) {
            marketMakerShareWithdrawnAmount += _amount;
            require(marketMakerShareWithdrawnAmount <= marketMakerShare, "LIQUIDITY VAULT: Amount exeeds the limits");
            IERC20 soulsToken = IERC20(soulsTokenAddress);
            soulsToken.transfer(_receiver, _amount);
            managers.deleteTopic(_title);
        }
    }
}

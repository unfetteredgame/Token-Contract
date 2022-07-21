// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../interfaces/IVault.sol";
import "../interfaces/ILiquidityVault.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/ICrowdFunding.sol";
import "./Managers.sol";
import "./SoulsToken.sol";
import "hardhat/console.sol";

contract Proxy is Ownable {
    using ERC165Checker for address;
    SoulsToken public soulsToken;
    Managers public managers;

    uint256 public liquidityTokensUnlockTime;

    //Tokenomi
    uint256 public marketingShare = 300_000_000 ether;
    uint256 public exchangesShare = 150_000_000 ether;
    uint256 public liquidityShare = 60_000_000 ether;
    uint256 public stakingShare = 300_000_000 ether;
    uint256 public advisorShare = 150_000_000 ether;
    uint256 public airdropShare = 90_000_000 ether;
    uint256 public teamShare = 300_000_000 ether;
    uint256 public treasuryShare = 210_000_000 ether;
    uint256 public playToEarnShare = 900_000_000 ether;

    address marketingVaultAddress;
    address teamVaultAddress;
    address advisorVaultAddress;
    address airdropVaultAddress;
    address exchangesVaultAddress;
    address liquidityVaultAddress;
    address playToEarnVaultAddress;
    address treasuryVaultAddress;
    address stakingAddress;
    address dexPairAddress;

    enum VaultEnumerator {
        MARKETING,
        ADVISOR,
        AIRDROP,
        TEAM,
        EXCHANGES,
        TREASURY
    }

    modifier onlyManager() {
        require(managers.isManager(msg.sender), "Not authorized");
        _;
    }

    constructor(
        address _manager1,
        address _manager2,
        address _manager3,
        address _manager4,
        address _manager5
    ) {
        require(
            _manager1 != address(0) &&
                _manager2 != address(0) &&
                _manager3 != address(0) &&
                _manager4 != address(0) &&
                _manager5 != address(0)
        );
        managers = new Managers(_manager1, _manager2, _manager3, _manager4, _manager5);
        soulsToken = new SoulsToken("SOULS", "Souls Token", address(this), address(managers));
        managers.addAddressToTrustedSources(address(soulsToken), "Souls Token");
    }

    function initStakingContract(address _stakingAddress) external onlyOwner {
        require(stakingAddress == address(0), "Already Inited");
        require(_stakingAddress != address(0), "Zero address");
        stakingAddress = _stakingAddress;

        IStaking _staking = IStaking(stakingAddress);
        require(soulsToken.transfer(address(_staking), stakingShare));
        managers.addAddressToTrustedSources(stakingAddress, "Staking");
    }

    function approveTokensForCrowdFundingContract(address _contractAddress) external onlyManager {
        require(_contractAddress != address(0), "Zero address");
        string memory _title = "Approve Tokens for Crowd Funding Contract";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_contractAddress));

        managers.approveTopic(_title, _valueInBytes);
        if (managers.isApproved(_title, _valueInBytes)) {
            soulsToken.approve(_contractAddress, type(uint256).max);
            managers.deleteTopic(_title);
        }
    }

    //Managers Function
    function transferTokensToCrowdFundingContract(address _contractAddress, uint256 _totalAmount) external onlyManager {
        require(_contractAddress != address(0), "Zero address");
        require(_totalAmount > 0, "Zero amount");
        require(_contractAddress.supportsInterface(type(ICrowdFunding).interfaceId), "Not crowdfunding contract");
        //require(ICrowdFunding(_contractAddress).isCrowdFunding(), "Not crowdfunding contract");

        string memory _title = "Transfer Tokens To Crowd Funding Contract";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_contractAddress, _totalAmount));
        managers.approveTopic(_title, _valueInBytes);
        if (managers.isApproved(_title, _valueInBytes)) {
            soulsToken.transfer(_contractAddress, _totalAmount);
            managers.deleteTopic(_title);
        }
    }

    //Managers Function
    function initPlayToEarnVault(address _playToEarnVaultAddress, uint256 _gameStartTime) external onlyManager {
        require(playToEarnVaultAddress == address(0), "Already Inited");
        require(_playToEarnVaultAddress != address(0), "Zero address");
        require(_gameStartTime < block.timestamp, "Game start time must be in the past");

        string memory _title = "Init Play To Earn Vault";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_gameStartTime));
        managers.approveTopic(_title, _valueInBytes);
        if (managers.isApproved(_title, _valueInBytes)) {
            playToEarnVaultAddress = _playToEarnVaultAddress;
            _initPlayToEarnVault(_gameStartTime);
            managers.deleteTopic(_title);
        }
    }

    function initLiquidityVault(address _liquidityVaultAddress, address _BUSDTokenAddress) external onlyOwner {
        require(liquidityVaultAddress == address(0), "Already Inited");
        liquidityVaultAddress = _liquidityVaultAddress;

        ILiquidityVault _liquidityVault = ILiquidityVault(liquidityVaultAddress);

        IERC20 BUSDToken = IERC20(_BUSDTokenAddress);
        BUSDToken.approve(liquidityVaultAddress, type(uint256).max);
        BUSDToken.transferFrom(msg.sender, liquidityVaultAddress, _liquidityVault.BUSDAmountForInitialLiquidity());

        soulsToken.approve(liquidityVaultAddress, liquidityShare);
        _liquidityVault.lockTokens(liquidityShare);
        liquidityTokensUnlockTime = block.timestamp + 365 days;
        //Set pair address on token contract for bot protection.
        dexPairAddress = _liquidityVault.getDEXPairAddress();
        soulsToken.setDexPairAddress(dexPairAddress);

        managers.addAddressToTrustedSources(liquidityVaultAddress, "Liquidity Vault");
    }

    function initVault(address _vaultAddress, VaultEnumerator _vaultToInit) external onlyOwner {
        string memory _vaultName;
        uint256 _vaultShare;
        uint256 _initialRelease;
        uint256 _cliffDuration;
        uint256 _vestingCount;
        uint256 _vestingFrequency;
        if (_vaultToInit == VaultEnumerator.MARKETING) {
            require(marketingVaultAddress == address(0), "Already Inited");
            require(_vaultAddress != address(0), "Zero address");
            marketingVaultAddress = _vaultAddress;
            _vaultName = "Marketing Vault";
            _vaultShare = marketingShare;
            _initialRelease = 6_000_000 ether;
            _cliffDuration = 90;
            _vestingCount = 24;
            _vestingFrequency = 30;
        } else if (_vaultToInit == VaultEnumerator.ADVISOR) {
            require(advisorVaultAddress == address(0), "Already Inited");
            require(_vaultAddress != address(0), "Zero address");

            advisorVaultAddress = _vaultAddress;
            _vaultName = "Advisor Vault";
            _vaultShare = advisorShare;
            _initialRelease = 0;
            _cliffDuration = 365;
            _vestingCount = 24;
            _vestingFrequency = 30;
        } else if (_vaultToInit == VaultEnumerator.AIRDROP) {
            require(airdropVaultAddress == address(0), "Already Inited");
            require(_vaultAddress != address(0), "Zero address");
            airdropVaultAddress = _vaultAddress;
            _vaultName = "Airdrop Vault";
            _vaultShare = airdropShare;
            _initialRelease = 0;
            _cliffDuration = 240;
            _vestingCount = 12;
            _vestingFrequency = 30;
        } else if (_vaultToInit == VaultEnumerator.TEAM) {
            require(teamVaultAddress == address(0), "Already Inited");
            require(_vaultAddress != address(0), "Zero address");
            teamVaultAddress = _vaultAddress;
            _vaultName = "Team Vault";
            _vaultShare = teamShare;
            _initialRelease = 0;
            _cliffDuration = 365;
            _vestingCount = 24;
            _vestingFrequency = 30;
        } else if (_vaultToInit == VaultEnumerator.EXCHANGES) {
            require(advisorVaultAddress == address(0), "Already Inited");
            require(_vaultAddress != address(0), "Zero address");
            advisorVaultAddress = _vaultAddress;
            _vaultName = "Advisor Vault";
            _vaultShare = advisorShare;
            _initialRelease = 0;
            _cliffDuration = 90;
            _vestingCount = 24;
            _vestingFrequency = 30;
        } else if (_vaultToInit == VaultEnumerator.TREASURY) {
            require(treasuryVaultAddress == address(0), "Already Inited");
            require(_vaultAddress != address(0), "Zero address");
            treasuryVaultAddress = _vaultAddress;
            _vaultName = "Treasury Vault";
            _vaultShare = treasuryShare;
            _initialRelease = 0;
            _cliffDuration = 90;
            _vestingCount = 36;
            _vestingFrequency = 30;
        } else {
            revert("Invalid vault");
        }

        soulsToken.approve(_vaultAddress, _vaultShare);
        IVault _vault = IVault(_vaultAddress);
        _vault.lockTokens(_vaultShare, _initialRelease, _cliffDuration, _vestingCount, _vestingFrequency);
        managers.addAddressToTrustedSources(_vaultAddress, _vaultName);
    }

    function _initPlayToEarnVault(uint256 _gameStartTime) internal {
        IVault _playToEarnVault = IVault(playToEarnVaultAddress);
        soulsToken.approve(playToEarnVaultAddress, playToEarnShare);
        uint256 daysSinceGameStartTime = (block.timestamp - _gameStartTime) / 1 days;
        _playToEarnVault.lockTokens(playToEarnShare, 0, 60 - daysSinceGameStartTime, 84, 30);
        managers.addAddressToTrustedSources(playToEarnVaultAddress, "PlayToEarn Vault");
    }

    function approveTokensToCrowdFundingContract(address _crowdFundingContractAddress) external onlyOwner {
        require(_crowdFundingContractAddress != address(0), "Zero address");
        soulsToken.approve(_crowdFundingContractAddress, type(uint256).max);
    }

    function withdrawLPTokens(address _to) external onlyManager {
        require(block.timestamp > liquidityTokensUnlockTime, "LP tokens are locked still");
        require(dexPairAddress != address(0), "Init Liquidity Vault first");
        require(_to != address(0), "Zero address");
        uint256 _tokenBalance = IERC20(dexPairAddress).balanceOf(address(this));
        require(_tokenBalance > 0, "Zero balance LP tokens");
        string memory _title = "Withdraw LP Tokens";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_to));
        managers.approveTopic(_title, _valueInBytes);

        if (managers.isApproved(_title, _valueInBytes)) {
            IERC20(dexPairAddress).transfer(_to, _tokenBalance);
            managers.deleteTopic(_title);
        }
    }

    function withdrawOthers(address _tokenAddress, address _to) external onlyManager {
        require(_tokenAddress != address(soulsToken), "Not allowed to withdraw SOULS");
        require(_to != address(0), "Zero address");
        uint256 _tokenBalance = IERC20(_tokenAddress).balanceOf(address(this));
        require(_tokenBalance > 0, "Token balance is zero");
        string memory _title = "Withdraw Tokens";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_tokenAddress, _to));
        managers.approveTopic(_title, _valueInBytes);

        if (managers.isApproved(_title, _valueInBytes)) {
            IERC20(dexPairAddress).transfer(_to, _tokenBalance);
            managers.deleteTopic(_title);
        }
    }

    function addToTrustedSources(address _address, string calldata _name) external onlyOwner {
        managers.addAddressToTrustedSources(_address, _name);
    }

    //TODO: Below lines for test purpose and will be deleted for production.

    bool public approveTopicTestVariable;

    function testApproveTopicFunction(address _testAddress) external {
        require(managers.isManager(msg.sender), "Not authorized");
        string memory _title = "Test Approve Topic Function";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_testAddress));
        managers.approveTopic(_title, _valueInBytes);

        if (managers.isApproved(_title, _valueInBytes)) {
            approveTopicTestVariable = true;
            managers.deleteTopic(_title);
        }
    }

    function transferSoulsToAddress(address _receiver, uint256 _amount) external onlyOwner {
        soulsToken.transfer(_receiver, _amount);
    }
}

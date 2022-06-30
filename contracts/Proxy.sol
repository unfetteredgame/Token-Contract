// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IVault.sol";
import "../interfaces/ILiquidityVault.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/ICrowdFunding.sol";
import "./Managers.sol";
import "./SoulsToken.sol";

import "hardhat/console.sol";

contract Proxy is Ownable {
    SoulsToken public soulsToken;
    Managers public managers;

    //Tokenomi
    uint256 public marketingShare = 300_000_000 ether;
    uint256 public exchangesShare = 150_000_000 ether;
    uint256 public liquidityShare = 60_000_000 ether; //Includes CEX and DEX
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

    //Managers Function
    function transferTokensToCrowdFundingContract(address _contractAddress, uint256 _totalAmount) external onlyManager {
        require(_contractAddress != address(0), "Zero address");
        require(_totalAmount > 0, "Zero amount");
        require(ICrowdFunding(_contractAddress).isCrowdFunding(), "Not crowdfunding contract");

        string memory _title = "Transfer Tokens To Crowd Funding Contract";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_contractAddress, _totalAmount));
        managers.approveTopic(_title, _valueInBytes);
        if (managers.isApproved(_title, _valueInBytes)) {
            _transferSoulsToAddress(_contractAddress, _totalAmount);
            managers.deleteTopic(_title);
        }
    }

    function _transferSoulsToAddress(address _receiver, uint256 _amount) internal {
        soulsToken.transfer(_receiver, _amount);
    }

    //Managers Function
    function initPlayToEarnVault(address _playToEarnVaultAddress, uint256 _gameStartTime) external onlyManager {
        require(playToEarnVaultAddress == address(0), "Already Inited");
        require(_playToEarnVaultAddress != address(0), "Zero address");
        require(_gameStartTime > block.timestamp, "Game start time is in the past");

        string memory _title = "Init Play To Earn Vault";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_gameStartTime));
        managers.approveTopic(_title, _valueInBytes);
        if (managers.isApproved(_title, _valueInBytes)) {
            playToEarnVaultAddress = _playToEarnVaultAddress;
            _initPlayToEarnVault(_gameStartTime);
            managers.deleteTopic(_title);
        }
    }

    function initStakingContract(address _stakingAddress) external onlyOwner {
        require(stakingAddress == address(0), "Already Inited");
        require(_stakingAddress != address(0), "Zero address");
        stakingAddress = _stakingAddress;

        IStaking _staking = IStaking(stakingAddress);
        require(soulsToken.transfer(address(_staking), stakingShare));
        managers.addAddressToTrustedSources(stakingAddress, "Staking");
    }

    function initLiquidityVault(address _liquidityVaultAddress, address _BUSDTokenAddress) external onlyOwner {
        require(liquidityVaultAddress == address(0), "Already Inited");
        liquidityVaultAddress = _liquidityVaultAddress;

        ILiquidityVault _liquidityVault = ILiquidityVault(liquidityVaultAddress);

        IERC20 BUSDToken = IERC20(_BUSDTokenAddress);
        BUSDToken.approve(liquidityVaultAddress, type(uint256).max); //addLiquidityOnDex function on LiquidityVault contract requires allowance
        BUSDToken.transferFrom(msg.sender, liquidityVaultAddress, _liquidityVault.getBUSDAmountForInitialLiquidity());
		
		console.log("testtt %s %s", _BUSDTokenAddress, BUSDToken.balanceOf( liquidityVaultAddress));

		soulsToken.approve(liquidityVaultAddress, liquidityShare);
        _liquidityVault.lockTokens(liquidityShare, 0, 1, 0);

        //Set pair address on token contract for bot protection.
        dexPairAddress = _liquidityVault.getDEXPairAddress();
        soulsToken.setDexPairAddress(dexPairAddress);

        managers.addAddressToTrustedSources(liquidityVaultAddress, "Liquidity Vault");
    }

    function initMarketingVault(address _marketingVaultAddress) external onlyOwner {
        require(marketingVaultAddress == address(0), "Already Inited");
        require(_marketingVaultAddress != address(0), "Zero address");
        marketingVaultAddress = _marketingVaultAddress;

        IVault _marketingVault = IVault(marketingVaultAddress);
        soulsToken.approve(marketingVaultAddress, marketingShare);
        _marketingVault.lockTokens(marketingShare, 90, 24, 30);
        managers.addAddressToTrustedSources(marketingVaultAddress, "Marketing Vault");
    }

    function initAdvisorVault(address _advisorVaultAddress) external onlyOwner {
        require(advisorVaultAddress == address(0), "Already Inited");
        require(_advisorVaultAddress != address(0), "Zero address");
        advisorVaultAddress = _advisorVaultAddress;

        IVault _advisorVault = IVault(advisorVaultAddress);
        soulsToken.approve(advisorVaultAddress, advisorShare);
        _advisorVault.lockTokens(advisorShare, 365, 24, 30);
        managers.addAddressToTrustedSources(advisorVaultAddress, "Advisor Vault");
    }

    function initAirdropVault(address _airdropVaultAddress) external onlyOwner {
        require(airdropVaultAddress == address(0), "Already Inited");
        require(_airdropVaultAddress != address(0), "Zero address");
        airdropVaultAddress = _airdropVaultAddress;
        IVault _airdropVault = IVault(airdropVaultAddress);
        soulsToken.approve(airdropVaultAddress, airdropShare);
        _airdropVault.lockTokens(airdropShare, 240, 12, 30);
        managers.addAddressToTrustedSources(airdropVaultAddress, "Airdrop Vault");
    }

    function initTeamVault(address _teamVaultAddress) external onlyOwner {
        require(teamVaultAddress == address(0), "Already Inited");
        require(_teamVaultAddress != address(0), "Zero address");
        teamVaultAddress = _teamVaultAddress;
        IVault _teamVault = IVault(teamVaultAddress);
        soulsToken.approve(teamVaultAddress, teamShare);
        _teamVault.lockTokens(teamShare, 365, 12, 30);
        managers.addAddressToTrustedSources(teamVaultAddress, "Team Vault");
    }

    function initExchangesVault(address _exchangesVaultAddress) external onlyOwner {
        require(exchangesVaultAddress == address(0), "Already Inited");
        require(_exchangesVaultAddress != address(0), "Zero address");
        exchangesVaultAddress = _exchangesVaultAddress;
        IVault _exchnagesVault = IVault(exchangesVaultAddress);
        soulsToken.approve(exchangesVaultAddress, exchangesShare);
        _exchnagesVault.lockTokens(exchangesShare, 90, 24, 30);
        managers.addAddressToTrustedSources(exchangesVaultAddress, "Exchanges Vault");
    }

    function initTresuaryVault(address _treasuryVaultAddress) external onlyOwner {
        require(treasuryVaultAddress == address(0), "Already Inited");
        require(_treasuryVaultAddress != address(0), "Zero address");
        treasuryVaultAddress = _treasuryVaultAddress;
        IVault _tresuaryVault = IVault(treasuryVaultAddress);
        soulsToken.approve(treasuryVaultAddress, treasuryShare);
        _tresuaryVault.lockTokens(treasuryShare, 90, 36, 30); 
        managers.addAddressToTrustedSources(treasuryVaultAddress, "Treasury Vault");
    }

    function _initPlayToEarnVault(uint256 _gameStartTime) internal {
        IVault _playToEarnVault = IVault(playToEarnVaultAddress);
        soulsToken.approve(playToEarnVaultAddress, playToEarnShare);
        _playToEarnVault.lockTokens(playToEarnShare, 60, 84, 30);
        managers.addAddressToTrustedSources(playToEarnVaultAddress, "PlayToEarn Vault");
    }

    function approveTokensToCrowdFundingContract(address _crowdFundingContractAddress) external onlyOwner {
        require(_crowdFundingContractAddress != address(0), "Zero address");
        soulsToken.approve(_crowdFundingContractAddress, type(uint256).max);
    }

    function withdrawLPTokens(address _to) external onlyManager {
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

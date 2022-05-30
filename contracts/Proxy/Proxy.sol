// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IVestingVaultBase.sol";
import "../../interfaces/ILiquidityVault.sol";

import "../Managers/Managers.sol";
import "../SoulsToken/Souls.sol";

// import "../Staking/Staking.sol";

contract Proxy is Ownable {
    Souls public soulsToken;
    Managers public managers;

    //TODO: Chage rates;

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

    uint8 emergencyExitPenaltyRate = 1;
    uint16 stakePercentagePer1Month = 1;
    uint16 stakePercentagePer3Month = 1;
    uint16 stakePercentagePer6Month = 1;
    uint16 stakePercentagePer12Month = 1;

    address marketingVaultAddress;
    address teamVaultAddress;
    address advisorVaultAddress;
    address airdropVaultAddress;
    address exchangesVaultAddress;
    address liquidityVaultAddress;
    address playToEarnVaultAddress;
    address treasuryVaultAddress;

    constructor(
        address _manager1,
        address _manager2,
        address _manager3,
        address _manager4,
        address _manager5
    ) {
        managers = new Managers(_manager1, _manager2, _manager3, _manager4, _manager5);
        soulsToken = new Souls("SOULS", "Souls Token", address(managers));
    }

    function setProxyAddressOnTokenContract(address _address) external onlyOwner {
        soulsToken.setProxyAddress(_address);
    }

    function setVaultAddresses(
        address _marketingVaultAddress,
        address _teamVaultAddress,
        address _advisorVaultAddress,
        address _airdropVaultAddress,
        address _exchangesVaultAddress,
        address _liquidityVaultAddress,
        address _playToEarnVaultAddress,
        address _treasuryVaultAddress
    ) external onlyOwner {
        marketingVaultAddress = _marketingVaultAddress;
        teamVaultAddress = _teamVaultAddress;
        advisorVaultAddress = _advisorVaultAddress;
        airdropVaultAddress = _airdropVaultAddress;
        exchangesVaultAddress = _exchangesVaultAddress;
        liquidityVaultAddress = _liquidityVaultAddress;
        playToEarnVaultAddress = _playToEarnVaultAddress;
        treasuryVaultAddress = _treasuryVaultAddress;
    }

    function initVaults(
        address _dexFactoryAddress,
        address _dexRouterAddress,
        address _BUSDTokenAddress
    ) external onlyOwner {
        // _initStakingContract(); //FIXME: Contract is too large. deploy externally
        _initLiquidityVault(_dexFactoryAddress, _dexRouterAddress, _BUSDTokenAddress);
        _initMarketingVault();
        _initAdvisorVault();
        _initAirdropVault();
        _initTeamVault();
        _initExchangesVault();
        _initTresuaryVault();
    }

    //Managers Function
    function initPlayToEarnVault(uint256 _gameStartTime) external {
        require(playToEarnVaultAddress == address(0), "Already Inited");
        require(managers.isManager(msg.sender), "Not authorized");
        string memory _title = "Init Play To Earn Vault";
        bytes32 _valueInBytes = keccak256(abi.encodePacked(_gameStartTime));
        managers.approveTopic(_title, _valueInBytes);
        if (managers.isApproved(_title, _valueInBytes)) {
            _initPlayToEarnVault(_gameStartTime);
        }
    }

    // function _initStakingContract() internal {
    //     Staking _staking = new Staking(
    //         address(soulsToken),
    //         address(managers),
    //         emergencyExitPenaltyRate,
    //         stakePercentagePer1Month,
    //         stakePercentagePer3Month,
    //         stakePercentagePer6Month,
    //         stakePercentagePer12Month
    //     );
    //     require(soulsToken.transfer(address(_staking), stakingShare));
    //     managers.addAddressToTrustedSources(address(_staking));
    // }

    function _initLiquidityVault(
        address _dexFactoryAddress,
        address _dexRouterAddress,
        address _BUSDTokenAddress
    ) internal {
        ILiquidityVault _liquidityVault = ILiquidityVault(liquidityVaultAddress);

        // new LiquidityVault(
        //     address(soulsToken),
        //     address(managers),
        //     _dexFactoryAddress,
        //     _dexRouterAddress,
        //     _BUSDTokenAddress
        // );
        soulsToken.approve(liquidityVaultAddress, liquidityShare);
        _liquidityVault.lockTokens(liquidityShare);

        //Set pair address on token contract for bot protection.
        soulsToken.setDexPairAddress(_liquidityVault.getDEXPairAddress());
        managers.addAddressToTrustedSources(liquidityVaultAddress);
    }

    function _initMarketingVault() internal {
        IVestingVaultBase _marketingVault = IVestingVaultBase(marketingVaultAddress);
        soulsToken.approve(marketingVaultAddress, marketingShare);
        _marketingVault.lockTokens(marketingShare, 90, 30, 24);
        managers.addAddressToTrustedSources(marketingVaultAddress);
    }

    function _initAdvisorVault() internal {
        IVestingVaultBase _advisorVault = IVestingVaultBase(advisorVaultAddress);
        soulsToken.approve(advisorVaultAddress, advisorShare);
        _advisorVault.lockTokens(advisorShare, 365, 30, 24);
        managers.addAddressToTrustedSources(advisorVaultAddress);
    }

    function _initAirdropVault() internal {
        IVestingVaultBase _airdropVault = IVestingVaultBase(airdropVaultAddress);
        soulsToken.approve(airdropVaultAddress, airdropShare);
        _airdropVault.lockTokens(airdropShare, 240, 30, 12);
        managers.addAddressToTrustedSources(airdropVaultAddress);
    }

    function _initTeamVault() internal {
        IVestingVaultBase _teamVault = IVestingVaultBase(teamVaultAddress);
        soulsToken.approve(teamVaultAddress, teamShare);
        _teamVault.lockTokens(teamShare, 365, 30, 24);
        managers.addAddressToTrustedSources(teamVaultAddress);
    }

    function _initExchangesVault() internal {
        IVestingVaultBase _exchnagesVault = IVestingVaultBase(exchangesVaultAddress);
        soulsToken.approve(exchangesVaultAddress, exchangesShare);
        _exchnagesVault.lockTokens(exchangesShare, 90, 30, 24);
        managers.addAddressToTrustedSources(exchangesVaultAddress);
    }

    function _initTresuaryVault() internal {
        IVestingVaultBase _tresuaryVault = IVestingVaultBase(treasuryVaultAddress);
        soulsToken.approve(treasuryVaultAddress, treasuryShare);
        _tresuaryVault.lockTokens(treasuryShare, 90, 1, 1); //FIXME: Learn vesting for treasury
        managers.addAddressToTrustedSources(treasuryVaultAddress);
    }

    function _initPlayToEarnVault(uint256 _gameStartTime) internal {
        IVestingVaultBase _playToEarnVault = IVestingVaultBase(playToEarnVaultAddress);
        soulsToken.approve(playToEarnVaultAddress, playToEarnShare);
        _playToEarnVault.lockTokens(playToEarnShare, 60, 30, 84);
        managers.addAddressToTrustedSources(playToEarnVaultAddress);
    }

    function testAddTrustedSources(address _address) external onlyOwner {
        managers.addAddressToTrustedSources(_address);
    }

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
}

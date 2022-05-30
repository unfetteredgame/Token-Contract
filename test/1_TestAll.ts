import { ethers, waffle } from 'hardhat';
import chai from 'chai';

import ProxyArtifact from '../artifacts/contracts/Proxy/Proxy.sol/Proxy.json';
import ManagersArtifact from '../artifacts/contracts/Managers/Managers.sol/Managers.json';
import SoulsArtifact from '../artifacts/contracts/SoulsToken/Souls.sol/Souls.json';
import StakingArtifact from '../artifacts/contracts/Staking/Staking.sol/Staking.json';
import AdvisorVaultArtifact from '../artifacts/contracts/Vaults/AdvisorVault.sol/AdvisorVault.json';
import AirdropVaultArtifact from '../artifacts/contracts/Vaults/AirdropVault.sol/AirdropVault.json';
import ExchangesVaultArtifact from '../artifacts/contracts/Vaults/ExchangesVault.sol/ExchangesVault.json';
import LiquidityVaultArtifact from '../artifacts/contracts/Vaults/LiquidityVault.sol/LiquidityVault.json';
import MarketingVaultArtifact from '../artifacts/contracts/Vaults/MarketingVault.sol/MarketingVault.json';
import PlayToEarnVaultArtifact from '../artifacts/contracts/Vaults/PlayToEarnVault.sol/PlayToEarnVault.json';
import TeamVaultArtifact from '../artifacts/contracts/Vaults/TeamVault.sol/TeamVault.json';
import TreasuryVaultArtifact from '../artifacts/contracts/Vaults/TreasuryVault.sol/TreasuryVault.json';


import { Proxy } from '../typechain/Proxy';
import { Managers } from '../typechain/Managers';
import { Souls } from '../typechain/Souls';
import { Staking } from '../typechain/Staking';
import { AdvisorVault } from '../typechain/AdvisorVault';
import { AirdropVault } from '../typechain/AirdropVault';
import { ExchangesVault } from '../typechain/ExchangesVault';
import { LiquidityVault } from '../typechain/LiquidityVault';
import { MarketingVault } from '../typechain/MarketingVault';
import { PlayToEarnVault } from '../typechain/PlayToEarnVault';
import { TeamVault } from '../typechain/TeamVault';
import { TreasuryVault } from '../typechain/TreasuryVault';


import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

const { deployContract } = waffle;
const { expect } = chai;


const _dexFactoryAddress = "0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc";
const _dexRouterAddress = "0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7";
const _BUSDTokenAddress = "0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7"
const _GameLaunchTime = new Date("2022-12-12").getTime() / 1000 //TODO: SET CORRECT VAULE FOR GAME LAUNCH TIME



describe('TokenProxy Contract', () => {
	let owner: SignerWithAddress;
	let manager1: SignerWithAddress;
	let manager2: SignerWithAddress;
	let manager3: SignerWithAddress;
	let manager4: SignerWithAddress;
	let manager5: SignerWithAddress;
	let addrs: SignerWithAddress[];

	let marketingVault: MarketingVault
	let teamVault: TeamVault
	let advisorVault: AdvisorVault
	let airdropVault: AirdropVault
	let exchangesVault: ExchangesVault
	let liquidityVault: LiquidityVault
	let playToEarnVault: PlayToEarnVault
	let treasuryVault: TreasuryVault

	let managers: Managers
	let proxy: Proxy;
	let soulsToken: Souls;
	let staking: Staking

	beforeEach(async () => {
		[owner, manager1, manager2, manager3, manager4, manager5, ...addrs] = await ethers.getSigners();

		proxy = (await deployContract(owner, ProxyArtifact, [manager1.address, manager2.address, manager3.address, manager4.address, manager5.address])) as Proxy;
		soulsToken = new ethers.Contract(await proxy.soulsToken(), SoulsArtifact.abi) as Souls
		managers = new ethers.Contract(await proxy.managers(), ManagersArtifact.abi) as Managers

		marketingVault = (await deployContract(owner, MarketingVaultArtifact, [soulsToken.address, managers.address, proxy.address])) as MarketingVault;
		teamVault = (await deployContract(owner, TeamVaultArtifact, [soulsToken.address, managers.address, proxy.address])) as TeamVault;
		advisorVault = (await deployContract(owner, AdvisorVaultArtifact, [soulsToken.address, managers.address, proxy.address])) as AdvisorVault;
		airdropVault = (await deployContract(owner, AirdropVaultArtifact, [soulsToken.address, managers.address, proxy.address])) as AirdropVault;
		exchangesVault = (await deployContract(owner, ExchangesVaultArtifact, [soulsToken.address, managers.address, proxy.address])) as ExchangesVault;
		treasuryVault = (await deployContract(owner, TreasuryVaultArtifact, [soulsToken.address, managers.address, proxy.address])) as TreasuryVault;

		liquidityVault = (await deployContract(owner, LiquidityVaultArtifact, [soulsToken.address, managers.address, proxy.address, _dexFactoryAddress, _dexRouterAddress, _BUSDTokenAddress])) as LiquidityVault;
		playToEarnVault = (await deployContract(owner, PlayToEarnVaultArtifact, [soulsToken.address, managers.address, proxy.address, _GameLaunchTime])) as PlayToEarnVault;
		//console.log("souls token address", soulsToken.address);

	});

	describe('Test initialization', () => {
		it("check contract deployments", async () => {
			
		});
	});
});

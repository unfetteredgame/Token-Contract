import { ethers, waffle } from 'hardhat';
import chai from 'chai';

import ProxyArtifact from '../artifacts/contracts/Proxy.sol/Proxy.json';
import ManagersArtifact from '../artifacts/contracts/Managers.sol/Managers.json';
import SoulsArtifact from '../artifacts/contracts/SoulsToken.sol/SoulsToken.json';
import StakingArtifact from '../artifacts/contracts/Staking.sol/Staking.json';
import VaultArtifact from '../artifacts/contracts/Vault.sol/Vault.json';
import LiquidityVaultArtifact from '../artifacts/contracts/LiquidityVault.sol/LiquidityVault.json';
import CrowdFundingArtifact from '../artifacts/contracts/CrowdFunding.sol/CrowdFunding.json';
import BUSDTokenArtifact from '../artifacts/contracts/BUSDToken.sol/BUSDToken.json';
import IPancakeRouterArtifact from '../artifacts/interfaces/IPancakeRouter02.sol/IPancakeRouter02.json'




import { Proxy } from '../typechain/Proxy';
import { Managers } from '../typechain/Managers';
import { SoulsToken } from '../typechain/SoulsToken';
import { Staking } from '../typechain/Staking';
import { Vault } from '../typechain/Vault';
import { LiquidityVault } from '../typechain/LiquidityVault';
import { CrowdFunding } from '../typechain/CrowdFunding';
import { BUSDToken } from '../typechain/BUSDToken'



import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { IPancakeRouter02 } from '../typechain/IPancakeRouter02';

const { deployContract } = waffle;
const { expect } = chai;




const simulateTimeInSeconds = async (duration: number) => {
	const blockNumBefore = await ethers.provider.getBlockNumber();
	const blockBefore = await ethers.provider.getBlock(blockNumBefore);

	await ethers.provider.send('evm_increaseTime', [duration]);
	await ethers.provider.send('evm_mine', []);
};

const gotoTime = async (time: number) => {
	const now = (await ethers.provider.getBlock("latest")).timestamp
	await simulateTimeInSeconds(time - now)
}


const _dexFactoryAddress = "0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc";
const _dexRouterAddress = "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3";
let _BUSDTokenAddress = ""
let _GameLaunchTime = new Date("2023-12-12").getTime() / 1000 //TODO: SET CORRECT VAULE FOR GAME LAUNCH TIME
const stakingAPYFor1Month = 5
const stakingAPYFor3Month = 10
const stakingAPYFor6Month = 15
const stakingAPYFor12Month = 20


describe('TokenProxy Contract', () => {
	return
	let busdToken
	let owner: SignerWithAddress;
	let manager1: SignerWithAddress;
	let manager2: SignerWithAddress;
	let manager3: SignerWithAddress;
	let manager4: SignerWithAddress;
	let manager5: SignerWithAddress;
	let addrs: SignerWithAddress[];

	let liquidityVault: LiquidityVault

	let marketingVault: Vault
	let teamVault: Vault
	let advisorVault: Vault
	let airdropVault: Vault
	let exchangesVault: Vault
	let playToEarnVault: Vault
	let treasuryVault: Vault

	let privateSaleFunding: CrowdFunding;
	let strategicSaleFunding: CrowdFunding;
	let seedSaleFunding: CrowdFunding;
	let publicSaleFunding: CrowdFunding;
	let airdropFunding: CrowdFunding;

	let managers: Managers
	let proxy: Proxy;
	let soulsToken: SoulsToken;
	let staking: Staking
	let router: IPancakeRouter02 = new ethers.Contract(_dexRouterAddress, IPancakeRouterArtifact.abi) as IPancakeRouter02


	beforeEach(async () => {
		[owner, manager1, manager2, manager3, manager4, manager5, ...addrs] = await ethers.getSigners();
	});


	describe('\n\n#########################################\n deploy contracts \n#########################################', () => {
		it("Deploys All Contracts", async () => {
			busdToken = await deployContract(owner, BUSDTokenArtifact) as BUSDToken
			_BUSDTokenAddress = busdToken.address

			console.log("Deploy Crowdfunding Contracts")
			privateSaleFunding = (await deployContract(owner, CrowdFundingArtifact, ["Private Sale", soulsToken.address, managers.address])) as CrowdFunding;
			seedSaleFunding = (await deployContract(owner, CrowdFundingArtifact, ["Seed Sale", soulsToken.address, managers.address])) as CrowdFunding;
			strategicSaleFunding = (await deployContract(owner, CrowdFundingArtifact, ["Strategic Sale", soulsToken.address, managers.address])) as CrowdFunding;
			publicSaleFunding = (await deployContract(owner, CrowdFundingArtifact, ["Public Sale", soulsToken.address, managers.address])) as CrowdFunding;
			airdropFunding = (await deployContract(owner, CrowdFundingArtifact, ["Airdrop", soulsToken.address, managers.address])) as CrowdFunding;


			console.log("Deploy Proxy Contract")
			proxy = (await deployContract(owner, ProxyArtifact, [manager1.address, manager2.address, manager3.address, manager4.address, manager5.address])) as Proxy;
			soulsToken = new ethers.Contract(await proxy.soulsToken(), SoulsArtifact.abi) as SoulsToken
			managers = new ethers.Contract(await proxy.managers(), ManagersArtifact.abi) as Managers

			console.log("Deploy Staking Contract")
			staking = (await deployContract(owner, StakingArtifact, [soulsToken.address, managers.address, ethers.utils.parseEther(stakingAPYFor1Month.toString()), ethers.utils.parseEther(stakingAPYFor3Month.toString()), ethers.utils.parseEther(stakingAPYFor6Month.toString()), ethers.utils.parseEther(stakingAPYFor12Month.toString())])) as Staking;

			console.log("Deploy Vault Contracts")
			marketingVault = (await deployContract(owner, VaultArtifact, ["Marketing Vault", proxy.address, soulsToken.address, managers.address])) as Vault;
			teamVault = (await deployContract(owner, VaultArtifact, ["Team Vault", proxy.address, soulsToken.address, managers.address])) as Vault;
			advisorVault = (await deployContract(owner, VaultArtifact, ["Advisor Vault", proxy.address, soulsToken.address, managers.address])) as Vault;
			treasuryVault = (await deployContract(owner, VaultArtifact, ["Treasury Vault", proxy.address, soulsToken.address, managers.address])) as Vault;
			exchangesVault = (await deployContract(owner, VaultArtifact, ["Exchanges Vault", proxy.address, soulsToken.address, managers.address])) as Vault;
			playToEarnVault = (await deployContract(owner, VaultArtifact, ["Play To Earn Vault", proxy.address, soulsToken.address, managers.address])) as Vault;
			airdropVault = (await deployContract(owner, VaultArtifact, ["Airdrop Vault", proxy.address, soulsToken.address, managers.address])) as Vault;
			liquidityVault = (await deployContract(owner, LiquidityVaultArtifact, ["Liquidity Vault", proxy.address, soulsToken.address, managers.address, _dexFactoryAddress, _dexRouterAddress, _BUSDTokenAddress])) as LiquidityVault;

	

			console.log("Set Vault Addresses in Proxy Contract")

			console.log("Init staking contract")

			await proxy.initStakingContract(staking.address)

			enum VaultEnumerator {
				MARKETING,
				ADVISOR,
				AIRDROP,
				TEAM,
				EXCHANGES,
				TREASURY
			}

			console.log("Init marketing Vault")
			await proxy.initVault(marketingVault.address, VaultEnumerator.MARKETING)

			console.log("Init Advisor Vault")
			await proxy.initVault(advisorVault.address, VaultEnumerator.ADVISOR)

			console.log("Init Airdrop Vault")
			await proxy.initVault(airdropVault.address, VaultEnumerator.AIRDROP)

			console.log("Init Team Vault")
			await proxy.initVault(teamVault.address, VaultEnumerator.TEAM)

			console.log("Init Exchanges Vault")
			await proxy.initVault(exchangesVault.address, VaultEnumerator.EXCHANGES)

			console.log("Init Treasury Vault")
			await proxy.initVault(treasuryVault.address, VaultEnumerator.TREASURY)

			console.log("Init PlayToEarn Vault")
			_GameLaunchTime   = await (await ethers.provider.getBlock("latest")).timestamp + 1000
			await proxy.connect(manager1).initPlayToEarnVault(playToEarnVault.address, _GameLaunchTime)
			await proxy.connect(manager2).initPlayToEarnVault(playToEarnVault.address, _GameLaunchTime)
			await proxy.connect(manager3).initPlayToEarnVault(playToEarnVault.address, _GameLaunchTime)
			
			await busdToken.connect(owner).approve(proxy.address, ethers.constants.MaxUint256);

			console.log("Init liquidity vault")
			await proxy.initLiquidityVault(liquidityVault.address, _BUSDTokenAddress)

			console.log("DEX pair address: ", await soulsToken.connect(owner).dexPairAddress())
		});
	});

});

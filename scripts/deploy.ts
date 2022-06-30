// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from 'hardhat';
import ManagersArtifact from '../artifacts/contracts/Managers.sol/Managers.json';
import SoulsArtifact from '../artifacts/contracts/SoulsToken.sol/SoulsToken.json';


import { Proxy as ProxyType } from '../typechain/Proxy';
import { Managers as ManagersType } from '../typechain/Managers';
import { SoulsToken as SoulsTokenType } from '../typechain/SoulsToken';
import { Staking as StakingType } from '../typechain/Staking';
import { Vault as VaultType } from '../typechain/Vault';
import { LiquidityVault as LiquidityVaultType } from '../typechain/LiquidityVault';
import { BUSDToken as BUSDTokenType } from '../typechain/BUSDToken'

import hre from "hardhat"

async function main() {

	// Hardhat always runs the compile task when running scripts with its command
	// line interface.
	//
	// If this script is run directly using `node` you may want to call compile
	// manually to make sure everything is compiled
	// await hre.run('compile');

	// We get the contract to deploy
	const manager1 = "0xeF23bEBBDb9D211494E1F8d7ee8D511d05D28765"
	const manager2 = "0x46f2E5F4a603a44ffd54B187c12d36C4E9D73c16"
	const manager3 = "0x7bf9A780DE60bF3F91Fc8Dd95B3dF21b94C16a30"
	const manager4 = "0xEf4b9084CC90412b1f4f528f88784eC2b60FF2Cf"
	const manager5 = "0x4634302fCE259c5E89C4eCbBEEE4eDe7bE4622b4"


	let _dexFactoryAddress = ""
	let _dexRouterAddress = ""
	let _BUSDTokenAddress = ""

	const BusdToken = await ethers.getContractFactory('BUSDToken');
	const busdToken = await BusdToken.deploy() as BUSDTokenType;
	await busdToken.deployed()

	switch (hre.network.name) {
		case 'localhost':
			_dexFactoryAddress = "0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc";
			_dexRouterAddress = "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3";
			_BUSDTokenAddress = busdToken.address
			break
		case 'rinkeby':
			_dexFactoryAddress = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"; //uniswap
			_dexRouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"; //uniswap
			_BUSDTokenAddress = busdToken.address
			break;
		case 'bsctestnet':
			_dexFactoryAddress = "0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc"; //pancakeswap
			_dexRouterAddress = "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3"; //pancakeswap
			_BUSDTokenAddress = busdToken.address
			break;
		case 'bsc':
			_dexFactoryAddress = "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73";
			_dexRouterAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E";
			_BUSDTokenAddress = busdToken.address;
			break;
	}




	const _GameLaunchTime = new Date("2022-12-12").getTime() / 1000 //TODO: SET CORRECT VAULE FOR GAME LAUNCH TIME

	//TODO: Chage rates;
	const stakingAPYFor1Month = 5
	const stakingAPYFor3Month = 10
	const stakingAPYFor6Month = 15
	const stakingAPYFor12Month = 20



	const Proxy = await ethers.getContractFactory('Proxy');
	const Staking = await ethers.getContractFactory('Staking');
	const CrowdFunding = await ethers.getContractFactory('CrowdFunding');
	const Vault = await ethers.getContractFactory('Vault');
	const LiquidityVault = await ethers.getContractFactory('LiquidityVault');



	const proxy = await Proxy.deploy(manager1, manager2, manager3, manager4, manager5) as ProxyType;
	(await proxy.deployed());
	console.log("Proxy contract deployed to", proxy.address)

	const soulsTokenAddress = await proxy.soulsToken();
	const managersAddress = await proxy.managers();
	console.log("Souls token deployed by proxy to:", soulsTokenAddress)
	console.log("Managers deployed by proxy to:", managersAddress)
	const soulsToken = new ethers.Contract(soulsTokenAddress, SoulsArtifact.abi, ethers.provider.getSigner()) as SoulsTokenType;
	const managers = new ethers.Contract(managersAddress, ManagersArtifact.abi) as ManagersType;

	const staking = await Staking.deploy(soulsToken.address, managers.address, ethers.utils.parseEther(stakingAPYFor1Month.toString()), ethers.utils.parseEther(stakingAPYFor3Month.toString()), ethers.utils.parseEther(stakingAPYFor6Month.toString()), ethers.utils.parseEther(stakingAPYFor12Month.toString())) as StakingType;
	await staking.deployed();
	console.log("Staking deployed to:", staking.address);

	const liquidityVault = await LiquidityVault.deploy("Liquidity Vault", proxy.address, soulsToken.address, managers.address, _dexFactoryAddress, _dexRouterAddress, _BUSDTokenAddress) as LiquidityVaultType
	const marketingVault = await Vault.deploy("Marketing Vault", proxy.address, soulsToken.address, managers.address) as VaultType
	const teamVault = await Vault.deploy("Team Vault", proxy.address, soulsToken.address, managers.address) as VaultType
	const advisorVault = await Vault.deploy("Advisor Vault", proxy.address, soulsToken.address, managers.address) as VaultType
	const treasuryVault = await Vault.deploy("Treasury Vault", proxy.address, soulsToken.address, managers.address) as VaultType
	const exchangesVault = await Vault.deploy("Exchanges Vault", proxy.address, soulsToken.address, managers.address) as VaultType
	const playToEarnVault = await Vault.deploy("PlayToEarn Vault", proxy.address, soulsToken.address, managers.address) as VaultType
	const airdropVault = await Vault.deploy("Airdrop Vault", proxy.address, soulsToken.address, managers.address) as VaultType


	await liquidityVault.deployed();
	console.log("Liquidity Vault deployed to:", liquidityVault.address);
	await marketingVault.deployed();
	console.log("Marketing Vault deployed to:", marketingVault.address);
	await teamVault.deployed();
	console.log("Team Vault deployed to:", teamVault.address);
	await advisorVault.deployed();
	console.log("Advisor Vault deployed to:", advisorVault.address);
	await treasuryVault.deployed();
	console.log("Treasury Vault deployed to:", treasuryVault.address);
	await exchangesVault.deployed();
	console.log("Exchanges Vault deployed to:", exchangesVault.address);
	await playToEarnVault.deployed();
	console.log("PlayToEarn Vault deployed to:", playToEarnVault.address);
	await airdropVault.deployed();
	console.log("Airdrop Vault deployed to:", airdropVault.address);

	console.log("Giving allowance of BUSD tokens for proxy contract")
	console.log("BUSD token address:", _BUSDTokenAddress);

	//const busdToken = new ethers.Contract(_BUSDTokenAddress, IERC20Artifact.abi, ethers.provider.getSigner())
	console.log("BUSD token balance:", await busdToken.balanceOf(await ethers.provider.getSigner().getAddress()));
	console.log("Required BUSD amount", await liquidityVault.getBUSDAmountForInitialLiquidity())
	const tx = await busdToken.approve(proxy.address, ethers.constants.MaxUint256);
	await tx.wait()
	console.log("Allowance for proxy contract: ", await busdToken.allowance(await ethers.provider.getSigner().getAddress(), proxy.address))
	console.log("Setting vault addresses on proxy contract")


	console.log("Vaults are getting initialized by proxy contract")
	// const gasEstimation = await proxy.estimateGas.initVaults(_dexFactoryAddress, _dexRouterAddress, _BUSDTokenAddress)
	// console.log("gas estimation", gasEstimation);

	console.log("Init staking contract")
	await (await proxy.initStakingContract(staking.address)).wait()

	console.log("Init marketing Vault")
	await (await proxy.initMarketingVault(marketingVault.address)).wait()

	console.log("Init Advisor Vault")
	await proxy.initAdvisorVault(advisorVault.address)

	console.log("Init Airdrop Vault")
	await proxy.initAirdropVault(airdropVault.address)

	console.log("Init Team Vault")
	await proxy.initTeamVault(teamVault.address)

	console.log("Init Exchanges Vault")
	await proxy.initExchangesVault(exchangesVault.address)

	console.log("Init Treasury Vault")
	await proxy.initTresuaryVault(treasuryVault.address)

	console.log("Init liquidity vault")
	// const gasEstimation = await proxy.estimateGas.initLiquidityVault(liquidityVault.address, _dexFactoryAddress, _dexRouterAddress, _BUSDTokenAddress)
	//console.log("Estimated gas: ", gasEstimation.toString())
	await proxy.initLiquidityVault(liquidityVault.address, _BUSDTokenAddress, { gasLimit: 4000000 })

	//total gas required : 41.200.961

	const dexPairAddress = await liquidityVault.DEXPairAddress();
	console.log("DEX pair address:", dexPairAddress)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});

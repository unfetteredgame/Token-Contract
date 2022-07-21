import { ethers, waffle } from 'hardhat';
import chai from 'chai';

import ProxyArtifact from '../artifacts/contracts/Proxy.sol/Proxy.json';
import ManagersArtifact from '../artifacts/contracts/Managers.sol/Managers.json';
import SoulsArtifact from '../artifacts/contracts/SoulsToken.sol/SoulsToken.json';
import VaultArtifact from '../artifacts/contracts/Vault.sol/Vault.json';


import { Proxy } from '../typechain/Proxy';
import { Managers } from '../typechain/Managers';
import { SoulsToken } from '../typechain/SoulsToken';
import { Vault } from '../typechain/Vault';



import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber } from 'ethers';

const { deployContract } = waffle;
const { expect } = chai;


const simulateTimeInSeconds = async (duration: number) => {
	const blockNumBefore = await ethers.provider.getBlockNumber();
	const blockBefore = await ethers.provider.getBlock(blockNumBefore);

	await ethers.provider.send('evm_increaseTime', [duration]);
	await ethers.provider.send('evm_mine', []);
};



const _dexFactoryAddress = "0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc";
const _dexRouterAddress = "0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7";

const _BUSDTokenAddress = "0x8c552cF3F61aBEA86741e9828C1A4Eb31d48590D"

describe('Other Vaults Contract', () => {
	return
	let owner: SignerWithAddress;
	let manager1: SignerWithAddress;
	let manager2: SignerWithAddress;
	let manager3: SignerWithAddress;
	let manager4: SignerWithAddress;
	let manager5: SignerWithAddress;
	let addrs: SignerWithAddress[];


	let managers: Managers
	let proxy: Proxy;
	let souls: SoulsToken;
	let testVault: Vault;

	beforeEach(async () => {
		[owner, manager1, manager2, manager3, manager4, manager5, ...addrs] = await ethers.getSigners();

		proxy = (await deployContract(owner, ProxyArtifact, [manager1.address, manager2.address, manager3.address, manager4.address, manager5.address])) as Proxy;
		managers = new ethers.Contract(await proxy.managers(), ManagersArtifact.abi) as Managers
		souls = new ethers.Contract(await proxy.soulsToken(), SoulsArtifact.abi, owner) as SoulsToken
		testVault = (await deployContract(owner, VaultArtifact, ["Test Vault", proxy.address, souls.address, managers.address])) as Vault;

		await proxy.connect(owner).initVault(testVault.address, 1)

		console.log("")


	});
	describe('\n\n#########################################\n lockTokens function\n#########################################', () => {
		return
		it("Cannot init more than one for each vault", async () => {
			const tx = proxy.connect(owner).initVault(testVault.address, 1);
			await expect(tx).to.be.revertedWith("Already Inited")
		})


		it("Contract token balance must increase with amount of locked tokens", async () => {
			const contractBalance = await souls.balanceOf(testVault.address);
			await expect(contractBalance).to.be.equal(await proxy.advisorShare());
		})

		it("Total of vestings must be equal to locked tokens", async () => {
			const contractBalance = await souls.balanceOf(testVault.address);
			await expect(contractBalance).to.be.equal(await proxy.advisorShare());
			const tokenVestings = await testVault.getVestingData();
			const vestingData = []
			let totalAmount = BigNumber.from(0)
			for (let i = 0; i < tokenVestings.length; i++) {
				vestingData.push({
					amount: ethers.utils.formatEther(tokenVestings[i].amount),
					releaseDate: new Date(tokenVestings[i].unlockTime.toNumber() * 1000).toDateString()
				})
				totalAmount = totalAmount.add(tokenVestings[i].amount)
			}

			console.table(vestingData)
			console.log("Vault share: ", ethers.utils.formatEther(await proxy.advisorShare()))
			console.log("Total amount of vestings: ", ethers.utils.formatEther(totalAmount));
			expect(await proxy.advisorShare()).to.be.equal(totalAmount)
		})

	})

	describe('\n\n#########################################\n withdrawTokens function\n#########################################', () => {
		it("Cannot withdraw before unlock time", async () => {
			await testVault.connect(manager1).withdrawTokens([addrs[0].address], [ethers.utils.parseEther("1")])
			await testVault.connect(manager2).withdrawTokens([addrs[0].address], [ethers.utils.parseEther("1")])
			const tx = testVault.connect(manager3).withdrawTokens([addrs[0].address], [ethers.utils.parseEther("1")])
			await expect(tx).to.be.revertedWith("Wait for vesting release date")
		})

		it("Relases next vesting automatically after unlockTime if released amount is not enough", async () => {
			// const unlockTime = await marketingVault.connect(owner).unlockTime();
			const vestings = await testVault.getVestingData()
			const unlockTime = vestings[0].unlockTime
			await simulateTimeInSeconds(unlockTime.toNumber() - (await ethers.provider.getBlock("latest")).timestamp)
			const amountOfFirstVesting = (await testVault.tokenVestings(0)).amount
			await testVault.connect(manager1).withdrawTokens([addrs[0].address], [amountOfFirstVesting])
			await testVault.connect(manager2).withdrawTokens([addrs[0].address], [amountOfFirstVesting])
			await testVault.connect(manager3).withdrawTokens([addrs[0].address], [amountOfFirstVesting])
			expect(await souls.balanceOf(addrs[0].address)).to.be.equal(amountOfFirstVesting.toString())
		})

		it("Can work many times if there is enough relased amount", async () => {
			const vestings = await testVault.getVestingData()
			const unlockTime = vestings[0].unlockTime
			await simulateTimeInSeconds(unlockTime.toNumber() - (await ethers.provider.getBlock("latest")).timestamp)
			const amountOfFirstVesting = (await testVault.tokenVestings(0)).amount
			let expectedBalance = BigNumber.from(0)
			await testVault.connect(manager1).withdrawTokens([addrs[0].address], [amountOfFirstVesting.div(3)])
			await testVault.connect(manager2).withdrawTokens([addrs[0].address], [amountOfFirstVesting.div(3)])
			await testVault.connect(manager3).withdrawTokens([addrs[0].address], [amountOfFirstVesting.div(3)])
			expect(await souls.balanceOf(addrs[0].address)).to.be.equal(amountOfFirstVesting.div(3).toString())
			expectedBalance = expectedBalance.add(amountOfFirstVesting.div(3))

			await testVault.connect(manager1).withdrawTokens([addrs[0].address], [amountOfFirstVesting.div(3)])
			await testVault.connect(manager2).withdrawTokens([addrs[0].address], [amountOfFirstVesting.div(3)])
			await testVault.connect(manager3).withdrawTokens([addrs[0].address], [amountOfFirstVesting.div(3)])
			expect(await souls.balanceOf(addrs[0].address)).to.be.equal(amountOfFirstVesting.div(3).mul(2).toString())
			expectedBalance = expectedBalance.add(amountOfFirstVesting.div(3))

			await testVault.connect(manager1).withdrawTokens([addrs[0].address], [amountOfFirstVesting.div(3)])
			await testVault.connect(manager2).withdrawTokens([addrs[0].address], [amountOfFirstVesting.div(3)])
			await testVault.connect(manager3).withdrawTokens([addrs[0].address], [amountOfFirstVesting.div(3)])
			expectedBalance = expectedBalance.add(amountOfFirstVesting.div(3))
			expect(await souls.balanceOf(addrs[0].address)).to.be.equal(expectedBalance)

			await testVault.connect(manager1).withdrawTokens([addrs[0].address], [amountOfFirstVesting.div(3)])
			await testVault.connect(manager2).withdrawTokens([addrs[0].address], [amountOfFirstVesting.div(3)])
			const tx = testVault.connect(manager3).withdrawTokens([addrs[0].address], [amountOfFirstVesting.div(3)])
			await expect(tx).to.be.revertedWith("Wait for vesting release date")

			await simulateTimeInSeconds(vestings[1].unlockTime.toNumber() - (await ethers.provider.getBlock("latest")).timestamp)


		})

		it("Can withdraw all vestings when unlocked", async () => {
			const vestingData = await testVault.getVestingData()
			for (let v = 0; v < vestingData.length; v++) {
				console.log("Withdraw vesting: ", v)
				const vesting = vestingData[v];
				await simulateTimeInSeconds(vesting.unlockTime.toNumber() - (await ethers.provider.getBlock("latest")).timestamp)
				const amountOfVesting = vesting.amount
				await testVault.connect(manager1).withdrawTokens([addrs[0].address], [amountOfVesting])
				await testVault.connect(manager2).withdrawTokens([addrs[0].address], [amountOfVesting])
				await testVault.connect(manager3).withdrawTokens([addrs[0].address], [amountOfVesting])
			}
			console.log("Vault contract balance after withdraw all vesting: ", (await souls.balanceOf(testVault.address)).toString())
			expect(await souls.balanceOf(testVault.address)).to.be.equal(0)
			console.log("Available balance to withdraw in vault: ", (await testVault.getAvailableAmountForWithdraw()).toString())
		})

		it("Can withdraw all vestings with parts", async () => {
			const vestingData = await testVault.getVestingData()
			for (let v = 0; v < vestingData.length; v++) {
				const vesting = vestingData[v];
				await simulateTimeInSeconds(vesting.unlockTime.toNumber() - (await ethers.provider.getBlock("latest")).timestamp)
				const amountOfVesting = vesting.amount
				await testVault.connect(manager1).withdrawTokens([addrs[0].address], [amountOfVesting.div(2)])
				await testVault.connect(manager2).withdrawTokens([addrs[0].address], [amountOfVesting.div(2)])
				await testVault.connect(manager3).withdrawTokens([addrs[0].address], [amountOfVesting.div(2)])
				await testVault.connect(manager1).withdrawTokens([addrs[0].address], [amountOfVesting.div(2)])
				await testVault.connect(manager2).withdrawTokens([addrs[0].address], [amountOfVesting.div(2)])
				await testVault.connect(manager3).withdrawTokens([addrs[0].address], [amountOfVesting.div(2)])
			}
			expect(await souls.balanceOf(testVault.address)).to.be.equal(0)

		})


		it("Cannot withdraw more than total of released amount and unlocked vesting amount", async () => {
			const vestings = await testVault.getVestingData()
			const unlockTime = vestings[0].unlockTime
			await simulateTimeInSeconds(unlockTime.toNumber() - (await ethers.provider.getBlock("latest")).timestamp)
			const amountOfFirstVesting = (await testVault.tokenVestings(0)).amount
			await testVault.connect(manager1).withdrawTokens([addrs[0].address], [amountOfFirstVesting.add(1)])
			await testVault.connect(manager2).withdrawTokens([addrs[0].address], [amountOfFirstVesting.add(1)])
			const tx = testVault.connect(manager3).withdrawTokens([addrs[0].address], [amountOfFirstVesting.add(1)])
			await expect(tx).to.be.revertedWith("Not enough amount in released balance")
			//expect(await souls.balanceOf(addrs[0].address)).to.be.equal(ethers.utils.parseEther("1"))
		})

		it("Cannot withdraw more than available released amount after unlocked all vestings", async () => {
			const vestingData = await testVault.getVestingData()
			for (let v = 0; v < vestingData.length; v++) {
				const vesting = vestingData[v];
				await simulateTimeInSeconds(vesting.unlockTime.toNumber() - (await ethers.provider.getBlock("latest")).timestamp)
				const amountOfVesting = vesting.amount
				await testVault.connect(manager1).withdrawTokens([addrs[0].address], [amountOfVesting.div(2)])
				await testVault.connect(manager2).withdrawTokens([addrs[0].address], [amountOfVesting.div(2)])
				await testVault.connect(manager3).withdrawTokens([addrs[0].address], [amountOfVesting.div(2)])
				if (v < vestingData.length - 1) {
					await testVault.connect(manager1).withdrawTokens([addrs[0].address], [amountOfVesting.div(2)])
					await testVault.connect(manager2).withdrawTokens([addrs[0].address], [amountOfVesting.div(2)])
					await testVault.connect(manager3).withdrawTokens([addrs[0].address], [amountOfVesting.div(2)])
				} else {
					await testVault.connect(manager1).withdrawTokens([addrs[0].address], [vestingData[vestingData.length - 1].amount.div(2).add(ethers.utils.parseEther("1"))])
					await testVault.connect(manager2).withdrawTokens([addrs[0].address], [vestingData[vestingData.length - 1].amount.div(2).add(ethers.utils.parseEther("1"))])
				}
			}
			const tx = testVault.connect(manager3).withdrawTokens([addrs[0].address], [vestingData[vestingData.length - 1].amount.div(2).add(ethers.utils.parseEther("1"))])
			await expect(tx).to.be.revertedWith("Not enough released tokens and no more vesting")

		})
	})

});

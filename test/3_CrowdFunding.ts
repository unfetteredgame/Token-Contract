import { ethers, waffle } from 'hardhat';
import chai from 'chai';

import ProxyArtifact from '../artifacts/contracts/Proxy.sol/Proxy.json';
import ManagersArtifact from '../artifacts/contracts/Managers.sol/Managers.json';
import SoulsArtifact from '../artifacts/contracts/SoulsToken.sol/SoulsToken.json';
import CrowdFundingArtifact from '../artifacts/contracts/CrowdFunding.sol/CrowdFunding.json';


import { Proxy } from '../typechain/Proxy';
import { Managers } from '../typechain/Managers';
import { SoulsToken } from '../typechain/SoulsToken';
import { CrowdFunding } from '../typechain/CrowdFunding';



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


describe('CrowdFunding Contract', () => {
	return
	let owner: SignerWithAddress;
	let manager1: SignerWithAddress;
	let manager2: SignerWithAddress;
	let manager3: SignerWithAddress;
	let manager4: SignerWithAddress;
	let manager5: SignerWithAddress;
	let investor1: SignerWithAddress;
	let investor2: SignerWithAddress;
	let investor3: SignerWithAddress;
	let investor4: SignerWithAddress;
	let investor5: SignerWithAddress;
	let investor6: SignerWithAddress;
	let addrs: SignerWithAddress[];


	let managers: Managers
	let proxy: Proxy;
	let souls: SoulsToken;
	let crowdFunding: CrowdFunding;

	beforeEach(async () => {
		[owner, manager1, manager2, manager3, manager4, manager5, investor1, investor2, investor3, investor4, investor5, investor6, ...addrs] = await ethers.getSigners();

		proxy = (await deployContract(owner, ProxyArtifact, [manager1.address, manager2.address, manager3.address, manager4.address, manager5.address])) as Proxy;
		managers = new ethers.Contract(await proxy.managers(), ManagersArtifact.abi) as Managers
		souls = new ethers.Contract(await proxy.soulsToken(), SoulsArtifact.abi, owner) as SoulsToken
		crowdFunding = (await deployContract(owner, CrowdFundingArtifact, ["Seed Sale", souls.address, managers.address])) as CrowdFunding;
		await proxy.connect(owner).addToTrustedSources(crowdFunding.address, "Seed Sale Funding");

		console.log("")


	});

	describe('\n\n#########################################\n addRewards function\n#########################################', () => {
		it("Calculate totalAmount variable correct in contract", async () => {
			console.log("crowdfunding balance", await (await souls.connect(owner).balanceOf(crowdFunding.address)).toString())
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)

			expect(await souls.connect(owner).balanceOf(crowdFunding.address)).to.be.equal(ethers.utils.parseEther(calculatedTotalAmount.toString()));
			expect(await crowdFunding.totalRewardAmount()).to.be.equal(ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			console.log("crowdfunding balance", await (await souls.connect(owner).balanceOf(crowdFunding.address)).toString())
			await crowdFunding.connect(owner).addRewards(
				[investor4.address, investor5.address, investor6.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)
			calculatedTotalAmount += 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			expect(await crowdFunding.totalRewardAmount()).to.be.equal(ethers.utils.parseEther(calculatedTotalAmount.toString()))
		})
		it("Cannot add reward for same investor second time", async () => {

			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)
			expect(await crowdFunding.totalRewardAmount()).to.be.equal(ethers.utils.parseEther(calculatedTotalAmount.toString()))

			let newCalculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))

			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(newCalculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(newCalculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(newCalculatedTotalAmount.toString()))

			const tx = crowdFunding.connect(owner).addRewards(
				[investor1.address, investor5.address, investor6.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)
			await expect(tx).to.be.revertedWith("Investor already added")
		})
	})

	describe('\n\n#########################################\n claimRewards function\n#########################################', () => {
		it("Cannot claim advance amount before release date", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)
			const rewardsInfo = await crowdFunding.connect(investor1).fetchRewardsInfo(0);
			const blockTime = (await ethers.provider.getBlock("latest")).timestamp
			await simulateTimeInSeconds(rewardsInfo.releaseDate.toNumber() - blockTime - 10)

			const tx = crowdFunding.connect(investor1).claimRewards(0);
			await expect(tx).to.be.revertedWith("Early request")
		})

		it("Must be 30 days between vestings's release dates", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)


			for (let i = 1; i <= 23; i++) {
				const prevRewardsInfo = await crowdFunding.connect(investor1).fetchRewardsInfo(i - 1);
				const rewardsInfo = await crowdFunding.connect(investor1).fetchRewardsInfo(i);
				expect(rewardsInfo.releaseDate.sub(prevRewardsInfo.releaseDate)).to.be.equal(30 * 24 * 60 * 60);

			}
		})

		it("Can claim vestings when reach their release dates", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)


			for (let i = 0; i <= 23; i++) {
				const rewardsInfo = await crowdFunding.connect(investor1).fetchRewardsInfo(i);
				const blockTime = (await ethers.provider.getBlock("latest")).timestamp
				await simulateTimeInSeconds(rewardsInfo.releaseDate.toNumber() - blockTime)
				await crowdFunding.connect(investor1).claimRewards(i);
				console.log("User claimed " + ethers.utils.formatEther(rewardsInfo.amount) + " tokens on " + new Date(rewardsInfo.releaseDate.toNumber() * 1000).toDateString())
			}
			const userBalance = await souls.connect(investor1).balanceOf(investor1.address)
			console.log("")
			console.log("User balance after claiming all the vestings: " + ethers.utils.formatEther(userBalance))
			expect(userBalance).to.be.equal(ethers.utils.parseEther((1000 * 24).toString()))
		})
		it("Cannot claim investor when blacklested", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)

			console.log("Managers will add the investor's address to blacklist after 12th vesting.")
			for (let i = 0; i <= 23; i++) {
				const rewardsInfo = await crowdFunding.connect(investor1).fetchRewardsInfo(i);
				const blockTime = (await ethers.provider.getBlock("latest")).timestamp
				await simulateTimeInSeconds(rewardsInfo.releaseDate.toNumber() - blockTime)

				if (i == 12) {
					await crowdFunding.connect(manager1).addToBlacklist(investor1.address);
					await crowdFunding.connect(manager2).addToBlacklist(investor1.address);
					await crowdFunding.connect(manager3).addToBlacklist(investor1.address);
				}
				if (i >= 12) {
					const tx = crowdFunding.connect(investor1).claimRewards(i);
					await expect(tx).to.be.revertedWith("Address is blacklisted")
					console.log("Vesting " + (i + 1) + ": Claim rejected because the address is blacklisted")
				} else {
					await crowdFunding.connect(investor1).claimRewards(i);
					console.log("Vesting " + (i + 1) + ": User claimed " + ethers.utils.formatEther(rewardsInfo.amount) + " tokens on " + new Date(rewardsInfo.releaseDate.toNumber() * 1000).toDateString())
				}
			}
		})
	})

	describe('\n\n#########################################\n withdrawTokens function\n#########################################', () => {
		it("Transfers tokens to given address when requested by 3 of managers", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000)) + 200
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)

			await crowdFunding.connect(manager1).withdrawTokens(manager1.address, 200);
			await crowdFunding.connect(manager2).withdrawTokens(manager1.address, 200);

			await expect(() => crowdFunding.connect(manager3).withdrawTokens(manager1.address, 200))
				.to.changeTokenBalance(souls, manager1, 200);
		})
	})

	describe('\n\n#########################################\n deactivateInvestorVesting and activateInvestorVesting function\n#########################################', () => {
		it("Reverts deactivating if address is not investor", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)

			const tx = crowdFunding.connect(manager1).deactivateInvestorVesting(investor4.address, 0);
			await expect(tx).to.be.revertedWith("Reward owner not found")
		})
		it("Reverts deactivating if vesting index is invalid", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)

			const tx = crowdFunding.connect(manager1).deactivateInvestorVesting(investor1.address, 24);
			await expect(tx).to.be.revertedWith("Invalid vesting index")
		})

		it("Reverts deactivating if vesting has already claimed", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)
			const rewardsInfo = await crowdFunding.connect(investor1).fetchRewardsInfo(0);
			const blockTime = (await ethers.provider.getBlock("latest")).timestamp
			await simulateTimeInSeconds(rewardsInfo.releaseDate.toNumber() - blockTime)

			await crowdFunding.connect(investor1).claimRewards(0);

			const tx = crowdFunding.connect(manager1).deactivateInvestorVesting(investor1.address, 0);
			await expect(tx).to.be.revertedWith("Already claimed")

		})

		it("Managers can deactivate vesting for an investor with specified vesting index by voting if everything is ok", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)

			await crowdFunding.connect(manager1).deactivateInvestorVesting(investor1.address, 0);
			await crowdFunding.connect(manager2).deactivateInvestorVesting(investor1.address, 0);
			await crowdFunding.connect(manager3).deactivateInvestorVesting(investor1.address, 0);
			const rewardsInfo = await crowdFunding.connect(investor1).fetchRewardsInfo(0);
			await expect(rewardsInfo.isActive).to.be.equal(false)

			const blockTime = (await ethers.provider.getBlock("latest")).timestamp
			await simulateTimeInSeconds(rewardsInfo.releaseDate.toNumber() - blockTime)
			const tx = crowdFunding.connect(investor1).claimRewards(0);
			await expect(tx).to.be.revertedWith("Reward is deactivated")
		})

		it("Reverts activating if vesting is already active", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)

			const tx = crowdFunding.connect(manager1).activateInvestorVesting(investor1.address, 0);
			await expect(tx).to.be.revertedWith("Already active")
		})

		it("Managers can activate vesting for an investor with specified vesting index by voting if everything is ok", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)

			await crowdFunding.connect(manager1).deactivateInvestorVesting(investor1.address, 0);
			await crowdFunding.connect(manager2).deactivateInvestorVesting(investor1.address, 0);
			await crowdFunding.connect(manager3).deactivateInvestorVesting(investor1.address, 0);
			let rewardsInfo = await crowdFunding.connect(investor1).fetchRewardsInfo(0);
			await expect(rewardsInfo.isActive).to.be.equal(false)

			await crowdFunding.connect(manager1).activateInvestorVesting(investor1.address, 0);
			await crowdFunding.connect(manager2).activateInvestorVesting(investor1.address, 0);
			await crowdFunding.connect(manager3).activateInvestorVesting(investor1.address, 0);
			rewardsInfo = await crowdFunding.connect(investor1).fetchRewardsInfo(0);
			await expect(rewardsInfo.isActive).to.be.equal(true)


			const blockTime = (await ethers.provider.getBlock("latest")).timestamp
			await simulateTimeInSeconds(rewardsInfo.releaseDate.toNumber() - blockTime)
			await crowdFunding.connect(investor1).claimRewards(0);
		})
	})

	describe('\n\n#########################################\n addToBlacklist and removeFromBlacklist function\n#########################################', () => {
		it("Reverts adding to blacklist if address is not investor", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)

			const tx = crowdFunding.connect(manager1).addToBlacklist(investor4.address);
			await expect(tx).to.be.revertedWith("Reward owner not found")
		})

		it("Reverts adding to blacklist if address is already blacklisted", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)

			await crowdFunding.connect(manager1).addToBlacklist(investor1.address);
			await crowdFunding.connect(manager2).addToBlacklist(investor1.address);
			await crowdFunding.connect(manager3).addToBlacklist(investor1.address);

			const tx = crowdFunding.connect(manager1).addToBlacklist(investor1.address);
			await expect(tx).to.be.revertedWith("Already blacklisted")
		})

		it("Adds to blacklist if everything is ok", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)

			await crowdFunding.connect(manager1).addToBlacklist(investor1.address);
			await crowdFunding.connect(manager2).addToBlacklist(investor1.address);
			await crowdFunding.connect(manager3).addToBlacklist(investor1.address);

			expect(await crowdFunding.blacklist(investor1.address)).to.be.equal(true)
		})

		it("Reverts removing from blacklist if address is not blacklisted", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)

			const tx = crowdFunding.connect(manager1).addToBlacklist(investor4.address);
			await expect(tx).to.be.revertedWith("Reward owner not found")
		})

		it("Reverts removing from blacklist if address is not blacklisted", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)

			const tx = crowdFunding.connect(manager1).removeFromBlacklist(investor1.address);
			await expect(tx).to.be.revertedWith("Not blacklisted")
		})

		it("Removes from blacklist if everything is ok", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)
			console.log("Managers are adding investor address to blacklist")
			await crowdFunding.connect(manager1).addToBlacklist(investor1.address);
			await crowdFunding.connect(manager2).addToBlacklist(investor1.address);
			await crowdFunding.connect(manager3).addToBlacklist(investor1.address);

			expect(await crowdFunding.blacklist(investor1.address)).to.be.equal(true)
			console.log("Address is blacklisted")

			console.log("Managers are removing investor address from blacklist")

			await crowdFunding.connect(manager1).removeFromBlacklist(investor1.address);
			await crowdFunding.connect(manager2).removeFromBlacklist(investor1.address);
			await crowdFunding.connect(manager3).removeFromBlacklist(investor1.address);

			expect(await crowdFunding.blacklist(investor1.address)).to.be.equal(false)
			console.log("Address is not blacklisted now")
		})
	})

	describe('\n\n#########################################\n fetchRewardsInfo function\n#########################################', () => {
		it("Returns reward info for caller investor and given vesting index", async () => {
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)
			const investorVestingCount = await crowdFunding.connect(owner).investors(investor1.address)
			for (let i = 0; i < investorVestingCount.vestingCount.toNumber(); i++) {
				const rewardInfo = await crowdFunding.connect(investor1).fetchRewardsInfo(i)
				expect(rewardInfo.amount).to.be.gt(0)
			}
		})
	})

	describe('\n\n#########################################\n fetchInvestorList function\n#########################################', () => {
		it("returns address list of investors", async () => {
			console.log("Defining rewards for 3 investors")
			let calculatedTotalAmount = 1000 + 2000 + 3000 + (23 * (1000 + 2000 + 3000))
			await proxy.connect(manager1).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager2).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))
			await proxy.connect(manager3).transferTokensToCrowdFundingContract(crowdFunding.address, ethers.utils.parseEther(calculatedTotalAmount.toString()))

			await crowdFunding.connect(owner).addRewards(
				[investor1.address, investor2.address, investor3.address],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[ethers.utils.parseEther("1000"), ethers.utils.parseEther("2000"), ethers.utils.parseEther("3000")],
				[23, 23, 23],
				(await ethers.provider.getBlock("latest")).timestamp + 7 * 24 * 60 * 60
			)
			const investors = await crowdFunding.connect(owner).fetchInvestorList()
			console.log("Investor list in contract: ", investors)

			expect(investors.length).to.be.equal(3)
		})
	})

});

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
var crypto = require('crypto');


describe('Managers Contract', () => {
	let owner: SignerWithAddress;
	let manager1: SignerWithAddress;
	let manager2: SignerWithAddress;
	let manager3: SignerWithAddress;
	let manager4: SignerWithAddress;
	let manager5: SignerWithAddress;
	let addrs: SignerWithAddress[];


	let managers: Managers
	let proxy: Proxy;

	beforeEach(async () => {
		[owner, manager1, manager2, manager3, manager4, manager5, ...addrs] = await ethers.getSigners();

		proxy = (await deployContract(owner, ProxyArtifact, [manager1.address, manager2.address, manager3.address, manager4.address, manager5.address])) as Proxy;
		managers = new ethers.Contract(await proxy.managers(), ManagersArtifact.abi) as Managers

	});

	describe('addAddressToTrustedSources function', () => {
		it("Only proxy can add an address to trusted sources", async () => {
			const id = crypto.randomBytes(32).toString('hex');
			const privateKey = "0x" + id;

			var wallet = new ethers.Wallet(privateKey);

			const tx = managers.connect(owner).addAddressToTrustedSources(wallet.address)
			await expect(tx).to.be.revertedWith('Ownable: caller is not the owner');

			const managersOwnerAddress = await managers.connect(owner).owner()
			expect(managersOwnerAddress).to.be.equal(proxy.address);

			await proxy.testAddTrustedSources(wallet.address);
			const isAddressTrusted = await managers.connect(owner).trustedSources(wallet.address);
			expect(isAddressTrusted).to.be.equal(true);
		});
	});

	describe('isManager function', () => {
		it("returns true only for manager addresses", async () => {
			const id = crypto.randomBytes(32).toString('hex');
			const privateKey = "0x" + id;
			var wallet = new ethers.Wallet(privateKey);

			//Test random wallet address
			const isManager = await managers.connect(owner).isManager(wallet.address)
			expect(isManager).to.be.equal(false);

			expect(await managers.connect(owner).isManager(manager1.address)).to.be.equal(true);
			expect(await managers.connect(owner).isManager(manager2.address)).to.be.equal(true);
			expect(await managers.connect(owner).isManager(manager3.address)).to.be.equal(true);
			expect(await managers.connect(owner).isManager(manager4.address)).to.be.equal(true);
			expect(await managers.connect(owner).isManager(manager5.address)).to.be.equal(true);
		});
	});

	describe('approveTopic function', () => {
		it("only trusted sources can approve a topic and tx.origin must be a manager", async () => {
			//Add proxy contract to trusted sources
			await proxy.testAddTrustedSources(proxy.address);

			const id = crypto.randomBytes(32).toString('hex');
			const privateKey = "0x" + id;
			var wallet = new ethers.Wallet(privateKey);

			//Test to call function directly from unauthorized wallet 
			let tx = managers.connect(owner).approveTopic("test", ethers.utils.randomBytes(32))
			await expect(tx).to.be.revertedWith("Not authorized")

			//Test to call function directly from authorized wallet 
			tx = managers.connect(manager1).approveTopic("test", ethers.utils.randomBytes(32))
			await expect(tx).to.be.revertedWith("MANAGERS: Untrusted source")

			//Test to call function directly from a trusted contract 
			tx = proxy.connect(owner).testApproveTopicFunction(wallet.address);
			await expect(tx).to.be.revertedWith("Not authorized")

			//Test to call function by a manager over a trusted contract 
			await proxy.connect(manager1).testApproveTopicFunction(wallet.address);
			const managerApproval = await managers.connect(owner).managerApprovalsForTopic("Test Approve Topic Function", manager1.address)
			expect(managerApproval.approved).to.be.equal(true);

			const addedTopic = await managers.connect(owner).activeTopics(0)
			expect(addedTopic.title).to.be.equal("Test Approve Topic Function");
			expect(addedTopic.approveCount).to.be.equal(1);


		});

		it("adds topic to list when approved by a manager", async () => {
			//Add proxy contract to trusted sources
			await proxy.testAddTrustedSources(proxy.address);

			const id = crypto.randomBytes(32).toString('hex');
			const privateKey = "0x" + id;
			var wallet1 = new ethers.Wallet(privateKey);

			;

			await proxy.connect(manager1).testApproveTopicFunction(wallet1.address);
			const addedTopics = await managers.connect(owner).getActiveTopics()
			expect(addedTopics.length).to.be.equal(1);
			const addedTopic = await managers.connect(owner).activeTopics(0)
			expect(addedTopic.title).to.be.equal("Test Approve Topic Function");
			expect(await proxy.approveTopicTestVariable()).to.be.equal(false);
		});


		it("approves topic if approved by 3 of managers", async () => {
			//Add proxy contract to trusted sources
			await proxy.testAddTrustedSources(proxy.address);

			const id = crypto.randomBytes(32).toString('hex');
			const id2 = crypto.randomBytes(32).toString('hex');
			const privateKey = "0x" + id;
			const privateKey2 = "0x" + id2;
			var wallet1 = new ethers.Wallet(privateKey);
			var wallet2 = new ethers.Wallet(privateKey2);

			let addedTopic;

			await proxy.connect(manager1).testApproveTopicFunction(wallet1.address);
			addedTopic = await managers.connect(owner).activeTopics(0)
			expect(addedTopic.approveCount).to.be.equal(1);
			expect(await proxy.approveTopicTestVariable()).to.be.equal(false);

			await proxy.connect(manager2).testApproveTopicFunction(wallet1.address);
			addedTopic = await managers.connect(owner).activeTopics(0)
			expect(addedTopic.approveCount).to.be.equal(2);
			expect(await proxy.approveTopicTestVariable()).to.be.equal(false);


			//Send wallet2 address as parameter instead of wallet1
			await proxy.connect(manager3).testApproveTopicFunction(wallet2.address);
			addedTopic = await managers.connect(owner).activeTopics(0)
			expect(addedTopic.approveCount).to.be.equal(3);
			expect(await proxy.approveTopicTestVariable()).to.be.equal(false);


			await proxy.connect(manager4).testApproveTopicFunction(wallet1.address);
			expect(await proxy.approveTopicTestVariable()).to.be.equal(true);
		});

		it("removes topic from list when approved by 3 of managers", async () => {
			//Add proxy contract to trusted sources
			await proxy.testAddTrustedSources(proxy.address);

			const id = crypto.randomBytes(32).toString('hex');
			const privateKey = "0x" + id;
			var wallet = new ethers.Wallet(privateKey);

			let addedTopic;

			await proxy.connect(manager1).testApproveTopicFunction(wallet.address);
			addedTopic = await managers.connect(owner).activeTopics(0)
			expect(addedTopic.approveCount).to.be.equal(1);
			expect(await proxy.approveTopicTestVariable()).to.be.equal(false);

			await proxy.connect(manager2).testApproveTopicFunction(wallet.address);
			addedTopic = await managers.connect(owner).activeTopics(0)
			expect(addedTopic.approveCount).to.be.equal(2);
			expect(await proxy.approveTopicTestVariable()).to.be.equal(false);


			await proxy.connect(manager3).testApproveTopicFunction(wallet.address);
			const addedTopics = await managers.connect(owner).getActiveTopics()
			expect(addedTopics.length).to.be.equal(0);
			expect(await proxy.approveTopicTestVariable()).to.be.equal(true);
		});
	});

	describe('cancelTopicApproval function', () => {
		it("reverts if title not exists", async () => {
			//Add proxy contract to trusted sources
			await proxy.testAddTrustedSources(proxy.address);

			const id = crypto.randomBytes(32).toString('hex');
			const privateKey = "0x" + id;
			var wallet = new ethers.Wallet(privateKey);

			let tx = managers.connect(manager1).cancelTopicApproval("Non-exist Title");
			await expect(tx).to.be.revertedWith("Topic not found")

		});
		it("reverts if manager didn't voted title", async () => {
			//Add proxy contract to trusted sources
			await proxy.testAddTrustedSources(proxy.address);

			const id = crypto.randomBytes(32).toString('hex');
			const privateKey = "0x" + id;
			var wallet = new ethers.Wallet(privateKey);

			//Vote using manager1
			await proxy.connect(manager1).testApproveTopicFunction(wallet.address);
			const managerApproval = await managers.connect(owner).managerApprovalsForTopic("Test Approve Topic Function", manager1.address)
			expect(managerApproval.approved).to.be.equal(true);;

			//Try to cancel vote using manager2
			let tx = managers.connect(manager2).cancelTopicApproval("Test Approve Topic Function");
			await expect(tx).to.be.revertedWith("Not voted")
		});

		it("cancels manager's vote if voted (also tests _deleteTopic internal function)", async () => {
			//Add proxy contract to trusted sources
			await proxy.testAddTrustedSources(proxy.address);

			const id = crypto.randomBytes(32).toString('hex');
			const privateKey = "0x" + id;
			var wallet = new ethers.Wallet(privateKey);

			//Approve with manager1
			await proxy.connect(manager1).testApproveTopicFunction(wallet.address);
			const managerApproval = await managers.connect(owner).managerApprovalsForTopic("Test Approve Topic Function", manager1.address)
			expect(managerApproval.approved).to.be.equal(true);

			let approveInfo = await managers.connect(owner).managerApprovalsForTopic("Test Approve Topic Function", manager1.address);
			expect(approveInfo.approved).to.be.equal(true);

			//Cancel approval
			await managers.connect(manager1).cancelTopicApproval("Test Approve Topic Function");

			approveInfo = await managers.connect(owner).managerApprovalsForTopic("Test Approve Topic Function", manager1.address);
			expect(approveInfo.approved).to.be.equal(false);

		});


		it("removes from topic list if all the managers canceled their votes", async () => {
			//Add proxy contract to trusted sources
			await proxy.testAddTrustedSources(proxy.address);

			const id = crypto.randomBytes(32).toString('hex');
			const privateKey = "0x" + id;
			var wallet = new ethers.Wallet(privateKey);

			//Approve with manager1
			await proxy.connect(manager1).testApproveTopicFunction(wallet.address);

			//Approve with manager2
			await proxy.connect(manager2).testApproveTopicFunction(wallet.address);


			let approveInfo = await managers.connect(owner).managerApprovalsForTopic("Test Approve Topic Function", manager1.address);
			expect(approveInfo.approved).to.be.equal(true);
			let activeTopics = await managers.connect(owner).getActiveTopics()

			expect(activeTopics.length).to.be.equal(1);
			//Cancel approval
			await managers.connect(manager1).cancelTopicApproval("Test Approve Topic Function");
			activeTopics = await managers.connect(owner).getActiveTopics()
			expect(activeTopics.length).to.be.equal(1);

			await managers.connect(manager2).cancelTopicApproval("Test Approve Topic Function");
			activeTopics = await managers.connect(owner).getActiveTopics()

			expect(activeTopics.length).to.be.equal(0);
		});



	});

	describe('changeManagerAddress function', () => {
		it("reverts if try to change own address", async () => {
			//Add proxy contract to trusted sources
			await proxy.testAddTrustedSources(proxy.address);

			const id = crypto.randomBytes(32).toString('hex');
			const privateKey = "0x" + id;
			var wallet = new ethers.Wallet(privateKey);

			let tx = managers.connect(manager1).changeManager1Address(wallet.address);
			await expect(tx).to.be.revertedWith("Cannot vote to set own address")

		});
		it("changes if approved same address by 3 other managers", async () => {
			//Add proxy contract to trusted sources
			await proxy.testAddTrustedSources(proxy.address);

			const id = crypto.randomBytes(32).toString('hex');
			const privateKey = "0x" + id;
			var wallet = new ethers.Wallet(privateKey);

			await managers.connect(manager2).changeManager1Address(wallet.address);
			await managers.connect(manager3).changeManager1Address(wallet.address);
			await managers.connect(manager4).changeManager1Address(wallet.address);

			expect(await managers.connect(owner).manager1()).to.be.equal(wallet.address);

		});
	});
});

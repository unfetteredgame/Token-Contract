require('dotenv').config();

import { task, HardhatUserConfig } from 'hardhat/config';
import '@typechain/hardhat';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-solhint';
import 'solidity-coverage';
import '@nomiclabs/hardhat-etherscan';

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
	const accounts = await hre.ethers.getSigners();

	for (const account of accounts) {
		console.log(account.address);
	}
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
const config: HardhatUserConfig = {
	solidity: {
		compilers: [
			{
				version: "0.5.0",
			},
			{
				version: "0.8.12",
				settings: {},
			},
		],
		settings: {
			optimizer: {
				enabled: true,
				runs: 200
			}
		}
	},
	networks: {
		hardhat: {
			//   mining: {
			//     auto: true,
			//     interval: 1000,
			//   },
			// gasPrice: 0,
			// initialBaseFeePerGas: 0,
			accounts: {
				count: 20,
				mnemonic: process.env.MNEMONIC,
				path: "m/44'/60'/0'/0",
			},
			forking: {
				url: "https://speedy-nodes-nyc.moralis.io/71ece097b9de0b700fb55cfc/bsc/testnet",
			},
			gasPrice:5000000000
		},

		rinkeby: {
			allowUnlimitedContractSize: true,
			url: process.env.RINKEBY_URL || '',
			// accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
			accounts: {
				count: 20,
				mnemonic: process.env.MNEMONIC,
				path: "m/44'/60'/0'/0",
			}, 
			gasPrice: 5000000000
		},
		bsctestnet: {
			allowUnlimitedContractSize: true,
			url: process.env.BSC_TESTNET_URL || '',
			// accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
			accounts: {
				count: 20,
				mnemonic: process.env.MNEMONIC,
				path: "m/44'/60'/0'/0",
			},
			gasPrice:5000000000
		},
		bscmainnet: {
			allowUnlimitedContractSize: true,
			url: process.env.BSC_MAINNET_URL || '',
			// accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
			accounts: {
				count: 20,
				mnemonic: process.env.MNEMONIC,
				path: "m/44'/60'/0'/0",
			},
			gasPrice: 5000000000
		},
	},
};

export default config;

const { apiKey, mnemonic } = require('./secrets.json')
const HDWalletProvider = require('@truffle/hdwallet-provider')

module.exports = {
	networks: {
		develop: {
			port: 8545,
			network_id: '*',
			skipDryRun: true,
		},
		kovan: {
			provider: () => {
				return new HDWalletProvider(mnemonic, `https://kovan.infura.io/v3/${apiKey}`)
			},
			network_id: '42',
			gasPrice: 10e9,
			skipDryRun: true,
		},
	},
	compilers: {
		solc: {
			version: '0.6.7',
		},
	},
}
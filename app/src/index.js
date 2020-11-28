import Web3 from "web3"
import { getAPY } from "./APY.mjs"

const App = {
	web3: null,
	account: null,

	start: async function() {
		const { web3 } = this

		try {
			// get network id
			const networkId = await web3.eth.net.getId()

			// get accounts
			const accounts = await web3.eth.getAccounts()
			this.account = accounts[0]

		/*
			const currentBlock = await web3.eth.getBlockNumber()
			document.getElementById("message").innerHTML = currentBlock
		*/
			const TWT_APY = await getAPY(web3, '0x9c4EBADa591FFeC4124A7785CAbCfb7068fED2fb')
			console.log(TWT_APY)
		} catch (error) {
			console.error("Could not connect to contract or chain.")
		}
	},
}

window.App = App

window.addEventListener("load", function() {
	if (window.ethereum) {
		// use MetaMask's provider
		App.web3 = new Web3(window.ethereum)
		window.ethereum.enable() // get permission to access accounts
	} else {
		console.warn(
			"No web3 detected. Falling back to http://127.0.0.1:8545. You should remove this fallback when you deploy live",
		)
		// fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
		App.web3 = new Web3(
			new Web3.providers.HttpProvider("http://127.0.0.1:8545"),
		)
	}

	App.start()
})

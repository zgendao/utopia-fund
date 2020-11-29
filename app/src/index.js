import Web3 from "web3"
import { getAPY } from "./APY.mjs"

const App = {
	web3: null,
	account: null,

	start: async function() {
		let bestAPYPool
		let bestAPY = 0

		//Kigyűjtöttem az addresseket, ha a tokeneké nem kell kitörölheted
		let cakePoolAddress = "0x73feaa1eE314F8c655E354234017bE2193C9E24E"
		let twtPoolAddress = "0x9c4EBADa591FFeC4124A7785CAbCfb7068fED2fb"
		let unfiPoolAddress = "0xFb1088Dae0f03C5123587d2babb3F307831E6367"
		let blkPoolAddress = "0x42Afc29b2dEa792974d1e9420696870f1Ca6d18b"

		let cakeTokenAddress = "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82"
		let twtTokenAddress = "0x4b0f1812e5df2a09796481ff14017e6005508003"
		let unfiTokenAddress = "0x728c5bac3c3e370e372fc4671f9ef6916b814d8b"
		let blkTokenAddress = "0x63870a18b6e42b01ef1ad8a2302ef50b7132054f"


		//A "reward" az legyen amivel a coingecko API-n be tudod azonosítani
		let pools = [
			{
				"address": cakePoolAddress,
				"reward": cakeTokenAddress,
				"APY": 0
			},
			{
				"address": twtPoolAddress,
				"reward": twtTokenAddress,
				"APY": 0
			},
			{
				"address": unfiPoolAddress,
				"reward": unfiTokenAddress,
				"APY": 0
			},
			{
				"address": blkPoolAddress,
				"reward": blkTokenAddress,
				"APY": 0
			}
		  ]

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

			//Itt történik a varázslat
			pools.forEach(pool => pool.APY = await getAPY(web3, pool.address, pool.reward))
			pools.forEach(pool => {
				if(pool.APY > bestAPY){
					bestAPY = pool.APY
					bestAPYPool = pool.address
				}
			})
			console.log(bestAPYPool)
			console.log(bestAPY)

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

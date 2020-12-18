import Web3 from "web3"
import { addr } from "./crypto_helper.mjs"
import { getAPY } from "./APY.mjs"

const App = {
	web3: null,
	account: null,

	start: async function() {
		let bestAPYPool
		let bestAPY = 0
		
		let pools = [
			{
				"address": addr['cake_pool'],
				"reward": addr['cake_token'],
				"APY": 0
			},
			{
				"address": addr['twt_pool'],
				"reward": addr['twt_token'],
				"APY": 0
			},
			{
				"address": addr['unfi_pool'],
				"reward": addr['unfi_token'],
				"APY": 0
			},
			{
				"address": addr['blk_pool'],
				"reward": addr['blk_token'],
				"APY": 0
			}
		]

		const { web3 } = this

		try {
			// get accounts
			const accounts = await web3.eth.getAccounts()
			this.account = accounts[0]

			function updateAPY() {
				new Promise((resolve, reject) => {
					let counter = 0
					// looping through each pool
					pools.forEach(
						pool => {
							function cb(APY) {
								console.log(APY)
								pool.APY = APY
							
								// finding the highest APY
								if (pool.APY > bestAPY) {
									bestAPY = pool.APY
									bestAPYPool = pool.address
								}
								
								if (counter++ === 3)
									resolve()
							}
	
							getAPY(web3, pool.address, pool.reward, cb)
						}
					)
				}).then(() => {
					console.log(`The address of the pool with the highest APY is ${bestAPYPool}`)
					console.log(`The highest APY is ${bestAPY}`)

					let today = new Date()
					console.log(`Current time is ${today.getHours()}:${today.getMinutes()}:${today.getSeconds()}`)
				})
			}

			updateAPY()

			// calling the updateAPY function every three hours
			setInterval(() => updateAPY(), 1000 * 60 * 60 * 3)
		} catch (error) {
			console.error(error)
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

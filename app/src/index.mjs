import Web3 from "web3"
import { addr, symbols } from "./crypto_helper.mjs"
import { getAPY } from "./APY.mjs"
import myContractArtifact from "../../build/contracts/Strategy.json"

let currentPool
let currentAPY = 0
let bestPool
let bestAPY = 0

async function start() {
	// list of pools to make everything easier
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
	]

	// initialize web3 with the address of the BSC mainnet
	const web3 = new Web3(new Web3.providers.HttpProvider('https://bsc-dataseed1.binance.org:443'))
	const networkId = await web3.eth.net.getId()
	const deployedNetwork = myContractArtifact.networks[networkId]

	const contract = new web3.eth.Contract(myContractArtifact.abi, deployedNetwork.address,)

	try {
		function updateAPY() {
			new Promise((resolve, reject) => {
				let counter = 0
				let timerC = 0
				// looping through each pool
				pools.forEach(
					pool => {
						setTimeout(function() {
							// callback function
							function cb(APY) {
								console.log(`APY: ${APY}\n`)
								pool.APY = APY
							
								// finding the highest APY
								if (pool.APY >= bestAPY) {
									bestAPY = pool.APY
									bestPool = pool.address
								}
								
								if (counter++ === 1)
									resolve()
							}
	
							getAPY(web3, pool.address, pool.reward, cb)
						}, timerC++ * 1000)
					}
				)
			}).then(async () => {
				console.log(`The address of the pool with the highest APY is ${bestPool}`)
				console.log(`The highest APY is ${bestAPY}`)

				if (bestAPY >= currentAPY + 0.05) {
					currentAPY = bestAPY
					currentPool = bestPool

					let userAccount = await web3.eth.getAccounts()
					console.log(userAccount)
					await contract.methods.reinvest(symbols[currentPool]).send( {from : userAccount[0]} )
				}

				let today = new Date()
				console.log(`Current time is ${today.getHours()}:${today.getMinutes()}:${today.getSeconds()}`)
			})
		}

		updateAPY()

		// calling the updateAPY function every hour
		setInterval(() => updateAPY(), 1000 * 60 * 60 * 1)
	} catch (error) {
		console.error(error)
	}
}

start()

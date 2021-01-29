const Web3 = require('web3')
const Accounts = require('web3-eth-accounts')
const readline = require("readline")
const keystore = require('./keystore.json')
const crypto_helper = require('./crypto_helper')
const getAPY = require('./APY')
const strat = require('./stratAbi')
//This needs to be set when we deploy the vault
const vaultAddress = "0x0"

let addr = crypto_helper.addr
let strategies = crypto_helper.strategies
let stratAbi = strat.abi

let currentPool
let currentAPY = 0
let bestPool
let bestAPY = 0

// initialize the prompt
const rl = readline.createInterface({
	input: process.stdin,
	output: process.stdout
})

// initialize web3 with the address of the BSC mainnet
const web3 = new Web3(new Web3.providers.HttpProvider('https://bsc-dataseed1.binance.org:443'))

// ask for password
rl.question("Enter the password: ", function(password) {
	// get the private key
	const userAccount = web3.eth.accounts.decrypt(keystore, password)
	console.log(`loaded account with address "${userAccount.address}"`)

	// add the account to the wallet
	web3.eth.accounts.wallet.add(userAccount.privateKey)

	// set it as the default account address
	web3.eth.defaultAccount = userAccount.address

	console.log()
	rl.close()
})

rl.on("close", function() {
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
	
		const vault = new web3.eth.Contract(stratAbi, vaultAddress)
	
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
	
						await vault.methods.changeStrategy(strategies[currentPool]).send( {from : web3.eth.defaultAccount, gas: 500000} )
					}
	
					let today = new Date()
					console.log(`Current time is ${today.getHours()}:${today.getMinutes()}:${today.getSeconds()}`)
				})
			}
			//calling the harvest function every 24 hours
			async function harvesting() {
				vault.methods.harvest().send( {from : web3.eth.defaultAccount, gas: 500000}).then(
					async function() {
						console.log("successful harvest");
						setTimeout(async () => await harvesting(), 1000 * 60 * 60 * 24)	
					}
				).catch(
					async function() {
						console.log("failed harvest");
						await harvesting()
					}
				)
			}
			harvesting();

			updateAPY()
	
			// calling the updateAPY function every hour
			setInterval(() => updateAPY(), 1000 * 60 * 60 * 1)
		} catch (error) {
			console.error(error)
		}
	}
	
	start()
})

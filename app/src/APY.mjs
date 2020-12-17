import { addr, coingecko_ids } from "./crypto_helper.mjs"

// api URL for crypto prices
const priceURL = 'https://api.coingecko.com/api/v3/simple/price'

let currentBlock			// block number of the current block
let bonusEndBlock			// block number of the last block
let rewardPerBlock			// how much do we earn per one block
let rewardTokenPrice		// price of the token in CAKE
let cakeAmountInContract	// how much CAKE is in the contract
let cakePrice				// current price of CAKE in USD
let blockDiff				// the difference between the current and last block
							// (how many blocks left)
let decimals				// how many decimals is the token contract using

/**
 * A function to calculate the APY of a syrup pool
 * @param web3 is the web3 object
 * @param address is the address of syrup pool
 * @param rewardToken is the address of a token contract
 * @param callback is the function that gets executed when we get the APY
 */
export async function getAPY(web3, address, rewardToken, callback) {
	// first we get the block number of the current block
	web3.eth.getBlockNumber().then(num => {
		currentBlock = num

		// now we ask for the abi of the pool contract
		$.ajax({
			url: `https://api.bscscan.com/api?module=contract&action=getabi&address=${address}`,
			dataType: 'json',
			async: false,
			success: function (data) {
				const abi = JSON.parse(data['result'])
				const contract = new web3.eth.Contract(abi, address)

				let getBonusEndBlock = async () => {
					// there is no 'bonusEndBlock' in the CAKE pool
					if (address === addr["cake_pool"])
						return currentBlock + (60 * 60 * 8 * 365) // 8 is 24 / 3

					return await contract.methods.bonusEndBlock.call().call()
				}

				let getRewardPerBlock = async () => {
					// the variable is called 'cakePerBlock' insteod of 'rewardPerBlock'
					if (address === addr["cake_pool"])
						return 10 ** 19

					return await contract.methods.rewardPerBlock.call().call()
				}

				let getDecimals = async () => {
					let tokenContract

					await $.ajax({
						url: `https://api.bscscan.com/api?module=contract&action=getabi&address=${rewardToken}`,
						dataType: 'json',
						async: false,
						success: function (data) {
							const tokenAbi = JSON.parse(data['result'])
							tokenContract = new web3.eth.Contract(tokenAbi, rewardToken)
						}
					})

					return await tokenContract.methods.decimals.call().call()
				}

				// we get the block number of the last block and the amount of rewards per block
				Promise.all([getBonusEndBlock(), getRewardPerBlock(), getDecimals()]).then((values) => {
					bonusEndBlock = values[0]
					rewardPerBlock = values[1]
					blockDiff = bonusEndBlock - currentBlock

					decimals = values[2]
	
					console.log(`currentBlock: ${currentBlock}`)
					console.log(`bonusEndBlock: ${bonusEndBlock}`)
					console.log(`rewardPerBlock: ${rewardPerBlock}`)
					console.log(`blockDiff: ${blockDiff}`)
					console.log(`decimals: ${decimals}`)

					// the amount of CAKE in the pool
					$.ajax({
						url: `https://api.bscscan.com/api?module=account&action=tokenbalance&contractaddress=${addr['cake_token']}&address=${address}&tag=latest`,
						dataType: 'json',
						async: false,
						success: function (data) {
							cakeAmountInContract = data['result']
							console.log(`cakeAmountInContract: ${cakeAmountInContract}`)
						}
					})

					// price of the CAKE token
					$.ajax({
						url: `${priceURL}?ids=${coingecko_ids[addr['cake_token']]}&vs_currencies=USD`,
						dataType: 'json',
						async: false,
						success: function (data) {
							cakePrice = data['pancakeswap-token']['usd']
							console.log(`cakePrice: ${cakePrice}`)
						}
					})

					// price of the token we get as reward
					$.ajax({
						url: `${priceURL}?ids=${coingecko_ids[rewardToken]}&vs_currencies=USD`,
						dataType: 'json',
						async: false,
						success: function (data) {
							rewardTokenPrice = data[coingecko_ids[rewardToken]]['usd']
							console.log(`rewardTokenPrice (${coingecko_ids[rewardToken]}): ${rewardTokenPrice}`)
						}
					})

					// we are ready to calculate the APY and send it back to the callback function
					callback(
						(rewardPerBlock * rewardTokenPrice * (10 ** 18 / 10 ** decimals))
						/
						(cakeAmountInContract * cakePrice)
						*
						(365 * 60 * 60 * 8) // 8 is 24 / 3
					)
				})
			},
			error: function() {
				return -1
			}
		})
	})
}
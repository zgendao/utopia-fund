import request from "request"
import { addr, coingecko_ids } from "./crypto_helper.mjs"

// bscscan api
const bscscanapi = 'https://api.bscscan.com/api'
// api URL for crypto prices
const priceURL = 'https://api.coingecko.com/api/v3/simple/price'

/**
 * Simple helper function to make API requests
 * @param url is the url we want to fetch data from
 */
function doRequest(url) {
		return new Promise(function (resolve, reject) {
		request(url, function (error, res, body) {
			if (!error && res.statusCode == 200)
				resolve(JSON.parse(JSON.parse(body).result))
			else
				reject(error)
		})
	})
}

/**
 * Simple helper function to get the price of tokens
 * @param token is the address of the token
 */
function getTokenPrice(token) {
	return new Promise(function (resolve, reject) {
		request(
			`${priceURL}?ids=${coingecko_ids[token]}&vs_currencies=USD`,
			function (error, res, body) {
				if (!error && res.statusCode == 200)
					resolve(JSON.parse(body)[coingecko_ids[token]]['usd'])
				else
					reject(error)
			}
		)
	})
}

/**
 * A function to calculate the APY of a syrup pool
 * @param web3 is the web3 object
 * @param poolAddress is the address of syrup pool
 * @param rewardToken is the address of a token contract
 * @param callback is the function that gets executed when we get the APY
 */
export async function getAPY(web3, poolAddress, rewardToken, callback) {
	let currentBlock			// block number of the current block
	let bonusEndBlock			// block number of the last block
	let rewardPerBlock			// how much do we earn per one block
	let rewardTokenPrice		// price of the token in CAKE
	let cakeAmountInContract	// how much CAKE is in the contract
	let cakePrice				// current price of CAKE in USD
	let blockDiff				// the difference between the current and last block
								// (how many blocks left)
	let decimals				// how many decimals is the token contract using

	// first we get the block number of the current block
	currentBlock = await web3.eth.getBlockNumber()

	// getting the ABI for the pool
	const poolABI = await doRequest(`${bscscanapi}?module=contract&action=getabi&address=${poolAddress}`)

	// initializing the pool contract
	const poolContract = new web3.eth.Contract(poolABI, poolAddress)

	// getting bonusEndBlock
	// there is no 'bonusEndBlock' in the CAKE pool
	if (poolAddress === addr["cake_pool"])
		bonusEndBlock = currentBlock + (60 * 60 * 8 * 365) // 8 is 24 / 3
	else
		bonusEndBlock = await poolContract.methods.bonusEndBlock().call()

	// getting rewardPerBlock
	// the variable is called 'cakePerBlock' insteod of 'rewardPerBlock'
	if (poolAddress === addr["cake_pool"])
		rewardPerBlock = 10 ** 19
	else
		rewardPerBlock = await poolContract.methods.rewardPerBlock().call()

	blockDiff = bonusEndBlock - currentBlock

	// getting the ABI for the reward token contract
	const tokenABI = await doRequest(`${bscscanapi}?module=contract&action=getabi&address=${rewardToken}`)

	// initializing the token contract
	const tokenContract = new web3.eth.Contract(tokenABI, rewardToken)

	// getting the decimals used in the token contract
	decimals = await tokenContract.methods.decimals().call()

	// getting cakeAmountInContract
	cakeAmountInContract = await doRequest(`${bscscanapi}?module=account&action=tokenbalance&contractaddress=${addr['cake_token']}&address=${poolAddress}&tag=latest`)

	// getting the price of the CAKE token
	cakePrice = await getTokenPrice(addr['cake_token'])

	// getting the price of the reward token
	rewardTokenPrice = await getTokenPrice(rewardToken)

	console.log(`currentBlock: ${currentBlock}`)
	console.log(`bonusEndBlock: ${bonusEndBlock}`)
	console.log(`rewardPerBlock: ${rewardPerBlock}`)
	console.log(`blockDiff: ${blockDiff}`)
	console.log(`decimals: ${decimals}`)
	console.log(`cakeAmountInContract: ${cakeAmountInContract}`)
	console.log(`cakePrice: $${cakePrice}`)
	console.log(`rewardTokenPrice (${coingecko_ids[rewardToken]}): $${rewardTokenPrice}`)

	// we are ready to calculate the APY and send it back to the callback function
	callback(
		(rewardPerBlock * rewardTokenPrice * (10 ** 18 / 10 ** decimals))
		/
		(cakeAmountInContract * cakePrice)
		*
		(365 * 60 * 60 * 8) // 8 is 24 / 3
	)
}
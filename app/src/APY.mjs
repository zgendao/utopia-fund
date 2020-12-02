import { addr, coingecko_ids } from "./crypto_helper.mjs"

const priceURL = 'https://api.coingecko.com/api/v3/simple/price'

let currentBlock
let bonusEndBlock
let rewardPerBlock
let rewardTokenPrice
let cakeAmountInContract
let cakePrice
let blockDiff

export function getAPY(web3, address, rewardToken) {
	web3.eth.getBlockNumber().then(num => {
		currentBlock = num

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
						return currentBlock + (60 * 60 * 8 * 365)

					return await contract.methods.bonusEndBlock.call().call()
				}
	
				let getRewardPerBlock = async () => {
					// the variable is called 'cakePerBlock' insteod of 'rewardPerBlock'
					if (address === addr["cake_pool"])
						return 10
	
					return await contract.methods.rewardPerBlock.call().call()
				}
	
				Promise.all([getBonusEndBlock(), getRewardPerBlock()]).then((values) => {
					bonusEndBlock = values[0]
					rewardPerBlock = values[1]
					blockDiff = bonusEndBlock - currentBlock
	
					console.log(`currentBlock: ${currentBlock}`)
					console.log(`bonusEndBlock: ${bonusEndBlock}`)
					console.log(`rewardPerBlock: ${rewardPerBlock}`)
					console.log(`blockDiff: ${blockDiff}`)
	
					$.ajax({
	
						url: `https://api.bscscan.com/api?module=account&action=tokenbalance&contractaddress=${addr['cake_token']}&address=${address}&tag=latest`,
						dataType: 'json',
						async: false,
						success: function (data) {
							cakeAmountInContract = data['result']
							console.log(`cakeAmountInContract: ${cakeAmountInContract}`)
						}
					})
	
					$.ajax({
						url: `${priceURL}?ids=${coingecko_ids[addr['cake_token']]}&vs_currencies=USD`,
						dataType: 'json',
						async: false,
						success: function (data) {
							cakePrice = data['pancakeswap-token']['usd']
							console.log(`cakePrice: ${cakePrice}`)
						}
					})
	
					$.ajax({
						url: `${priceURL}?ids=${coingecko_ids[rewardToken]}&vs_currencies=USD`,
						dataType: 'json',
						async: false,
						success: function (data) {
							rewardTokenPrice = data[coingecko_ids[rewardToken]]['usd']
							console.log(`rewardTokenPrice (${coingecko_ids[rewardToken]}): ${rewardTokenPrice}`)
						}
					})
	
					const APY =
						(rewardPerBlock * rewardTokenPrice)
						/
						(cakeAmountInContract * cakePrice)
						*
						(address === addr["blk_pool"] ? 1000000000000 / 3: 1)
						*
						(365 * 60 * 60 * 8)
	
					console.log(APY)
					return APY
				});
			}
		})
	})
}

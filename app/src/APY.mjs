import { addr, coingecko_ids } from "./crypto_helper.mjs"

export async function getAPY(web3, address, rewardToken) {

	const currentBlock = await web3.eth.getBlockNumber()
	let bonusEndBlock
	let rewardPerBlock = 0
	let rewardTokenPrice = 0
	let cakeAmountInContract
	let cakePrice
	let blockDiff // bonusEndBlock - currentBlock

	$.getJSON(`https://api.bscscan.com/api?module=contract&action=getabi&address=${address}`, async (data) => {
		const abi = JSON.parse(data.result)
		const contract = new web3.eth.Contract(abi, address)

		if (address === addr["cake_pool"]) {
			// there is no 'bonusEndBlock' in the CAKE pool
			bonusEndBlock = currentBlock + (60 * 60 * 24 * 365 / 3)
			// the variable is called 'cakePerBlock' insteod of 'rewardPerBlock'
			rewardPerBlock = await contract.methods.cakePerBlock.call().call()

		} else {
			bonusEndBlock = await contract.methods.bonusEndBlock.call().call()
			rewardPerBlock = await contract.methods.rewardPerBlock.call().call()
		}

		blockDiff = bonusEndBlock - currentBlock
	})

	$.getJSON(`https://api.bscscan.com/api?module=account&action=tokenbalance&contractaddress=${addr['cake_token']}&address=${addr['cake_pool']}&tag=latest`).then(
		data => cakeAmountInContract = data['result']
	)

	$.getJSON(`https://api.coingecko.com/api/v3/simple/price?ids=${coingecko_ids[addr['cake_token']]}&vs_currencies=USD`).then(
		data => cakePrice = data['pancakeswap-token']['usd']
	)

	$.getJSON(`https://api.coingecko.com/api/v3/simple/price?ids=${coingecko_ids[rewardToken]}&vs_currencies=USD`).then(
		data => rewardTokenPrice = data[coingecko_ids[rewardToken]]['usd']
	)

	return (
		(
			(blockDiff * web3.utils.fromWei((rewardPerBlock * rewardTokenPrice).toString(), 'ether')) /
			(cakeAmountInContract * cakePrice)
		) * (
			365 /
			(
				(blockDiff * 3) /
				(60 * 60 * 24)
			)
		)
	)
}

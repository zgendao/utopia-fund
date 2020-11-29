import { addr, coingecko_ids } from "./crypto_helper.mjs"

const priceURL = 'https://api.coingecko.com/api/v3/simple/price'

export async function getAPY(web3, address, rewardToken) {
	$.ajaxSetup({
		async: false
	})

	const currentBlock = await web3.eth.getBlockNumber()
	let bonusEndBlock
	let rewardPerBlock
	let rewardTokenPrice
	let cakeAmountInContract
	let cakePrice
	let blockDiff // bonusEndBlock - currentBlock

	$.getJSON(`https://api.bscscan.com/api?module=contract&action=getabi&address=${address}`, function(data){
		const abi = JSON.parse(data['result'])
		const contract = new web3.eth.Contract(abi, address)

		if (address === addr["cake_pool"]) {
			// there is no 'bonusEndBlock' in the CAKE pool
			bonusEndBlock = currentBlock + (60 * 60 * 24 * 365 / 3)
			// the variable is called 'cakePerBlock' insteod of 'rewardPerBlock'
			setTimeout(() => { contract.methods.cakePerBlock.call().call().then(async res => rewardPerBlock = res) }, 5000)
		} else {
			setTimeout(() => { contract.methods.bonusEndBlock.call().call().then(async res => bonusEndBlock = res) }, 5000)
			setTimeout(() => { contract.methods.rewardPerBlock.call().call().then(async res => rewardPerBlock = res) }, 5000)
		}

		blockDiff = bonusEndBlock - currentBlock

		console.log(`bonusEndBlock: ${bonusEndBlock}`)
		console.log(`rewardPerBlock: ${rewardPerBlock}`)
		console.log(`blockDiff: ${blockDiff}`)
	})

	$.getJSON(`https://api.bscscan.com/api?module=account&action=tokenbalance&contractaddress=${addr['cake_token']}&address=${addr['cake_pool']}&tag=latest`).then(
		data => cakeAmountInContract = data['result']
	)

	$.getJSON(`${priceURL}?ids=${coingecko_ids[addr['cake_token']]}&vs_currencies=USD`).then(
		data => cakePrice = data['pancakeswap-token']['usd']
	)

	$.getJSON(`${priceURL}?ids=${coingecko_ids[rewardToken]}&vs_currencies=USD`).then(
		data => rewardTokenPrice = data[coingecko_ids[rewardToken]]['usd']
	)

	return (
		(blockDiff * web3.utils.fromWei((rewardPerBlock * rewardTokenPrice).toString(), 'ether')) /
		(cakeAmountInContract * cakePrice)
	) * (
		365 /
		(
			(blockDiff * 3) /
			(60 * 60 * 24)
		)
	)
}

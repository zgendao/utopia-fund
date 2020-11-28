export async function getAPY(web3, address) {

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
		bonusEndBlock = await contract.methods.bonusEndBlock.call().call()
		rewardPerBlock = await contract.methods.rewardPerBlock.call().call()

		blockDiff = bonusEndBlock - currentBlock
	})

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

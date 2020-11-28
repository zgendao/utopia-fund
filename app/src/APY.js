async function getAPY(contract) {
	let bonusEndBlock = await contract.bonusEndBlock().call()
	let currentBlock
	let rewardPerBlock = await contract.rewardPerBlock().call()
	let rewardTokenPrice
	let cakeAmountInContract
	let cakePrice

	let blockDiff = bonusEndBlock - currentBlock

	let APY = (
		(
			(blockDiff * weiToEther(rewardPerBlock * rewardTokenPrice)) /
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

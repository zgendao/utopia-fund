export async function getAPY(web3, address, rewardToken) {

	const currentBlock = await web3.eth.getBlockNumber()
	let bonusEndBlock
	let rewardPerBlock
	let rewardTokenPrice //missing
	let cakeAmountInContract
	let cakePrice //missing
	let blockDiff // bonusEndBlock - currentBlock

	$.getJSON(`https://api.bscscan.com/api?module=contract&action=getabi&address=${address}`, async (data) => {
		const abi = JSON.parse(data.result)
		const contract = new web3.eth.Contract(abi, address)
		if (address === "0x73feaa1eE314F8c655E354234017bE2193C9E24E"){
			bonusEndBlock = currentBlock + (60*60*24*365/3) //A CAKE poolban nincs bonusEndBlock
			rewardPerBlock = await contract.methods.cakePerBlock.call().call() //És más a változó neve

		}else{
			bonusEndBlock = await contract.methods.bonusEndBlock.call().call()
			rewardPerBlock = await contract.methods.rewardPerBlock.call().call()
		}
		blockDiff = bonusEndBlock - currentBlock
	})

	$.getJSON(`https://api.bscscan.com/api?module=account&action=tokenbalance&contractaddress=0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82&address=${address}&tag=latest`, async (data) => {
		cakeAmountInContract = JSON.parse(data.result)
	})

	/*
	* Itt jöhetnek a token árak 
	*/

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

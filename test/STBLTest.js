const oracleContract = artifacts.require("EthPriceOracle")
const tokenContract = artifacts.require("STBL")

const secrets = require("../secrets.json")

let price = 0

contract("EthPriceOracle", (accounts) => {
	let oracleInstance

	before("before", async () =>
		oracleInstance = await oracleContract.new()
	)

	it("should be able to get latest price", async () => {
			price = await oracleInstance.getLatestPrice()
			assert(price !== 0, "Price can't be zero")
		}
	)
})

contract("STBL", (accounts) => {
	let tokenInstance

	before("before", async () =>
		tokenInstance = await tokenContract.new("StableToken", "STBL")
	)

	it("should be called 'StableToken'", async () =>
		assert.equal(await tokenInstance.name(), "StableToken")
	)

	it("should have symbol 'STBL'", async () =>
		assert.equal(await tokenInstance.symbol(), "STBL")
	)

	it("should be able to deposit ETH", async () => {
		const result = await tokenInstance.deposit(accounts[1], 1, { from: accounts[0], value: 1 })
		assert.equal(result.receipt.status, true)
		let balance = await tokenInstance.balanceOf(accounts[1])
		assert.equal(balance.toString(), price.toString()) 
	})

	it("should be able to withdraw ETH", async () => {
		const result = await tokenInstance.withdraw(accounts[1], 1)
		assert.equal(result.receipt.status, true)
		let balance = await tokenInstance.balanceOf(accounts[1])
		assert.equal(balance.toString(), (price - 1).toString())
	})
})

const EthPriceOracle = artifacts.require("EthPriceOracle")
const STBL = artifacts.require("STBL")

module.exports = function(deployer) {
	deployer.deploy(EthPriceOracle)
	deployer.deploy(STBL, "StableToken", "STBL")
}
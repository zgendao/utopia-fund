import Web3 from "web3"
import ethPriceOracleArtifact from "../../build/contracts/EthPriceOracle.json"
const secrets = require("../../secrets.json")

const App = {
	web3: null,
	meta: null,

	start: async function() {
		const { web3 } = this

		try {
			// initialize the conract
			this.meta = new web3.eth.Contract(
				ethPriceOracleArtifact.abi,
				secrets.address,
			)

			// get the current price
			const price = await this.meta.methods.getLatestPrice().call()
			// let's print the current price on our webApp
			document.getElementById("message").innerHTML = (price / Math.pow(10, 8)).toFixed(2) + '$'
		} catch (error) {
			console.error(error)
			document.getElementById("message").innerHTML = `<div style="color: red">${error}</div>`
		}
	}
}

window.App = App

window.addEventListener("load", function() {
	if (window.ethereum) { // check if the browser supports web3
		App.web3 = new Web3(window.ethereum) // use MetaMask's provider
		window.ethereum.enable() // get permission to access accounts
	} else // otherwise print an error message
		console.warn("No web3 detected.")

	App.start() // start the webApp
})
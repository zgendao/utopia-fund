// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract EthPriceOracle {
	AggregatorV3Interface internal priceFeed;

	constructor() public {
		/* the constuructor initializes the address of the AggregatorV3Interface
		 * with the contract address of the Chainlink PriceFeed oracle
		 */
		priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
	}
		
	function getLatestPrice() public view returns (uint) {
		/* the "latestRoundData" call is returning multiple values, so
		 * we have to store them in a tuple otherwise we would only get
		 * the first returned element
		 */
		(
			uint80 roundID, 
			int price,
			uint startedAt,
			uint timeStamp,
			uint80 answeredInRound
		) = priceFeed.latestRoundData();

		// we only need the current price info so we only return the price
		return uint(price);
	}
}
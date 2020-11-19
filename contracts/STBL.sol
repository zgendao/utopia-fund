// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./EthPriceOracle.sol";

contract STBL is ERC20 {
	EthPriceOracle internal ethPriceOracle;

	/// @dev We should decide if we need initial supply
	constructor(string memory name, string memory symbol) public
	ERC20(name, symbol)
	{
		ethPriceOracle = new EthPriceOracle();
	}

	/// @notice Gives STBL to the account that calls it, accepts ETH
	function deposit(address _account, uint _amount) public payable {
		require(msg.value == _amount);
		uint stblAmount = 466 * _amount; // * ethPriceOracle.getLatestPrice();
		_mint(_account, stblAmount);
	}

	/// @notice Removes STBL from the account that calls it, sends ETH
	function withdraw(address payable _account, uint _amount) public {
		uint ethAmount = _amount / 466; // / ethPriceOracle.getLatestPrice();
		require(address(this).balance >= ethAmount, "Not enough ether available");
		_account.transfer(ethAmount);
		_burn(_account, _amount);
	}
}
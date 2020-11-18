// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./EthPriceOracle.sol";

contract STBL is ERC20 {

    EthPriceOracle internal ethPriceOracle;

    /// @dev We should decide if we need initial supply
    constructor(string memory name, string memory symbol) public
    ERC20(name, symbol)
    {
        _mint(address(this), 100000 * 10 ** uint(decimals()));
        ethPriceOracle = new EthPriceOracle();
    }

    /// @notice Gives STBL to the account that calls it, accepts ETH
    /// @dev Should use transferFrom instead of _mint if we want to work with fixed supply
    function deposit(uint _amount) public payable {
        require(msg.value == _amount);
        uint stblAmount = _amount * ethPriceOracle.getLatestPrice();
        require(balanceOf(address(this)) >= stblAmount, "Not enough tokens available");
        //transferFrom(address(this), msg.sender, stblAmount);
        _mint(msg.sender, stblAmount);
    }

    /// @notice Removes STBL from the account that calls it, sends ETH
    /// @dev Should use transferFrom instead of _burn if we want to work with fixed supply
    function withdraw(uint _amount) public {
        uint ethAmount = _amount / ethPriceOracle.getLatestPrice();
        require(address(this).balance >= ethAmount, "Not enough ether available");
        msg.sender.transfer(ethAmount);
        //transferFrom(msg.sender, address(this), _amount);
        _burn(msg.sender, _amount);
    }
    
}
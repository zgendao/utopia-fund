// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./token/BEP20Mintable.sol";
import "./Strategy.sol";

/// @title A vault that holds PancakeSwap Cake tokens
contract Vault is Ownable {

    IBEP20 private cakeToken;
    BEP20Mintable private yCakeToken;
    address private strategyAddress;
    address private strategist;

    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event ChangedCakeAddress(address newAddress);
    event ChangedStrategy(address newAddress);
    event ChangedStrategist(address strategist);

    /// @notice Only the strategist has permissions to reinvest, harvest or set the strategy
    modifier onlyStrategist() {
        require(msg.sender == strategist, "!strategist");
        _;
    }

    constructor() {
        strategist = msg.sender;
        cakeToken = IBEP20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
        yCakeToken = new BEP20Mintable("yCake Token", "yCake");
        yCakeToken.mint(address(this), 100000 * 10 ** yCakeToken.decimals());
    }

    /// @notice Approves the active Strategy contract to manage funds in Vault and vice versa
    function approveStrategy() external onlyStrategist {
        cakeToken.approve(strategyAddress, uint256(-1));
        Strategy(strategyAddress).acceptTokens(address(cakeToken), uint256(-1));
    }

    /// @notice Accepts cakes, mints yCakes
    /// @dev Minting yCake should be possible, since the contract should have the MINTER_ROLE
    function deposit(uint256 _amount) public {
        require(_amount > 0, "Only a positive value can be deposited");
        require(cakeToken.allowance(msg.sender, address(this)) >= _amount, "Cake allowance not sufficient");
        require(cakeToken.balanceOf(msg.sender) >= _amount, "Sender does not have enough funds");
        cakeToken.transferFrom(msg.sender, address(this), _amount);
        yCakeToken.mint(msg.sender, _amount);
        sendToStrategy(_amount);
        emit Deposit(msg.sender, _amount);
    }

    /// @notice Burns yCakes, gives back Cakes
    /// @dev Burning yCake should be possible, since the contract should have the MINTER_ROLE
    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Only a positive value can be withdrawn");
        require(yCakeToken.allowance(msg.sender, address(this)) >= _amount, "yCake allowance not sufficient");
        require(yCakeToken.balanceOf(msg.sender) >= _amount, "Sender does not have enough funds");
        getFromStrategy(_amount);
        yCakeToken.burn(msg.sender, _amount);
        cakeToken.transferFrom(address(this), msg.sender, _amount);     // FAIL: 'BEP20: transfer amount exceeds allowance'
        emit Withdraw(msg.sender, _amount);
    }

    /// @notice Withdraws all the cakes of the sender
    function withdrawAll() public {
        withdraw(yCakeToken.balanceOf(msg.sender));
    }

    /// @notice Forwards the deposited amount to the Strategy contract
    function sendToStrategy(uint256 _amount) internal {
        Strategy(strategyAddress).deposit(address(cakeToken), _amount);
    }

    /// @notice Gets the tokens from the Strategy contract
    function getFromStrategy(uint256 _amount) internal {
        cakeToken.transferFrom(strategyAddress, address(this), _amount);
    }

    /// @notice Changes the address of the Strategy token. Use in case it gets changed in the future
    function setStrategy(address _newAddress) external onlyOwner {
        strategyAddress = _newAddress;
        emit ChangedStrategy(_newAddress);
    }

    /// @notice Changes the address of the Cake token. Use in case it gets changed in the future
    function setCakeAddress(address _newAddress) external onlyOwner {
        cakeToken = IBEP20(_newAddress);
        emit ChangedCakeAddress(_newAddress);
    }

    /// @notice Changes the address of the strategist
    function setStrategistAddress(address _newAddress) external onlyStrategist {
        strategist = _newAddress;
        emit ChangedStrategist(_newAddress);
    }

    /// @notice Gets the yCake balance of the depositor
    /// @return The amount of yCakes the depositor has
    function getBalance() external view returns (uint256) {
        return yCakeToken.balanceOf(msg.sender);
    }

    /// @notice Gets the yCake balance of _account
    /// @return The amount of yCakes _account has
    function getBalanceOf(address _account) public view returns (uint256) {
        return yCakeToken.balanceOf(_account);
    }

}
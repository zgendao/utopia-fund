// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./token/BEP20Mintable.sol";
import "./Strategy.sol";

/// @title A vault that holds PancakeSwap Cake tokens
contract Vault is Ownable {

    IBEP20 private cakeToken;
    BEP20Mintable private yCakeToken;
    address private strategyAddress;

    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);

    constructor() {
        cakeToken = IBEP20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
        yCakeToken = new BEP20Mintable("yCake Token", "yCake");
        yCakeToken.mint(address(this), 100000 * 10 ** yCakeToken.decimals());
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
        cakeToken.transferFrom(address(this), msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /// @notice Withdraws all the cakes of the sender
    function withdrawAll() public {
        withdraw(yCakeToken.balanceOf(msg.sender));
    }

    /// @notice Forwards the deposited amount to the Strategy contract
    function sendToStrategy(uint256 _amount) internal {
        cakeToken.approve(strategyAddress, 0);  // Security reasons
        cakeToken.approve(strategyAddress, _amount);
        cakeToken.transferFrom(address(this), strategyAddress, _amount);    // Fail with error 'BEP20: transfer amount exceeds allowance' (én -> vault)
                                                                            // Possibly approve nem azt approve-olja, akit kell
                                                                            // Lehet az a sender (én), nem a contractot engedélyezi?
        Strategy(strategyAddress).acceptTokens(address(cakeToken), _amount);
    }

    /// @notice Gets the tokens from the Strategy contract
    function getFromStrategy(uint256 _amount) internal {
        cakeToken.transferFrom(strategyAddress, address(this), _amount);
    }

    /// @notice Changes the address of the Strategy token. Use in case it gets changed in the future
    function changeStrategyAddress(address _newAddress) public onlyOwner {
        strategyAddress = _newAddress;
    }

    /// @notice Changes the address of the Cake token. Use in case it gets changed in the future
    function changeCakeAddress(address _newAddress) public onlyOwner {
        cakeToken = IBEP20(_newAddress);
    }

    /// @notice Gets the yCake balance of the depositor
    /// @return The amount of yCakes the depositor has
    function getBalance() public view returns (uint256) {
        return yCakeToken.balanceOf(msg.sender);
    }

    /// @notice Gets the yCake balance of _account
    /// @return The amount of yCakes _account has
    function getBalanceOf(address _account) public view returns (uint256) {
        return yCakeToken.balanceOf(_account);
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./token/IBEP20.sol";

contract Strategy {

    /// @notice Approves Vault to manage the amount of tokens it sent to Strategy
    /// @param _wot The address of the BEP20 token the function accepted
    /// @param _amount The amount of tokens it accepted
    function acceptTokens(address _wot, uint256 _amount) external {
        IBEP20(_wot).approve(msg.sender, _amount);
    }

    /// @notice Gets tokens from Vault and invests them into a pool
    /// @param _wot The address of the BEP20 token the function accepted
    /// @param _amount The amount of tokens it accepted
    function deposit(address _wot, uint256 _amount) public {
        // TODO: check if the caller is the vault
        IBEP20(_wot).transferFrom(msg.sender, address(this), _amount);
        // TODO: forward to pool
    }

}
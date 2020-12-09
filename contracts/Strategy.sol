// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./token/IBEP20.sol";

contract Strategy {

    /// @notice Approves Vault to manage the amount of tokens it just got
    /// @param _wot The address of the BEP20 token the function accepted
    /// @param _amount The amount of tokens it accepted
    function acceptTokens(address _wot, uint256 _amount) public {
        IBEP20(_wot).approve(msg.sender, _amount);
    }
}
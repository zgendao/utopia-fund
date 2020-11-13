// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title A simple ERC20 token
contract StakingToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory name, string memory symbol)
    ERC20(name, symbol)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /// @notice Mint amount tokens to account account
    function mint(address account, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender));
        _mint(account, amount);
    }

    /// @notice Burn amount tokens from account account
    function burn(address account,uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender));
        _burn(account, amount);
    }
}
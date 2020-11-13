// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./erc20/StakingToken.sol";

/// @title Makes staking tokens possible and keeps track of them
contract Staking is StakingToken {
    using SafeMath for uint;

    uint internal MAX_UINT = 2**256 - 1;
    // The addresses of the stakeholders
    address[] internal stakeholders;
    // Stakes of stakeholders
    mapping(address => amounts) internal stakes;
    // Stake amounts struct
    struct amounts {
        uint ethStake;
        uint stkStake;
    }
    // The number of last block
    uint lastBlock;

    constructor(string memory name, string memory symbol)
    StakingToken(name, symbol) {
        /// Initial supply - the contract's property
        _mint(address(this), 1000 * 10 ** uint(decimals()));
    }

    /// @notice Check if the given address is a stakeholder
    function isStakeholder(address _address) public view returns (bool, uint) {
        for (uint i = 0; i < stakeholders.length; i++) {
            if (stakeholders[i] == _address)
                return (true, i);
        }
        return (false, MAX_UINT);
    }

    /// @notice Adds a stakeholder
    function _addStakeholder(address _address) private {
        (bool _isStakeholder, ) = isStakeholder(_address);
        if (!_isStakeholder)
            stakeholders.push(_address);
    }

    /// @notice Removes a stakeholder
    function _removeStakeholder(address _address) private {
        (bool _isStakeholder, uint _index) = isStakeholder(_address);
        if (_isStakeholder) {
            stakeholders[_index] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }

    /// @notice Gets the list of stakeholders
    /// @return The list of addresses that have stakes
    function getStakeholders() public view returns (address[] memory) {
        return stakeholders;
    }

    /// @notice Gets the staked amounts of an address
    /// @return The staked amount of the address in (eth, stk) order
    function getStakeOf(address _address) public view returns (uint, uint) {
       return (stakes[_address].ethStake, stakes[_address].stkStake);
    }

    /// @notice Gets the staked amount of ETH of an address
    /// @return The staked amount of ETH of the address
    function getEthStakeOf(address _address) public view returns (uint) {
       return stakes[_address].ethStake;
    }

    /// @notice Gets the staked amount of STK of an address
    /// @return The staked amount of STK of the address
    function getStkStakeOf(address _address) public view returns (uint) {
       return stakes[_address].stkStake;
    }

    /// @notice Gets the total amount of stakes in the contract
    /// @dev ETH stake could be calculated just like the STK stake, but getEthBalance() is probably cheaper
    /// @return The total staked amount in (eth, stk) order
    function getAllStakes() public view returns (uint, uint) {
        uint _ethStake = getEthBalance();
        uint _stkStake = 0;
        for (uint i = 0; i < stakeholders.length; i++) {
            // _ethStake = _ethStake.add(stakes[stakeholders[i]].ethStake);
            _stkStake = _stkStake.add(stakes[stakeholders[i]].stkStake);
        }
        return (_ethStake, _stkStake);
    }

    /// @notice Gets the ETH balance of the contract
    function getEthBalance() public view returns (uint) {
        return address(this).balance;
    }

    /// @notice Gets the STK balance of the contract
    function getStkBalance() public view returns (uint) {
        return balanceOf(address(this));
    }

    /// @notice Creates an ETH stake for the account that calls it
    function createEthStake(uint _amount) public payable {
        require(msg.value == _amount);
        stakes[msg.sender].ethStake = stakes[msg.sender].ethStake.add(_amount);
        if (stakes[msg.sender].ethStake == _amount)
            _addStakeholder(msg.sender);
    }

    /// @notice Removes an ETH stake from the account that calls it
    function removeEthStake(uint _amount) public payable {
        require(address(this).balance >= _amount);
        msg.sender.transfer(_amount);
        stakes[msg.sender].ethStake = stakes[msg.sender].ethStake.sub(_amount);
        if (stakes[msg.sender].ethStake == 0)
            _removeStakeholder(msg.sender);
    }

    /// @notice Creates an STK stake for the account that calls it and initiates rewarding
    function createStkStake(uint _amount) public {
        if (isNewBlock()) {
            _distributeRewards();
            lastBlock = block.number;
        }
        _burn(msg.sender, _amount);
        stakes[msg.sender].stkStake = stakes[msg.sender].stkStake.add(_amount);
        if (stakes[msg.sender].stkStake == _amount)
            _addStakeholder(msg.sender);
    }

    /// @notice Removes an STK stake from the account that calls it
    function removeStkStake(uint _amount) public {
        stakes[msg.sender].stkStake = stakes[msg.sender].stkStake.sub(_amount);
        if (stakes[msg.sender].stkStake == 0)
            _removeStakeholder(msg.sender);
        _mint(msg.sender, _amount);
    }

    /// @notice Checks if a new block was issued
    function isNewBlock() internal view returns (bool) {
        return lastBlock < block.number ? true : false;
    }

    /// @notice Distribute rewards to STK stakeholders
    function _distributeRewards() private {
        for (uint i = 0; i < stakeholders.length; i++)
            if (stakes[stakeholders[i]].stkStake != 0) {
                uint reward = stakes[stakeholders[i]].stkStake.div(100);
                _mint(stakeholders[i], reward);
            }
    }
}
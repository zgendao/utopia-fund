// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface PoolInterface {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function pendingReward(address _user) external view returns (uint256);
}

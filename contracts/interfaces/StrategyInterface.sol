// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface StrategyInterface {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function withdrawAll() external returns (uint256, uint256, uint256);
    function harvest() external returns (uint256, uint256);
    function getBalance() external view returns (uint256);
}
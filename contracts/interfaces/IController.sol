// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IController {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function withdrawAll() external returns(uint256);
    function harvest() external;
    function changeStrategy(address _newStrategy) external;
    function getBalance() external view returns(uint256);
}
// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface CakePoolInterface {
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    //CAKE Pool: _pid = 0, _user = address(this)
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);
}
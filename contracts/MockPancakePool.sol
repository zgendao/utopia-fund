// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./token/IBEP20.sol";
contract MockPancakePool {
    address internal owoAddress = 0x28d4f491053F2d13145082418b93aDcE0a29023F;
    IBEP20 internal owoToken = IBEP20(0x28d4f491053F2d13145082418b93aDcE0a29023F);

    function enterStaking(uint256 _amount) external {
        owoToken.transferFrom(msg.sender, address(this), _amount);
    }

    function leaveStaking(uint256 _amount) external {
        owoToken.transfer(msg.sender, (_amount + 2000000000000000000));
    }

    function pendingCake(uint256 _pid, address _user) external view returns (uint256){
        return 2000000000000000000;
    }
}
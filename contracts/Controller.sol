// SPDX-License-Identifier: MIT
/// @author Józsa Erik

pragma solidity >=0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controller is Ownable {
    address pool;


    function updatePoolAddress (address _address) external onlyOwner {
        pool = _address;
    }

    function getPoolAddress ()external view returns(address){
        return pool;
    }
}
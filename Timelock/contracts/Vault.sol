// SPDX-License-Identifier: MIT
/// @author Józsa Erik

pragma solidity >=0.6.0;

import "./Ownable.sol";

contract Vault is Ownable {
    address tellerAddress = 0x0000000000000000000000000000000000000000;


    /**
     * @dev beállítja a tellerAddress-t a megadott address-re
     *
     * NOTE: csak egyszer működik és a deploy után meg kell hívni
     * mert addig a contract nem működik! Csak az tudja meghívni aki ezt
     * a contract-ot deploy-olta.
     * @param _newAdress Ez minden képpen a Teller contract adress-e legyen
     */
    function setTellerAddress(address _newAdress) external onlyOwner {
        require(tellerAddress == 0x0000000000000000000000000000000000000000);
        tellerAddress = _newAdress;
    }

     /**
     * @dev a Teller contract "withdraw" függvénye ezt hívja meg.
     * A kapott összeget elküldi a Teller contract-nak. Csak a beállított
     * Teller contract tudja meghívni.
     * @param _amount A levenni kívánt összeg.
     * @return Igaz érték ha sikeres. Ha nem akkor error. 
     */
    function withdrawal(uint _amount) external returns(bool) {
        require(msg.sender == tellerAddress);
        msg.sender.transfer(_amount);
        return true;
    }

    /**
     * @return A contracton tárolt teljes összeg
     */
    function balanceOf() external view returns(uint) {
    return address(this).balance;
    }
}
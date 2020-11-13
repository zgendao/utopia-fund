// SPDX-License-Identifier: MIT
/// @author Józsa Erik

pragma solidity >=0.6.0;

import "./Ownable.sol";

contract VaultInterface {
    function withdrawal(uint) external returns(bool) {}
}

contract Teller is Ownable {
    mapping(address => uint) balances;
    mapping(address => uint) timeTracker;
    address vaultAddress = 0x0000000000000000000000000000000000000000;
    VaultInterface vault;

    /**
     * @dev ellenőrzi, hogy az utolsó tranzakció óta létrejött-e 10 blokk
     */
    modifier lockCheck(){
        require(timeTracker[msg.sender] <= (block.number - 10));
        _;
    }

    /**
     * @dev beállítja a vaultAddress-t a megadott address-re
     *
     * NOTE: csak egyszer működik és a deploy után meg kell hívni
     * mert addig a contract nem működik! Csak az tudja meghívni aki ezt
     * a contract-ot deploy-olta.
     * @param _address Ez minden képpen a Vault contract adress-e legyen 
     */
    function setVaultAddress (address _address) external onlyOwner {
        require(vaultAddress == 0x0000000000000000000000000000000000000000);
        vault = VaultInterface(_address);
        vaultAddress = _address;
    }

    /**
     * @dev A tranzakcióban kapott összeget elküldi a Vault-nak
     * és az értékét hozzá adja a küldő balance-ához.
     */
    function invest() external payable lockCheck {
        payable(vaultAddress).transfer(msg.value);
        balances[msg.sender] += msg.value;
    }

    /**
     * @dev Ellenőrzi hogy a kivenni kívánt érték nem haladja-e meg a
     * hívó balance-át. Utána a Vaultal végrehajtat egy tranzakciót amivel
     * lekéri az összeget majd ha az sikeres elküldi a hívónak.
     */
    function withdraw(uint _amount) external lockCheck {
        require(balances[msg.sender] >= _amount);

        if(vault.withdrawal(_amount)){
            msg.sender.transfer(_amount);
            balances[msg.sender] -= _amount;
        } 
    }

    /**
     * @return A hívó balance-án lévő összeg
     */
    function getBalance() external view returns(uint){
        return balances[msg.sender];
    }

}

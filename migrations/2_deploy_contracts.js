const Controller = artifacts.require("Controller");
const CakeVault = artifacts.require("CakeVault");
const PancakeStrategy = artifacts.require("PancakeCakeStrategy");
const Strategy = artifacts.require("PancakeStrategy"); //["reward token","köztes token","staking token"]

// Constructor arguments need to be added
module.exports = function(deployer) {
  deployer.then(async () => {
    //Main
    /*await deployer.deploy(Controller, "0xD4bFdf99697eA9D2E611207868C57f2fA9c5483c");
    await deployer.deploy(CakeVault, "0xD4bFdf99697eA9D2E611207868C57f2fA9c5483c", Controller.address);
    await deployer.deploy(Strategy, 
    CakeVault.address, // Vault Address
    Controller.address, // Controller Addrress
    "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82", // Stake Token Addrress
    "0x624ef5C2C6080Af188AF96ee5B3160Bb28bb3E02", // Pool Addrress
    "0x233d91A0713155003fc4DcE0AFa871b508B3B715", // Reward token Address
    "0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F", // Exchange Address
    ["0x233d91A0713155003fc4DcE0AFa871b508B3B715","0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c","0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82"] // Exchange Path
    );*/

    //Teszt
    /*
    await deployer.deploy(Controller, "0xF67fFA19D50D9B366D7d645FE5897614C5Ed9A79");
    await deployer.deploy(CakeVault, "0xF67fFA19D50D9B366D7d645FE5897614C5Ed9A79", Controller.address);
    await deployer.deploy(PancakeStrategy, CakeVault.address, Controller.address, 
      "0x28d4f491053F2d13145082418b93aDcE0a29023F", "0x3A16e1385f7D94b49435d091041FfD742F70868B");*/
    
  });
};

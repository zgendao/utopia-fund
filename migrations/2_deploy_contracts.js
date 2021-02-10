const Pool = artifacts.require("MockPancakePool");
const Controller = artifacts.require("Controller");
const CakeVault = artifacts.require("CakeVault");
const PancakeStrategy = artifacts.require("PancakeCakeStrategy");
//const Strategy = artifacts.require("PancakeStrategy"); //["reward token","köztes token","staking token"]

// Constructor arguments need to be added
module.exports = function(deployer) {
  deployer.then(async () => {
    await deployer.deploy(Pool);
    await deployer.deploy(Controller, "0xF67fFA19D50D9B366D7d645FE5897614C5Ed9A79");
    await deployer.deploy(CakeVault, "0xF67fFA19D50D9B366D7d645FE5897614C5Ed9A79", Controller.address);
    await deployer.deploy(PancakeStrategy, CakeVault.address, Controller.address, 
    "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82", Pool.address);
  });
};
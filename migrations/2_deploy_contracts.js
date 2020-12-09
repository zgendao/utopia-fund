const vault = artifacts.require("Vault");
const controller = artifacts.require("Controller");
const strategy = artifacts.require("Strategy");

module.exports = function(deployer) {
  deployer.deploy(vault);
  deployer.deploy(controller);
  deployer.deploy(strategy);
};
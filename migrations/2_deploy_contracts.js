const vault = artifacts.require("Vault");
const controller = artifacts.require("Controller");

module.exports = function(deployer) {
  deployer.deploy(vault);
  deployer.deploy(controller);
};
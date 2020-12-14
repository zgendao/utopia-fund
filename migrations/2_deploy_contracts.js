const vault = artifacts.require("Vault");
const strategy = artifacts.require("Strategy");

module.exports = function(deployer) {
  deployer.deploy(vault);
  deployer.deploy(strategy);
};
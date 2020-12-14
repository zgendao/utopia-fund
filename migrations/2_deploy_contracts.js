const vault = artifacts.require("Vault");
const strategy = artifacts.require("Strategy");

// Constructor arguments need to be added
module.exports = function(deployer) {
  deployer.deploy(vault);
  deployer.deploy(strategy);
};
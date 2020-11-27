const vault = artifacts.require("Vault");

module.exports = function(deployer) {
  deployer.deploy(vault);
};

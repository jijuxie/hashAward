const HashAward = artifacts.require("HashAward");

module.exports = function(deployer) {
  deployer.deploy(HashAward);
};

var SDT = artifacts.require("./SDT.sol");

module.exports = function(deployer) {
  deployer.deploy(SDT, 1000);
};

var SDT = artifacts.require("./SDT.sol");

module.exports = function(deployer) {
  deployer.deploy(SDT, 700*10**6);
};

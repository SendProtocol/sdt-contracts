const SDT = artifacts.require('./SDT.sol');
const TokenSale = artifacts.require('./TokenSale.sol');
const TokenVesting = artifacts.require('./TokenVesting.sol');
const math = require('mathjs');

module.exports = function(deployer) {
  let accounts = web3.eth.accounts;
  let currentDate = math.floor(Date.now() / 1000)
  deployer.deploy(TokenSale, currentDate - 1, currentDate + 1000, accounts[5], currentDate + 100);
  deployer.deploy(TokenVesting);
};

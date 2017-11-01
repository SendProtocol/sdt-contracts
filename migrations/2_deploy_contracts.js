const SDT = artifacts.require('./SDT.sol');
const TokenSale = artifacts.require('./TokenSale.sol');
const math = require('mathjs');

module.exports = function(deployer, accounts) {
	let currentDate = math.floor(Date.now() / 1000)
	deployer.deploy(TokenSale, currentDate - 1, currentDate + 1000, 0x2, 0x3, 0x4, 0x5, 0x6, currentDate + 1000, currentDate + 100);
};

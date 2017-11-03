const SDT = artifacts.require('./SDT.sol');
const TokenSale = artifacts.require('./TokenSale.sol');
const math = require('mathjs');

module.exports = function(deployer) {
	let accounts = web3.eth.accounts;
	let currentDate = math.floor(Date.now() / 1000)
	console.log(web3.eth.accounts);
	deployer.deploy(TokenSale, currentDate - 1, currentDate + 1000, accounts[5], accounts[4], accounts[3], accounts[2], accounts[1], currentDate + 1000, currentDate + 100);
};

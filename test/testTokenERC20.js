'use strict';

const SDT = artifacts.require('./SDT.sol');
const assertJump = require('./helpers/assertJump');
const math = require('mathjs');

function amount(a){
	return a*math.pow(10,18);
}

contract('SDT', function(accounts) {

	it('should return the correct totalSupply after construction', async function() {
		let token = await SDT.new(1);
		let totalSupply = await token.totalSupply();

		assert.equal(totalSupply, amount(1));
	});
	
	it('should return correct balances after transfer', async function(){
		let token = await SDT.new(2);
		await token.transfer(accounts[1], amount(1));

		let firstAccountBalance = await token.balanceOf(accounts[0]);
		assert.equal(firstAccountBalance, amount(1));

		let secondAccountBalance = await token.balanceOf(accounts[1]);
		assert.equal(secondAccountBalance, amount(1));
	});

	it('should throw an error when trying to transfer more than balance', async function() {
		let token = await SDT.new(1);
		try {
			await token.transfer(accounts[1], amount(2));
			assert.fail('should have thrown before');
		} catch(error) {
			assertJump(error);
		}
	});

	it('should throw an error when trying to transfer to 0x0', async function() {
		let token = await SDT.new(100);
		try {
			await token.transfer(0x0, amount(1));
			assert.fail('should have thrown before');
		} catch(error) {
			assertJump(error);
		}
	});

	it('should return the correct allowance amount after approval', async function() {
		let token = await SDT.new(100);
		await token.approve(accounts[1], amount(1));
		let allowance = await token.allowance(accounts[0], accounts[1]);

		assert.equal(allowance, amount(1));
	});

	it('should return correct balances after transfering from another account', async function() {
		let token = await SDT.new(100);
		await token.approve(accounts[1], amount(100));
		await token.transferFrom(accounts[0], accounts[2], amount(100), {from: accounts[1]});

		let balance0 = await token.balanceOf(accounts[0]);
		assert.equal(balance0, 0);

		let balance1 = await token.balanceOf(accounts[2]);
		assert.equal(balance1, amount(100));

		let balance2 = await token.balanceOf(accounts[1]);
		assert.equal(balance2, 0);
	});

	it('should throw an error when trying to transfer more than allowed', async function() {
		let token = await SDT.new(100);
		await token.approve(accounts[1], amount(99));
		try {
			await token.transferFrom(accounts[0], accounts[2], amount(100), {from: accounts[1]});
			assert.fail('should have thrown before');
		} catch (error) {
			assertJump(error);
		}
	});

	it('should throw an error when trying to transferFrom more than _from has', async function() {
		let token = await SDT.new(100);
		let balance0 = await token.balanceOf(accounts[0]);
		await token.approve(accounts[1], amount(100));
		try {
			await token.transferFrom(accounts[0], accounts[2], balance0+1, {from: accounts[1]});
			assert.fail('should have thrown before');
		} catch (error) {
			assertJump(error);
		}
	});

	describe('validating allowance updates to spender', function() {
		let preApproved;
		let token;

		it('should start with zero', async function() {
			token = await SDT.new(100);
			preApproved = await token.allowance(accounts[0], accounts[1]);
			assert.equal(preApproved.valueOf(), 0);
		});

		it('should increase by 50 then decrease by 10', async function() {
			await token.increaseApproval(accounts[1], 50);
			let postIncrease = await token.allowance(accounts[0], accounts[1]);
			assert.equal(preApproved.plus(50).valueOf(), postIncrease.valueOf());
			await token.decreaseApproval(accounts[1], 10);
			let postDecrease = await token.allowance(accounts[0], accounts[1]);
			assert.equal(postIncrease.minus(10), postDecrease.valueOf());
		});
	});

	it('should increase by 50 then set to 0 when decreasing by more than 50', async function() {
		let token = await SDT.new(100);
		await token.approve(accounts[1], 50);
		await token.decreaseApproval(accounts[1], 60);
		let postDecrease = await token.allowance(accounts[0], accounts[1]);
		assert.equal(postDecrease, 0);
	});

	it('should throw an error when trying to transfer to 0x0', async function() {
		let token = await SDT.new(100);
		try {
			await token.transfer(0x0, 100);
			assert.fail('should have thrown before');
		} catch(error) {
			assertJump(error);
		}
	});

	it('should throw an error when trying to transferFrom to 0x0', async function() {
		let token = await SDT.new(100);
		await token.approve(accounts[1], 100);
		try {
			await token.transferFrom(accounts[0], 0x0, 100, {from: accounts[1]});
			assert.fail('should have thrown before');
		} catch(error) {
			assertJump(error);
		}
	});

	it('should be possible to sign with exchange rate', async function() {
		let referenceId = 1;
		let exchangeRate = 1;
		let token = await SDT.new(100);
		await token.verify(accounts[1]);
		await token.approve(accounts[1], amount(100));
		await token.verifiedTransferFrom(
			accounts[0], 
			accounts[2], 
			amount(99), 
			referenceId, 
			exchangeRate, 
			amount(1), 
			{from: accounts[1]}
		);

		let balance0 = await token.balanceOf(accounts[0]);
		assert.equal(balance0, 0);

		let balance1 = await token.balanceOf(accounts[2]);
		assert.equal(balance1, amount(99));

		let balance2 = await token.balanceOf(accounts[1]);
		assert.equal(balance2, amount(1));
	});

	it('should fail if exchange rate is 0', async function() {
		let referenceId = 1;
		let exchangeRate = 0;
		let token = await SDT.new(100);
		await token.verify(accounts[1]);
		await token.approve(accounts[1], amount(100));

		try {
			await token.verifiedTransferFrom(
				accounts[0], 
				accounts[2], 
				amount(99), 
				referenceId, 
				exchangeRate, 
				amount(1), 
				{from: accounts[1]}
			);
			assert.fail('should have thrown before');
		} catch(error) {
			assertJump(error);
		}
	});

	it('should fail if unverified', async function() {
		let referenceId = 1;
		let exchangeRate = 1;
		let token = await SDT.new(100);
		await token.approve(accounts[1], amount(100));

		try {
			await token.verifiedTransferFrom(
				accounts[0], 
				accounts[2], 
				amount(99), 
				referenceId, 
				exchangeRate, 
				amount(1), 
				{from: accounts[1]}
			);
			assert.fail('should have thrown before');
		} catch(error) {
			assertJump(error);
		}
	});

});

'use strict';

const SDT = artifacts.require('./SDT.sol');
const assertJump = require('./helpers/assertJump');

function amount(_a){
	let a = _a * (10 ** 18);
	return a;
}

contract('SDT', function(accounts) {
	let token;
	let futureDate = new Date().valueOf() + 3600;
	let pastDate = 1;


	describe('escrow basic flow', function() {
		let referenceId = 1;
		let referenceIdTwo = 2;
		let valueToApprove = 100;
		let fee = 1;
		let exchangeRate = 0;

		it('should lock amount + fee', async function() {
			token = await SDT.new(1);
			await token.approveLockedTransfer(
				accounts[1], 
				referenceId, 
				valueToApprove, 
				fee, 
				futureDate
			);
			let locked = await token.lockedBalanceOf(accounts[0]);
			assert.equal(locked, valueToApprove + fee);
			let balance = await token.balanceOf(accounts[0]);
			assert.equal(balance, amount(1) - (valueToApprove + fee));
		});

		it('should fail if trying to use the same keys', async function() {
			try {
				await token.approveLockedTransfer(
					accounts[1], 
					referenceId, 
					valueToApprove, 
					fee, 
					futureDate
				);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});

		it('should fail if trying to allow more than balance', async function() {
			try {
				await token.approveLockedTransfer(
					accounts[1], 
					referenceIdTwo, 
					amount(1), 
					fee, 
					futureDate
				);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});

		it('should fail if not enough balance to pay fee', async function() {
			try {
				await token.approveLockedTransfer(
					accounts[1], 
					referenceIdTwo, 
					amount(1) - (valueToApprove + fee), 
					fee, 
					futureDate
				);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});

		it('should fail if no verified sets an exchange rate', async function() {
			try {
				await token.executeLockedTransfer(
					accounts[0], 
					accounts[2], 
					referenceId, 
					fee, 
					{from: accounts[1]}
				);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});	

		it('should be possible to spend locked allowance', async function() {
			await token.executeLockedTransfer(
				accounts[0], 
				accounts[2], 
				referenceId, 
				0, 
				{from: accounts[1]}
			);
			let locked = await token.lockedBalanceOf(accounts[0]);
			assert.equal(locked, 0);
			let balanceSender = await token.balanceOf(accounts[0]);
			assert.equal(balanceSender, amount(1) - 101);
			let balanceRecipient = await token.balanceOf(accounts[2]);
			assert.equal(balanceRecipient, 100);
			let balanceAuthority = await token.balanceOf(accounts[1]);
			assert.equal(balanceAuthority, 1);
		});	

		it('should fail if exchange rate not set', async function() {
			await token.approveLockedTransfer(
				accounts[0], 
				referenceId, 
				valueToApprove, 
				0, 
				futureDate, 
				{from: accounts[2]}
			);
			try {
				await token.executeLockedTransfer(
					accounts[2], 
					accounts[3], 
					referenceId, 
					0
				);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});	

		it('should be possible to set exchange rate if verified', async function() {
			await token.executeLockedTransfer(
				accounts[2], 
				accounts[3], 
				referenceId, 
				valueToApprove
			);
			let locked = await token.lockedBalanceOf(accounts[2]);
			assert.equal(locked, 0);
			let balanceSender = await token.balanceOf(accounts[2]);
			assert.equal(balanceSender, 0);
			let balanceRecipient = await token.balanceOf(accounts[3]);
			assert.equal(balanceRecipient, 100);
			let balanceAuthority = await token.balanceOf(accounts[0]);
			assert.equal(balanceAuthority, amount(1) - 101);
		});	

		it('should fail if already resolved', async function() {
			try {
				await token.executeLockedTransfer(
					accounts[2], 
					accounts[3], 
					referenceId, 
					valueToApprove
				);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});

	});

	describe('escrow rollback', function() {
		let referenceId = 1;
		let valueToApprove = 100;
		let fee = 1;
		let exchangeRate = 0;

		it('should lock amount + fee', async function() {
			token = await SDT.new(1);
			await token.approveLockedTransfer(
				accounts[1], 
				referenceId, 
				valueToApprove, 
				fee, 
				futureDate
			);
			let locked = await token.lockedBalanceOf(accounts[0]);
			assert.equal(locked, valueToApprove + fee);
			let balance = await token.balanceOf(accounts[0]);
			assert.equal(balance, amount(1) - (valueToApprove + fee));
		});

		it('should return tokens to owner except fee', async function() {
			await token.executeLockedTransfer(
				accounts[0], 
				accounts[0], 
				referenceId, 
				exchangeRate, 
				{from: accounts[1]}
			);
			let locked = await token.lockedBalanceOf(accounts[0]);
			assert.equal(locked, 0);
			let senderBalance = await token.balanceOf(accounts[0]);
			assert.equal(senderBalance, amount(1) - fee);
			let authorityBalance = await token.balanceOf(accounts[1]);
			assert.equal(authorityBalance, fee);
		});

	});

	describe('escrow claim', function() {
		let referenceId = 1;
		let referenceIdTwo = 2;
		let valueToApprove = 100;
		let fee = 1;
		let exchangeRate = 0;

		it('should lock amount + fee', async function() {
			token = await SDT.new(1);
			await token.approveLockedTransfer(
				accounts[1], 
				referenceId, 
				valueToApprove, 
				fee, 
				pastDate
			);
			let locked = await token.lockedBalanceOf(accounts[0]);
			assert.equal(locked, valueToApprove + fee);
			let balance = await token.balanceOf(accounts[0]);
			assert.equal(balance, amount(1) - (valueToApprove + fee));
		});

		it('should allow user to get tokens back on an expired lock', async function() {
			await token.claimLockedTransfer(accounts[1], referenceId);
			let locked = await token.lockedBalanceOf(accounts[0]);
			assert.equal(locked, 0);
			let senderBalance = await token.balanceOf(accounts[0]);
			assert.equal(senderBalance, amount(1));
			let authorityBalance = await token.balanceOf(accounts[1]);
			assert.equal(authorityBalance, 0);
		});

	});	

	describe('escrow mediate', function() {

	});	

})
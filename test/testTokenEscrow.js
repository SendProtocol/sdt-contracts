const SDT = artifacts.require("./SDT.sol");
const assertJump = require('./helpers/assertJump');

function amount(a){
	return a*10**18;
}

contract('SDT', function(accounts) {
	let token;
	let futureDate = new Date().valueOf() + 3600;

	describe('escrow basic flow', function() {
		it("should lock amount + fee", async function() {
			token = await SDT.new(1);
			await token.approveLockedTransfer(accounts[1], 1, 100, 1, futureDate);
			let locked = await token.lockedBalanceOf(accounts[0]);
			assert.equal(locked, 101);
			let balance = await token.balanceOf(accounts[0]);
			assert.equal(balance, amount(1) - 101);
		});

		it("should fail if trying to use the same keys", async function() {
			try {
				await token.approveLockedTransfer(accounts[1], 1, 100, 1, futureDate);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});

		it("should fail if trying to allow more than balance", async function() {
			try {
				await token.approveLockedTransfer(accounts[1], 2, amount(1), 1, futureDate);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});

		it("should fail if not enough balance to pay fee", async function() {
			try {
				await token.approveLockedTransfer(accounts[1], 2, amount(1) - 101, 1, futureDate);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});

		it("should fail if authority tries to set an exchange rate", async function() {
			try {
				await token.executeLockedTransfer(accounts[0], accounts[2], 1, 1, {from: accounts[1]});
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});	

		it("should be possible to spend locked allowance", async function() {
			await token.executeLockedTransfer(accounts[0], accounts[2], 1, 0, {from: accounts[1]});
			let locked = await token.lockedBalanceOf(accounts[0]);
			assert.equal(locked, 0);
			let balanceSender = await token.balanceOf(accounts[0]);
			assert.equal(balanceSender, amount(1) - 101);
			let balanceRecipient = await token.balanceOf(accounts[2]);
			assert.equal(balanceRecipient, 100);
			let balanceAuthority = await token.balanceOf(accounts[1]);
			assert.equal(balanceAuthority, 1);
		});	

		it("should fail if exchange rate not set for a verified account", async function() {
			await token.approveLockedTransfer(accounts[0], 1, 100, 0, futureDate, {from: accounts[2]});
			try {
				await token.executeLockedTransfer(accounts[2], accounts[3], 1, 0);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});	

		it("should be possible to set exchange rate for a verified account", async function() {
			await token.executeLockedTransfer(accounts[2], accounts[3], 1, 100);
			let locked = await token.lockedBalanceOf(accounts[2]);
			assert.equal(locked, 0);
			let balanceSender = await token.balanceOf(accounts[2]);
			assert.equal(balanceSender, 0);
			let balanceRecipient = await token.balanceOf(accounts[3]);
			assert.equal(balanceRecipient, 100);
			let balanceAuthority = await token.balanceOf(accounts[0]);
			assert.equal(balanceAuthority, amount(1) - 101);
		});	

	});

	describe('escrow rollback', function() {

	});

	describe('escrow claim', function() {

	});	

	describe('escrow mediate', function() {

	});	

})
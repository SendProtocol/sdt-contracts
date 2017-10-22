'use strict';

const SDT = artifacts.require("./SDT.sol");
const assertJump = require('./helpers/assertJump');

function amount(a){
	return a*10**18;
}

contract('SDT', function(accounts) {
	let token;
	let futureDate = new Date().valueOf() + 3600;

	describe('create poll', function() {
		it("should store new poll if user is verified", async function() {
			token = await SDT.new(1);
			await token.createPoll(1, "is this working?", ["yes", "nope"], 1, 0, futureDate);
			let poll = await token.polls.call(1);
			assert.equal(poll[0], accounts[0]);
			assert.equal(poll[1].valueOf(), 1);
			assert.equal(poll[2].valueOf(), 0);
			assert.equal(poll[3].valueOf(), futureDate);
		});

		it("should fail if an unverified user tries create a poll", async function() {
			try {
				await token.createPoll(2, "is this working?", ["yes", "nope"], 1, 0, futureDate, {from: accounts[1]});
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});

		it("should fail if an user tries to create a poll with a repeated id", async function() {
			try {
				await token.createPoll(1, "is this working?", ["yes", "nope"], 1, 0, futureDate);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});
	});

	describe('vote', function() {
		it('should return true if voting user meets condition', async function() {
			token = await SDT.new(1);
			await token.createPoll(1, "is this working?", ["yes", "nope"], 1, 0, futureDate);
			let response = await token.vote(1,0);
			assert(response);
		});

		it('should fail if user tries to vote a second time in the same pol', async function() {
			try {
				await token.vote(1,0);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});

		it('should fail if user tries to vote in an unexisting poll', async function() {
			try {
				await token.vote(2,0);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});

		it('should fail if an user with no enough tokens tries to vote', async function() {
			try {
				await token.vote(1,0, {from: accounts[1]});
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});

		it('should fail if user tries to vote before start date', async function() {
			await token.createPoll(2, "is this working?", ["yes", "nope"], 1, futureDate, futureDate + 1);
			try {
				await token.vote(2,0);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});

		it('should fail if user tries to vote after end date', async function() {
			await token.createPoll(3, "is this working?", ["yes", "nope"], 1, 0, 1);
			try {
				await token.vote(3,0);
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});

	});

})
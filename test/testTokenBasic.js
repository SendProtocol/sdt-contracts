'use strict';

const SDT = artifacts.require("./SDT.sol");
const assertJump = require('./helpers/assertJump');

contract('SDT', function(accounts) {

    it("contract deploy should put 700M * 10^18 SDT in the first account", async function() {
        let token = await SDT.deployed();
        let balance = await token.balanceOf.call(accounts[0])
        assert.equal(balance.valueOf(), 700*10**24, "700M * 10^18 wasn't in the first account");
    });

	describe('consensus network', function() {
		let token;

		it("should be verified by default", async function() {
			token = await SDT.new(1);
			assert(await token.isVerified(accounts[0]));
		});

		it("should be unverified by default", async function() {
			assert(!(await token.isVerified(accounts[1])));
		});

		it("should possible to verify", async function() {
			await token.verify(accounts[1]);
			assert(await token.isVerified(accounts[1]));
		});

		it("should not be possible to verify", async function() {
			try {
				await token.verify(accounts[2], {from: accounts[1]});
				assert.fail('should have thrown before');
			} catch(error) {
				assertJump(error);
			}
		});
	});

});

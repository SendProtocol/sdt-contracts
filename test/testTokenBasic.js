"use strict";

const SDT = artifacts.require("./SDT.sol");
const assertJump = require("./helpers/assertJump");
const math = require("mathjs");

contract("SDT", function(accounts) {
  it("contract deploy should put 700M * 10^18 SDT in the first account", async function() {
    let token = await SDT.new(700 * 10 ** 6, accounts[0], accounts[1], 100);
    let balance = await token.balanceOf.call(accounts[0]);
    let expectedBalance = 7 * math.pow(10, 26);
    assert.equal(
      balance.valueOf(),
      expectedBalance,
      "700M * 10^18 wasn not in the first account"
    );
  });

  describe("consensus network", function() {
    let token;

    it("should be verified by default", async function() {
      token = await SDT.new(1, accounts[0], accounts[1], 100);
      assert(await token.isVerified(accounts[0]));
    });

    it("should be unverified by default", async function() {
      assert(!await token.isVerified.call(accounts[1]));
    });

    it("should possible to verify", async function() {
      await token.verify(accounts[1]);
      assert(await token.isVerified(accounts[1]));
    });

    it("should not be possible to verify", async function() {
      try {
        await token.verify(accounts[2], { from: accounts[1] });
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });
  });
});

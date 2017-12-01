"use strict";

const SDT = artifacts.require('./SDT.sol');
const Escrow = artifacts.require('./Escrow.sol');
const assertJump = require('./helpers/assertJump');
const math = require('mathjs');

let accountBalanceBefore;
let accountBalanceAfter;
let escrowBalanceBefore;
let escrowBalanceAfter;
let destBalanceBefore;
let destBalanceAfter;
let authBalanceBefore;
let authBalanceAfter;

function amount(a) {
  return a * math.pow(10, 18);
}

contract("SDT", function(accounts) {
  let token;
  let escrow;
  let futureDate = new Date().valueOf() + 3600;
  let pastDate = 1;

  describe("escrow basic flow", function() {
    let reference = 1;
    let referenceTwo = 2;
    let tokens = 100;
    let fee = 1;
    let exchangeRate = 1;

    it("should lock amount + fee", async function() {
      token = await SDT.new(1, accounts[0], accounts[1], 100);
      escrow = await Escrow.new(token.address);
      token.setEscrow(escrow.address);

      accountBalanceBefore = await token.balanceOf.call(accounts[0]);
      escrowBalanceBefore = await token.balanceOf.call(escrow.address);

      await token.escrowTransfer(
        accounts[1],
        reference,
        tokens,
        fee,
        futureDate
      );

      accountBalanceAfter = await token.balanceOf.call(accounts[0]);
      escrowBalanceAfter = await token.balanceOf.call(escrow.address);

      assert.equal(escrowBalanceAfter.valueOf(), escrowBalanceBefore.add(tokens).add(fee).valueOf());
      assert.equal(accountBalanceAfter.valueOf(), accountBalanceBefore.sub(tokens).sub(fee).valueOf());
    });

    it("should fail if trying to use the same keys", async function() {
      try {
        await token.escrowTransfer(
          accounts[1],
          reference,
          tokens,
          fee,
          futureDate
        );
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should fail if trying to use more than balance", async function() {
      try {
        await token.escrowTransfer(
          accounts[1],
          referenceTwo,
          amount(1),
          fee,
          futureDate
        );
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should fail if not enough balance to pay fee", async function() {
      try {
        await token.escrowTransfer(
          accounts[1],
          referenceTwo,
          amount(1) - (tokens + fee),
          fee,
          futureDate
        );
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should fail if no verified sets an exchange rate", async function() {
      try {
        await escrow.executeEscrowTransfer(
          accounts[0],
          accounts[2],
          reference,
          exchangeRate,
          { from: accounts[1] }
        );
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should be possible to spend locked balance", async function() {

      accountBalanceBefore = await token.balanceOf.call(accounts[0]);
      authBalanceBefore = await token.balanceOf.call(accounts[1]);
      destBalanceBefore = await token.balanceOf.call(accounts[2]);
      escrowBalanceBefore = await token.balanceOf.call(escrow.address);

      await escrow.executeEscrowTransfer(
        accounts[0],
        accounts[2],
        reference,
        0,
        { from: accounts[1] }
      );

      accountBalanceAfter = await token.balanceOf.call(accounts[0]);
      authBalanceAfter = await token.balanceOf.call(accounts[1]);
      destBalanceAfter = await token.balanceOf.call(accounts[2]);
      escrowBalanceAfter = await token.balanceOf.call(escrow.address);

      assert.equal(accountBalanceBefore.valueOf(), accountBalanceAfter.valueOf());
      assert.equal(authBalanceAfter.valueOf(), authBalanceBefore.add(fee).valueOf());
      assert.equal(destBalanceAfter.valueOf(), destBalanceBefore.add(tokens).valueOf());
      assert.equal(escrowBalanceAfter.valueOf(), escrowBalanceBefore.sub(fee).sub(tokens).valueOf());

    });

    it("should fail if exchange rate not set", async function() {

      await token.escrowTransfer(
        accounts[0],
        reference,
        tokens,
        0,
        futureDate,
        { from: accounts[2] }
      );
      try {
        await escrow.executeEscrowTransfer(
          accounts[2],
          accounts[3],
          reference,
          0
        );
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should be possible to set exchange rate if verified", async function() {
      accountBalanceBefore = await token.balanceOf.call(accounts[2]);
      authBalanceBefore = await token.balanceOf.call(accounts[0]);
      destBalanceBefore = await token.balanceOf.call(accounts[3]);
      escrowBalanceBefore = await token.balanceOf.call(escrow.address);

      await escrow.executeEscrowTransfer(
        accounts[2],
        accounts[3],
        reference,
        exchangeRate
      );

      accountBalanceAfter = await token.balanceOf.call(accounts[2]);
      authBalanceAfter = await token.balanceOf.call(accounts[0]);
      destBalanceAfter = await token.balanceOf.call(accounts[3]);
      escrowBalanceAfter = await token.balanceOf.call(escrow.address);

      assert.equal(accountBalanceBefore.valueOf(), accountBalanceAfter.valueOf());
      assert.equal(authBalanceAfter.valueOf(), authBalanceBefore.valueOf());
      assert.equal(destBalanceAfter.valueOf(), destBalanceBefore.add(tokens).valueOf());
      assert.equal(escrowBalanceAfter.valueOf(), escrowBalanceBefore.sub(tokens).valueOf());
      
    });

    it("should fail if already resolved", async function() {
      try {
        await escrow.executeEscrowTransfer(
          accounts[2],
          accounts[3],
          reference,
          exchangeRate
        );
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });
  });

  describe("escrow rollback", function() {
    let reference = 1;
    let tokens = 100;
    let fee = 1;
    let exchangeRate = 0;

    it("should lock amount + fee", async function() {
      token = await SDT.new(1, accounts[0], accounts[1], 100);
      escrow = await Escrow.new(token.address);
      token.setEscrow(escrow.address);

      accountBalanceBefore = await token.balanceOf.call(accounts[0]);
      escrowBalanceBefore = await token.balanceOf.call(escrow.address);

      await token.escrowTransfer(
        accounts[1],
        reference,
        tokens,
        fee,
        futureDate
      );

      accountBalanceAfter = await token.balanceOf.call(accounts[0]);
      escrowBalanceAfter = await token.balanceOf.call(escrow.address);

      assert.equal(escrowBalanceAfter.valueOf(), escrowBalanceBefore.add(tokens).add(fee).valueOf());
      assert.equal(accountBalanceAfter.valueOf(), accountBalanceBefore.sub(tokens).sub(fee).valueOf());
    });

    it("should return tokens to owner except fee", async function() {
      accountBalanceBefore = await token.balanceOf.call(accounts[0]);
      authBalanceBefore = await token.balanceOf.call(accounts[1]);
      destBalanceBefore = await token.balanceOf.call(accounts[2]);
      escrowBalanceBefore = await token.balanceOf.call(escrow.address);

      await escrow.executeEscrowTransfer(
        accounts[0],
        accounts[0],
        reference,
        exchangeRate,
        { from: accounts[1] }
      );

      accountBalanceAfter = await token.balanceOf.call(accounts[0]);
      authBalanceAfter = await token.balanceOf.call(accounts[1]);
      destBalanceAfter = await token.balanceOf.call(accounts[2]);
      escrowBalanceAfter = await token.balanceOf.call(escrow.address);

      assert.equal(accountBalanceBefore.add(tokens).valueOf(), accountBalanceAfter.valueOf());
      assert.equal(authBalanceAfter.valueOf(), authBalanceBefore.add(fee).valueOf());
      assert.equal(destBalanceAfter.valueOf(), destBalanceBefore.valueOf());
      assert.equal(escrowBalanceAfter.valueOf(), escrowBalanceBefore.sub(fee).sub(tokens).valueOf());
      
      
    });
  });

  describe("escrow claim", function() {
    let reference = 1;
    let tokens = 100;
    let fee = 1;

    it("should lock amount + fee", async function() {
      token = await SDT.new(1, accounts[0], accounts[1], 100);
      escrow = await Escrow.new(token.address);
      token.setEscrow(escrow.address);

      accountBalanceBefore = await token.balanceOf.call(accounts[0]);
      escrowBalanceBefore = await token.balanceOf.call(escrow.address);

      await token.escrowTransfer(
        accounts[1],
        reference,
        tokens,
        fee,
        pastDate
      );

      accountBalanceAfter = await token.balanceOf.call(accounts[0]);
      escrowBalanceAfter = await token.balanceOf.call(escrow.address);

      assert.equal(escrowBalanceAfter.valueOf(), escrowBalanceBefore.add(tokens).add(fee).valueOf());
      assert.equal(accountBalanceAfter.valueOf(), accountBalanceBefore.sub(tokens).sub(fee).valueOf());
    });

    it("should allow user to get tokens back on an expired lock", async function() {

      accountBalanceBefore = await token.balanceOf.call(accounts[0]);
      authBalanceBefore = await token.balanceOf.call(accounts[1]);
      destBalanceBefore = await token.balanceOf.call(accounts[2]);
      escrowBalanceBefore = await token.balanceOf.call(escrow.address);

      await escrow.claimEscrowTransfer(accounts[1], reference);

      accountBalanceAfter = await token.balanceOf.call(accounts[0]);
      authBalanceAfter = await token.balanceOf.call(accounts[1]);
      destBalanceAfter = await token.balanceOf.call(accounts[2]);
      escrowBalanceAfter = await token.balanceOf.call(escrow.address);

      assert.equal(accountBalanceBefore.add(tokens).add(fee).valueOf(), accountBalanceAfter.valueOf());
      assert.equal(authBalanceAfter.valueOf(), authBalanceBefore.valueOf());
      assert.equal(destBalanceAfter.valueOf(), destBalanceBefore.valueOf());
      assert.equal(escrowBalanceAfter.valueOf(), escrowBalanceBefore.sub(fee).sub(tokens).valueOf());

    });
  });

  describe("escrow mediate", function() {
    let reference = 1;
    let tokens = 100;
    let fee = 1;
    let exchangeRate = 0;

    it("should lock amount + fee", async function() {
      token = await SDT.new(1, accounts[0], accounts[1], 100);
      escrow = await Escrow.new(token.address);
      token.setEscrow(escrow.address);

      accountBalanceBefore = await token.balanceOf.call(accounts[0]);
      escrowBalanceBefore = await token.balanceOf.call(escrow.address);

      await token.escrowTransfer(
        accounts[1],
        reference,
        tokens,
        fee,
        pastDate
      );

      accountBalanceAfter = await token.balanceOf.call(accounts[0]);
      escrowBalanceAfter = await token.balanceOf.call(escrow.address);

      assert.equal(escrowBalanceAfter.valueOf(), escrowBalanceBefore.add(tokens).add(fee).valueOf());
      assert.equal(accountBalanceAfter.valueOf(), accountBalanceBefore.sub(tokens).sub(fee).valueOf());
    });

    it("should should fail if user tries to claim tokens after invalidation", async function() {
      await escrow.invalidateEscrowTransferExpiration(accounts[0], reference, {
        from: accounts[1]
      });

      try {
        await escrow.claimEscrowTransfer(accounts[1], reference);
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should be able to release tokens", async function() {

      accountBalanceBefore = await token.balanceOf.call(accounts[0]);
      authBalanceBefore = await token.balanceOf.call(accounts[1]);
      destBalanceBefore = await token.balanceOf.call(accounts[2]);
      escrowBalanceBefore = await token.balanceOf.call(escrow.address);

      await escrow.executeEscrowTransfer(
        accounts[0],
        accounts[2],
        reference,
        0,
        { from: accounts[1] }
      );

      accountBalanceAfter = await token.balanceOf.call(accounts[0]);
      authBalanceAfter = await token.balanceOf.call(accounts[1]);
      destBalanceAfter = await token.balanceOf.call(accounts[2]);
      escrowBalanceAfter = await token.balanceOf.call(escrow.address);

      assert.equal(accountBalanceBefore.valueOf(), accountBalanceAfter.valueOf());
      assert.equal(authBalanceAfter.valueOf(), authBalanceBefore.add(fee).valueOf());
      assert.equal(destBalanceAfter.valueOf(), destBalanceBefore.add(tokens).valueOf());
      assert.equal(escrowBalanceAfter.valueOf(), escrowBalanceBefore.sub(fee).sub(tokens).valueOf());

    });
  });
});

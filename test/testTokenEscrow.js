"use strict";

const { latestTime, increaseTimeTo, duration } = require("./helpers/time.js");

const SDT = artifacts.require("./SDT.sol");
const Escrow = artifacts.require("./Escrow.sol");
const assertJump = require("./helpers/assertJump");
const math = require("mathjs");

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
  let futureDate = latestTime() + duration.hours(1);

  describe("escrow basic flow", function() {
    let tokens = 100;
    let fee = 1;
    let exchangeRate = 1;

    before(async function() {
      this.token = await SDT.new(accounts[0]);
      this.escrow = await Escrow.new(this.token.address);
      this.token.setEscrow(this.escrow.address);
    });

    it("should lock amount + fee", async function() {
      accountBalanceBefore = await this.token.balanceOf.call(accounts[0]);
      escrowBalanceBefore = await this.token.balanceOf.call(
        this.escrow.address
      );

      await this.token.createEscrow(
        accounts[0],
        accounts[2],
        1,
        tokens,
        fee,
        futureDate,
        {from: accounts[1]}
      );

      await this.token.fundEscrow(
        accounts[1],
        1,
        tokens,
        fee
      )

      accountBalanceAfter = await this.token.balanceOf.call(accounts[0]);
      escrowBalanceAfter = await this.token.balanceOf.call(this.escrow.address);

      assert.equal(
        escrowBalanceAfter.valueOf(),
        escrowBalanceBefore
          .add(tokens)
          .add(fee)
          .valueOf()
      );
      assert.equal(
        accountBalanceAfter.valueOf(),
        accountBalanceBefore
          .sub(tokens)
          .sub(fee)
          .valueOf()
      );
    });

    it("should fiail if trying to fund an escrow twice", async function() {
      accountBalanceBefore = await this.token.balanceOf.call(accounts[0]);
      escrowBalanceBefore = await this.token.balanceOf.call(
        this.escrow.address
      );

      await this.token.createEscrow(
        accounts[0],
        accounts[2],
        7878,
        tokens,
        fee,
        futureDate,
        {from: accounts[1]}
      );

      await this.token.fundEscrow(
        accounts[1],
        7878,
        tokens,
        fee
      )

      try {
        await this.token.fundEscrow(
          accounts[1],
          7878  ,
          tokens,
          fee
        )
      } catch (error) {
        assertJump(error);
      }

      accountBalanceAfter = await this.token.balanceOf.call(accounts[0]);
      escrowBalanceAfter = await this.token.balanceOf.call(this.escrow.address);

    });

    it("should fail if trying to use the same keys", async function() {
      try {
        await this.token.createEscrow(
          accounts[0],
          accounts[2],
          1,
          tokens,
          fee,
          futureDate,
          {from: accounts[1]}
        );
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should fail if trying to use more than balance", async function() {
      await this.token.createEscrow(
        accounts[0],
        accounts[2],
        2,
        amount(700000000),
        fee,
        futureDate,
        {from: accounts[1]}
      );
      try {
        await this.token.fundEscrow(
          accounts[1],
          2,
          amount(700000000),
          fee
        )
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should fail if values are not exact", async function() {
      await this.token.createEscrow(
        accounts[0],
        accounts[2],
        4,
        tokens,
        fee,
        futureDate,
        {from: accounts[1]}
      );
      try {
        await this.token.fundEscrow(
          accounts[1],
          4,
          tokens + 1,
          fee
        )
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should fail if values are not exact", async function() {
      try {
        await this.token.fundEscrow(
          accounts[1],
          4,
          tokens,
          fee + 1
        )
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should fail if trying to fund an unexisting escrow", async function() {
      try {
        await this.token.fundEscrow(
          accounts[1],
          5,
          tokens,
          fee + 1
        )
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should fail if not enough balance to pay fee", async function() {
      await this.token.createEscrow(
        accounts[0],
        accounts[2],
        3,
        amount(700000000) - (tokens + fee),
        fee,
        futureDate,
        {from: accounts[1]}
      );
      try {
        await this.token.fundEscrow(
          accounts[1],
          3,
          amount(700000000) - (tokens + fee),
          fee
        )
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should fail if no verified sets an exchange rate", async function() {
      try {
        await this.escrow.release(
          accounts[0],
          accounts[2],
          1,
          exchangeRate,
          { from: accounts[1] }
        );
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should be possible to spend locked balance", async function() {
      accountBalanceBefore = await this.token.balanceOf.call(accounts[0]);
      authBalanceBefore = await this.token.balanceOf.call(accounts[1]);
      destBalanceBefore = await this.token.balanceOf.call(accounts[2]);
      escrowBalanceBefore = await this.token.balanceOf.call(
        this.escrow.address
      );

      await this.escrow.release(
        accounts[0],
        accounts[2],
        1,
        0,
        { from: accounts[1] }
      );

      accountBalanceAfter = await this.token.balanceOf.call(accounts[0]);
      authBalanceAfter = await this.token.balanceOf.call(accounts[1]);
      destBalanceAfter = await this.token.balanceOf.call(accounts[2]);
      escrowBalanceAfter = await this.token.balanceOf.call(this.escrow.address);

      assert.equal(
        accountBalanceBefore.valueOf(),
        accountBalanceAfter.valueOf()
      );
      assert.equal(
        authBalanceAfter.valueOf(),
        authBalanceBefore.add(fee).valueOf()
      );
      assert.equal(
        destBalanceAfter.valueOf(),
        destBalanceBefore.add(tokens).valueOf()
      );
      assert.equal(
        escrowBalanceAfter.valueOf(),
        escrowBalanceBefore
          .sub(fee)
          .sub(tokens)
          .valueOf()
      );
    });

    it("should fail if exchange rate not set", async function() {
      await this.token.verify(accounts[4]);
      await this.token.createEscrow(
        accounts[2],
        accounts[3],
        1,
        tokens,
        0,
        futureDate,
        {from: accounts[4]}
      );

      await this.token.fundEscrow(
        accounts[4],
        1,
        tokens,
        0,
        {from: accounts[2]}
      )

      try {
        await this.escrow.release(
          accounts[2],
          accounts[3],
          1,
          0,
          {from: accounts[4]}
        );
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should be possible to set exchange rate if verified", async function() {
      accountBalanceBefore = await this.token.balanceOf.call(accounts[2]);
      authBalanceBefore = await this.token.balanceOf.call(accounts[0]);
      destBalanceBefore = await this.token.balanceOf.call(accounts[3]);
      escrowBalanceBefore = await this.token.balanceOf.call(
        this.escrow.address
      );

      await this.escrow.release(
        accounts[2],
        accounts[3],
        1,
        exchangeRate,
        {from: accounts[4]}
      );

      accountBalanceAfter = await this.token.balanceOf.call(accounts[2]);
      authBalanceAfter = await this.token.balanceOf.call(accounts[0]);
      destBalanceAfter = await this.token.balanceOf.call(accounts[3]);
      escrowBalanceAfter = await this.token.balanceOf.call(this.escrow.address);

      assert.equal(
        accountBalanceBefore.valueOf(),
        accountBalanceAfter.valueOf()
      );
      assert.equal(authBalanceAfter.valueOf(), authBalanceBefore.valueOf());
      assert.equal(
        destBalanceAfter.valueOf(),
        destBalanceBefore.add(tokens).valueOf()
      );
      assert.equal(
        escrowBalanceAfter.valueOf(),
        escrowBalanceBefore.sub(tokens).valueOf()
      );
    });

    it("should fail if already resolved", async function() {
      try {
        await this.escrow.release(
          accounts[2],
          accounts[3],
          1,
          exchangeRate
        );
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });
  });

  describe("escrow rollback", function() {
    let tokens = 100;
    let fee = 1;
    let exchangeRate = 0;

    before(async function() {
      this.token = await SDT.new(accounts[0]);
      this.escrow = await Escrow.new(this.token.address);
      this.token.setEscrow(this.escrow.address);
    });

    it("should lock amount + fee", async function() {
      accountBalanceBefore = await this.token.balanceOf.call(accounts[0]);
      escrowBalanceBefore = await this.token.balanceOf.call(
        this.escrow.address
      );

      await this.token.createEscrow(
        accounts[0],
        accounts[2],
        1,
        tokens,
        fee,
        futureDate,
        {from: accounts[1]}
      );

      await this.token.fundEscrow(
        accounts[1],
        1,
        tokens,
        fee
      )

      accountBalanceAfter = await this.token.balanceOf.call(accounts[0]);
      escrowBalanceAfter = await this.token.balanceOf.call(this.escrow.address);

      assert.equal(
        escrowBalanceAfter.valueOf(),
        escrowBalanceBefore
          .add(tokens)
          .add(fee)
          .valueOf()
      );
      assert.equal(
        accountBalanceAfter.valueOf(),
        accountBalanceBefore
          .sub(tokens)
          .sub(fee)
          .valueOf()
      );
    });

    it("should return tokens to owner except fee", async function() {

      await increaseTimeTo(latestTime() + duration.hours(2));

      accountBalanceBefore = await this.token.balanceOf.call(accounts[0]);
      authBalanceBefore = await this.token.balanceOf.call(accounts[1]);
      destBalanceBefore = await this.token.balanceOf.call(accounts[2]);
      escrowBalanceBefore = await this.token.balanceOf.call(
        this.escrow.address
      );

      await this.escrow.release(
        accounts[0],
        accounts[0],
        1,
        exchangeRate,
        { from: accounts[1] }
      );

      accountBalanceAfter = await this.token.balanceOf.call(accounts[0]);
      authBalanceAfter = await this.token.balanceOf.call(accounts[1]);
      destBalanceAfter = await this.token.balanceOf.call(accounts[2]);
      escrowBalanceAfter = await this.token.balanceOf.call(this.escrow.address);

      assert.equal(
        accountBalanceBefore.add(tokens).valueOf(),
        accountBalanceAfter.valueOf()
      );
      assert.equal(
        authBalanceAfter.valueOf(),
        authBalanceBefore.add(fee).valueOf()
      );
      assert.equal(destBalanceAfter.valueOf(), destBalanceBefore.valueOf());
      assert.equal(
        escrowBalanceAfter.valueOf(),
        escrowBalanceBefore
          .sub(fee)
          .sub(tokens)
          .valueOf()
      );
    });
  });

  describe("escrow claim", function() {
    let tokens = 100;
    let fee = 1;

    before(async function() {
      this.token = await SDT.new(accounts[0]);
      this.escrow = await Escrow.new(this.token.address);
      this.token.setEscrow(this.escrow.address);
      futureDate = latestTime() + duration.hours(1);
    });

    it("should lock amount + fee", async function() {
      accountBalanceBefore = await this.token.balanceOf.call(accounts[0]);
      escrowBalanceBefore = await this.token.balanceOf.call(
        this.escrow.address
      );

      await this.token.createEscrow(
        accounts[0],
        accounts[2],
        1,
        tokens,
        fee,
        futureDate,
        {from: accounts[1]}
      );

      await this.token.fundEscrow(
        accounts[1],
        1,
        tokens,
        fee
      )

      accountBalanceAfter = await this.token.balanceOf.call(accounts[0]);
      escrowBalanceAfter = await this.token.balanceOf.call(this.escrow.address);

      assert.equal(
        escrowBalanceAfter.valueOf(),
        escrowBalanceBefore
          .add(tokens)
          .add(fee)
          .valueOf()
      );
      assert.equal(
        accountBalanceAfter.valueOf(),
        accountBalanceBefore
          .sub(tokens)
          .sub(fee)
          .valueOf()
      );
    });

    it("should allow user to get tokens back on an expired lock", async function() {
      await increaseTimeTo(futureDate + duration.hours(2));

      accountBalanceBefore = await this.token.balanceOf.call(accounts[0]);
      authBalanceBefore = await this.token.balanceOf.call(accounts[1]);
      destBalanceBefore = await this.token.balanceOf.call(accounts[2]);
      escrowBalanceBefore = await this.token.balanceOf.call(
        this.escrow.address
      );

      await this.escrow.claim(accounts[1], 1);

      accountBalanceAfter = await this.token.balanceOf.call(accounts[0]);
      authBalanceAfter = await this.token.balanceOf.call(accounts[1]);
      destBalanceAfter = await this.token.balanceOf.call(accounts[2]);
      escrowBalanceAfter = await this.token.balanceOf.call(this.escrow.address);

      assert.equal(
        accountBalanceBefore
          .add(tokens)
          .add(fee)
          .valueOf(),
        accountBalanceAfter.valueOf()
      );
      assert.equal(authBalanceAfter.valueOf(), authBalanceBefore.valueOf());
      assert.equal(destBalanceAfter.valueOf(), destBalanceBefore.valueOf());
      assert.equal(
        escrowBalanceAfter.valueOf(),
        escrowBalanceBefore
          .sub(fee)
          .sub(tokens)
          .valueOf()
      );
    });
  });

  describe("escrow mediate", function() {
    let tokens = 100;
    let fee = 1;
    let exchangeRate = 0;

    before(async function() {
      this.token = await SDT.new(accounts[0]);
      this.escrow = await Escrow.new(this.token.address);
      this.token.setEscrow(this.escrow.address);
    });

    it("should lock amount + fee", async function() {
      accountBalanceBefore = await this.token.balanceOf.call(accounts[0]);
      escrowBalanceBefore = await this.token.balanceOf.call(
        this.escrow.address
      );

      await this.token.createEscrow(
        accounts[0],
        accounts[2],
        1,
        tokens,
        fee,
        futureDate,
        {from: accounts[1]}
      );

      await this.token.fundEscrow(
        accounts[1],
        1,
        tokens,
        fee
      )

      accountBalanceAfter = await this.token.balanceOf.call(accounts[0]);
      escrowBalanceAfter = await this.token.balanceOf.call(this.escrow.address);

      assert.equal(
        escrowBalanceAfter.valueOf(),
        escrowBalanceBefore
          .add(tokens)
          .add(fee)
          .valueOf()
      );
      assert.equal(
        accountBalanceAfter.valueOf(),
        accountBalanceBefore
          .sub(tokens)
          .sub(fee)
          .valueOf()
      );
    });

    it("should fail if user tries to claim tokens after invalidation", async function() {
      await this.escrow.mediate(1, {from: accounts[1]});

      try {
        await this.escrow.claim(accounts[1], 1);
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should be able to release tokens", async function() {
      accountBalanceBefore = await this.token.balanceOf.call(accounts[0]);
      authBalanceBefore = await this.token.balanceOf.call(accounts[1]);
      destBalanceBefore = await this.token.balanceOf.call(accounts[2]);
      escrowBalanceBefore = await this.token.balanceOf.call(
        this.escrow.address
      );

      await this.escrow.release(
        accounts[0],
        accounts[2],
        1,
        0,
        { from: accounts[1] }
      );

      accountBalanceAfter = await this.token.balanceOf.call(accounts[0]);
      authBalanceAfter = await this.token.balanceOf.call(accounts[1]);
      destBalanceAfter = await this.token.balanceOf.call(accounts[2]);
      escrowBalanceAfter = await this.token.balanceOf.call(this.escrow.address);

      assert.equal(
        accountBalanceBefore.valueOf(),
        accountBalanceAfter.valueOf()
      );
      assert.equal(
        authBalanceAfter.valueOf(),
        authBalanceBefore.add(fee).valueOf()
      );
      assert.equal(
        destBalanceAfter.valueOf(),
        destBalanceBefore.add(tokens).valueOf()
      );
      assert.equal(
        escrowBalanceAfter.valueOf(),
        escrowBalanceBefore
          .sub(fee)
          .sub(tokens)
          .valueOf()
      );
    });
  });

  describe("withdraw other tokens", function() {
    let tokens = 100;
    let fee = 1;
    let exchangeRate = 0;

    before(async function() {
      this.token = await SDT.new(accounts[0]);
      this.otherToken = await SDT.new(accounts[7]);
      this.escrow = await Escrow.new(this.token.address);
      this.token.setEscrow(this.escrow.address);
    });

    it("should give tokens back", async function() {
      await this.otherToken.transfer(this.escrow.address, 10, {from: accounts[7]})

      accountBalanceBefore = await this.otherToken.balanceOf.call(accounts[7]);
      escrowBalanceBefore = await this.otherToken.balanceOf.call(
        this.escrow.address
      );

      assert.equal(escrowBalanceBefore, 10);
      assert.equal(accountBalanceBefore, amount(700000000) - 10);

      await this.escrow.transferToken(this.otherToken.address, accounts[7], 10);

      accountBalanceAfter = await this.token.balanceOf.call(accounts[0]);
      escrowBalanceAfter = await this.token.balanceOf.call(this.escrow.address);

      assert.equal(escrowBalanceAfter, 0);
      assert.equal(accountBalanceAfter, amount(700000000));
    });

    it("should fail if not owner", async function() {
      await this.otherToken.transfer(this.escrow.address, 10, {from: accounts[7]})
      try {
        await this.escrow.transferToken(this.otherToken.address, accounts[7], 10, {from: accounts[5]});
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should fail if trying to use with SDT", async function() {
      await this.token.transfer(this.escrow.address, 10)
      try {
        await this.escrow.transferToken(this.token.address, accounts[7], 10);
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

  });  
});

"use strict";

const { latestTime, increaseTimeTo, duration } = require("./helpers/time.js");

const SDT = artifacts.require("./SDT.sol");
const TokenVesting = artifacts.require("./TokenVesting.sol");
const assertJump = require("./helpers/assertJump");

const BigNumber = web3.BigNumber;

const error = 1 * 10 ** 11;

contract("TokenVesting", function(accounts) {
  before(async function() {
    this.owner = accounts[0];
    this.tokenHolder = accounts[1];
    this.tokenRecipient = accounts[2];
    this.amount = new BigNumber(1 * 10 ** 18);
  });

  beforeEach(async function() {
    this.start = latestTime() + duration.minutes(1);
    this.end = this.start + duration.years(1);
    this.vesting = await TokenVesting.new();
    this.token = await SDT.new(this.tokenHolder);

    await this.vesting.init(this.token.address, this.tokenHolder);
    await this.token.transfer(this.vesting.address, this.amount, {
      from: this.tokenHolder
    });
    await this.vesting.grantVestedTokens(
      this.tokenRecipient,
      this.amount,
      this.start,
      this.end,
      { from: this.tokenHolder }
    );

    this.totalVested = await this.vesting.totalVestedTokens.call({
      from: this.tokenRecipient
    });

    assert.equal(this.totalVested.valueOf(), this.amount.valueOf());
  });

  it("Claimable amount before start date should be 0", async function() {
    let claimable = await this.vesting.claimableTokens.call({
      from: this.tokenRecipient
    });
    assert.equal(claimable, 0);
  });

  it("Claimable amount if no grants should be 0", async function() {
    let claimable = await this.vesting.claimableTokens.call({
      from: this.tokenHolder
    });
    let totalVested = await this.vesting.totalVestedTokens.call({
      from: this.tokenHolder
    });
    assert.equal(totalVested, 0);
    assert.equal(claimable, 0);
  });

  it("Claimable amount after end date should equal granted amount", async function() {
    await increaseTimeTo(this.end + duration.weeks(1));
    let claimable = await this.vesting.claimableTokens.call({
      from: this.tokenRecipient
    });
    assert.equal(claimable.valueOf(), this.amount.valueOf());
  });

  it("Claimable amount should increase linearly - half", async function() {
    await increaseTimeTo(this.start + (this.end - this.start) / 2);
    let claimable = await this.vesting.claimableTokens.call({
      from: this.tokenRecipient
    });
    let expected = new BigNumber(String(this.amount / 2));
    assert(claimable.sub(expected).abs() < error);
  });

  it("Claimable amount should increase linearly - 1 hour after start", async function() {
    await increaseTimeTo(this.start + duration.hours(1));
    let claimable = await this.vesting.claimableTokens.call({
      from: this.tokenRecipient
    });
    let expected = new BigNumber(
      String(this.amount * duration.hours(1) / (this.end - this.start))
    );
    assert(claimable.sub(expected).abs() < error);
  });

  it("Claimable amount should increase linearly - 1 hour before end", async function() {
    await increaseTimeTo(this.end - duration.hours(1));
    let claimable = await this.vesting.claimableTokens.call({
      from: this.tokenRecipient
    });
    let expected = new BigNumber(
      String(
        this.amount *
          (this.end - this.start - duration.hours(1)) /
          (this.end - this.start)
      )
    );
    assert(claimable.sub(expected).abs() < error);
  });

  it("User can claim tokens for himself", async function() {
    await this.vesting.allow(this.tokenRecipient);
    await increaseTimeTo(this.end - duration.hours(1));

    let claimable = await this.vesting.claimableTokens.call({
      from: this.tokenRecipient
    });
    let rest = this.amount - claimable;

    await this.vesting.claimTokens({ from: this.tokenRecipient });

    let claimableAfter = await this.vesting.claimableTokens.call({
      from: this.tokenRecipient
    });
    let vestingBalance = await this.token.balanceOf.call(this.vesting.address);
    let recipientBalance = await this.token.balanceOf.call(this.tokenRecipient);

    assert(vestingBalance.sub(rest).abs() < error);
    assert(recipientBalance.sub(claimable).abs() < error);
    assert(claimableAfter < claimable);
  });

  it("claiming tokens with no grants should mnot change balance", async function() {
    await this.vesting.allow(this.tokenHolder);
    await increaseTimeTo(this.end - duration.hours(1));

    let balanceBefore = await this.token.balanceOf.call(this.tokenHolder);
    await this.vesting.claimTokens({ from: this.tokenHolder });
    let balanceAfter = await this.token.balanceOf.call(this.tokenHolder);

    assert.equal(balanceBefore.valueOf(), balanceAfter.valueOf());
  });

  it("Owner can claim tokens in behalf of an user", async function() {
    await this.vesting.allow(this.tokenRecipient);

    await increaseTimeTo(this.end - duration.hours(1));

    let claimable = await this.vesting.claimableTokens.call({
      from: this.tokenRecipient
    });
    let rest = this.amount - claimable;

    await this.vesting.claimTokensFor(this.tokenRecipient);

    let claimableAfter = await this.vesting.claimableTokens.call({
      from: this.tokenRecipient
    });
    let vestingBalance = await this.token.balanceOf.call(this.vesting.address);
    let recipientBalance = await this.token.balanceOf.call(this.tokenRecipient);

    assert(vestingBalance.sub(rest).abs() < error);
    assert(recipientBalance.sub(claimable).abs() < error);
    assert(claimableAfter < claimable);
  });

  it("Should fail if not whitelisted", async function() {
    await increaseTimeTo(this.end - duration.hours(1));
    try {
      await this.vesting.claimTokens({ from: this.tokenRecipient });
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("Should fail if not whitelisted", async function() {
    await increaseTimeTo(this.end - duration.hours(1));
    try {
      await this.vesting.claimTokensFor(this.tokenRecipient);
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("Should be possible to revoke whitelisted status", async function() {
    await this.vesting.allow(this.tokenRecipient);
    await this.vesting.revoke(this.tokenRecipient);
    await increaseTimeTo(this.end - duration.hours(1));
    try {
      await this.vesting.claimTokens({ from: this.tokenRecipient });
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("Should fail if not owner", async function() {
    await increaseTimeTo(this.end - duration.hours(1));
    try {
      await this.vesting.claimTokensFor(this.tokenRecipient, {
        from: this.tokenHolder
      });
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("Should be possible to stop receiving grants", async function() {
    await this.vesting.stop();
    try {
      await this.vesting.grantVestedTokens(
        this.tokenRecipient,
        this.amount,
        this.start,
        this.end,
        { from: this.tokenHolder }
      );
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("Should fail if not owner", async function() {
    try {
      await this.vesting.stop({ from: this.tokenHolder });
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("Should be possible to resume an stopped contract", async function() {
    await this.vesting.stop();
    await this.vesting.resume();
    await this.vesting.grantVestedTokens(
      this.tokenRecipient,
      this.amount,
      this.start,
      this.end,
      { from: this.tokenHolder }
    );
    this.totalVested = await this.vesting.totalVestedTokens.call({
      from: this.tokenRecipient
    });
    assert.equal(this.totalVested.valueOf(), this.amount.mul(2).valueOf());
  });

  it("Should fail if not owner", async function() {
    await this.vesting.stop();
    try {
      await this.vesting.resume({ from: this.tokenHolder });
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("Should fail if not stopped", async function() {
    try {
      await this.vesting.resume();
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("should fail if not initialized", async function() {
    try {
      await this.vesting.resume();
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("should fail if not initialized", async function() {
    let vesting = await TokenVesting.new();
    try {
      await vesting.resume();
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("should fail if not owner", async function() {
    let vesting = await TokenVesting.new();

    try {
      await vesting.init(this.token.address, this.tokenHolder, {
        from: this.tokenRecipient
      });
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });
});

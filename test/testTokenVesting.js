"use strict";

const { latestTime, increaseTimeTo, duration } = require('./helpers/time.js');

const SDT = artifacts.require("./SDT.sol");
const TokenVesting = artifacts.require("./TokenVesting.sol");
const assertJump = require('./helpers/assertJump');

const BigNumber = web3.BigNumber;

contract('TokenVesting', function (accounts) {

  before(async function () {
    this.owner = accounts[0]
    this.tokenHolder = accounts[1];
    this.tokenRecipient = accounts[2];
    this.amount = new BigNumber(1*10**18);
  });

  beforeEach(async function () {

    this.start = latestTime() + duration.minutes(1);
    this.end = this.start + duration.years(1);

    this.vesting = await TokenVesting.new();
    this.token = await SDT.new(1, this.owner, this.tokenHolder, 0);

    await this.vesting.init(this.token.address, this.tokenHolder);
    await this.vesting.grantVestedTokens(
      this.tokenRecipient, 
      this.amount, 
      this.start, 
      this.end, 
      {from: this.tokenHolder}
    );

    this.totalVested = await this.vesting.totalVestedTokens.call({from: this.tokenRecipient});
    
    assert.equal(this.totalVested.valueOf(), this.amount.valueOf());
  });

  it("Claimable amount before start date should be 0", async function() {
    let claimable = await this.vesting.claimableTokens.call({from: this.tokenRecipient});
    assert.equal(claimable, 0);
  });

  it("Claimable amount after end date should equal granted amount", async function() {
    await increaseTimeTo(this.end + duration.weeks(1));
    let claimable = await this.vesting.claimableTokens.call({from: this.tokenRecipient});
    assert.equal(claimable.valueOf(), this.amount.valueOf());
  });

  it("Claimable amount should increase linearly - half", async function() {
    await increaseTimeTo(this.start + ((this.end - this.start)/2));
    let claimable = await this.vesting.claimableTokens.call({from: this.tokenRecipient});
    let expected =  new BigNumber(String(this.amount / 2));
    assert(claimable.sub(expected.abs()) < 1)
  });

  it("Claimable amount should increase linearly - 1 hour", async function() {
    await increaseTimeTo(this.start + duration.hours(1));
    let claimable = await this.vesting.claimableTokens.call({from: this.tokenRecipient});
    let expected =  new BigNumber(String(this.amount * duration.hours(1) / (this.end - this.start)));
    assert(claimable.sub(expected.abs()) < 1)
  });

  it("Claimable amount should increase linearly - 1 hour to finish", async function() {
    await increaseTimeTo(this.end - duration.hours(1));
    let claimable = await this.vesting.claimableTokens.call({from: this.tokenRecipient});
    let expected =  new BigNumber(String(this.amount * (this.end - this.start - duration.hours(1)) / (this.end - this.start)));
    assert(claimable.sub(expected.abs()) < 1)
  });

});
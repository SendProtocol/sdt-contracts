"use strict";

const { latestTime, increaseTimeTo, duration } = require("./helpers/time.js");

const TokenSale = artifacts.require("./TokenSale.sol");
const Distribution = artifacts.require("./Distribution.sol");
const SDT = artifacts.require("./SDT.sol");
const TokenVesting = artifacts.require("./TokenVesting.sol");
const assertJump = require("./helpers/assertJump");
const math = require("mathjs");

function checkMaxError(a, b, e) {
  let diff = math.abs(a - b);
  return diff / a < e;
}

contract("TokenSale", function(accounts) {
  let bought;
  let error;
  let allocated;
  let collected;
  let preallocated;
  let presold;

  let distRaisedETH;
  let distRaisedUSD;
  let distSold;
  let distStageSold;
  let acc6Bonus;
  let acc7Bonus;

  before(async function() {
    this.currentDate = math.floor(Date.now() / 1000);
    this.sale = await TokenSale.new(
      this.currentDate - 1,
      this.currentDate + 1000,
      accounts[7],
      this.currentDate + 100
    );
    this.vesting = await TokenVesting.new();
    this.maxError = 0.00001;
    this.token = null;
  });

  it("should fail", async function() {
    try {
      await this.sale.btcPurchase(0x1, 10);
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("should fail if not owner", async function() {
    try {
      await this.sale.initialize (
        0x10, 
        0x20, 
        0x30, 
        0x40, 
        { from: accounts[1] }
      );
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("should be possible to activate crowdsale", async function() {
    // Create token, should have 700M - 1% ICO reseve
    this.token = await SDT.new(this.sale.address);

    this.distributionContract = await Distribution.new (
      this.currentDate + 2000,
      365,
      86400,
      this.token.address
    );

    assert.equal(
      await this.token.balanceOf.call(this.sale.address),
      7 * 10 ** 26
    );

    // Init vesting contract, should have 0 balance
    await this.vesting.init(this.token.address, this.sale.address);
    assert.equal(await this.token.balanceOf.call(this.vesting.address), 0);

    // Set exchange rates
    await this.sale.setBtcUsdRate(10);
    await this.sale.setWeiUsdRate(100);

    // Initialize sale
    await this.sale.initialize (
      this.token.address, 
      this.vesting.address, 
      0x30, 
      this.distributionContract.address
    );

    // Whitelist an address
    await this.sale.allow(accounts[9]);

    assert(await this.vesting.initialized.call());
    assert(await this.vesting.active.call());
    assert.equal(await this.vesting.owner.call(), accounts[0]);
    assert.equal(await this.vesting.ico.call(), this.sale.address);
    assert.equal(await this.vesting.token.call(), await this.sale.token.call());
    assert(await this.sale.activated.call());
    assert.equal(await this.token.balanceOf.call(0x30), 7 * 10 ** 24);
    assert.equal(await this.token.balanceOf.call(this.distributionContract.address), 161 * 10 ** 24)

    collected = await this.sale.raised.call();
    presold = await this.sale.raised.call();
    allocated = await this.sale.soldTokens.call();
    preallocated = await this.sale.soldTokens.call();
  });

  it("should fail if purchasing less than min", async function() {
    try {
      await this.sale.btcPurchase(accounts[9], 90);

      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("should fail if address not whitelisted", async function() {
    try {
      await this.sale.btcPurchase(accounts[8], 90);

      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("[BTC] 10 USD at 0.14 - should return the right amount with a maximum error of 0.001%", async function() {
    //Calculate tokens
    bought = await this.sale.computeTokens.call(10);
    error = math.abs(bought.valueOf() - 10 / 0.14 * 10 ** 18);

    //execute purchase
    let circulatingSupply = await this.vesting.circulatingSupply.call();
    let saleBalance = await this.token.balanceOf.call(this.sale.address);

    await this.sale.btcPurchase(accounts[9], 100);
    let newCirculatingSupply = await this.vesting.circulatingSupply.call();
    let newSaleBalance = await this.token.balanceOf.call(this.sale.address);

    let granted = await this.vesting.totalVestedTokens.call({
      from: accounts[9]
    });

    allocated = allocated.plus(granted);
    collected = collected.plus(10);

    assert(error < bought.valueOf() * this.maxError);
    assert.equal(granted.valueOf(), bought.valueOf());
    assert.equal(newSaleBalance, saleBalance - granted);
    assert.equal(newCirculatingSupply.valueOf(), circulatingSupply.valueOf());
    assert.equal(await this.sale.raised.call(), collected.valueOf());
    assert.equal(await this.sale.soldTokens.call(), allocated.valueOf());
  });

  it("[BTC] 49990 USD at 0.14 - should return the right amount with a maximum error of 0.001%", async function() {
    //Calculate tokens
    bought = await this.sale.computeTokens.call(49990);
    error = math.abs(bought.valueOf() - 49990 / 0.14 * 10 ** 18);

    //execute purchase
    let circulatingSupply = await this.vesting.circulatingSupply.call();
    let saleBalance = await this.token.balanceOf.call(this.sale.address);

    await this.sale.btcPurchase(accounts[9], 499900);
    let newCirculatingSupply = await this.vesting.circulatingSupply.call();
    let newSaleBalance = await this.token.balanceOf.call(this.sale.address);

    let granted = await this.vesting.totalVestedTokens.call({
      from: accounts[9]
    });

    allocated = allocated.plus(bought);
    collected = collected.plus(49990);

    assert(error < bought.valueOf() * this.maxError);
    assert.equal(granted.valueOf(), allocated.sub(preallocated));
    assert.equal(newSaleBalance.valueOf(), saleBalance.sub(bought));
    assert.equal(newCirculatingSupply.valueOf(), circulatingSupply.valueOf());
    assert.equal(await this.sale.raised.call(), collected.valueOf());
    assert.equal(await this.sale.soldTokens.call(), allocated.valueOf());
  });

  it("[ETH] 5,950,010 USD at 0.14 - should return right amount with a maximum error of 0.001%", async function() {
    //Calculate tokens
    bought = await this.sale.computeTokens.call(5950010 - presold);
    error = math.abs(bought.valueOf() - (5950010 - presold) / 0.14 * 10 ** 18);

    //execute purchase
    let circulatingSupply = await this.vesting.circulatingSupply.call();
    let saleBalance = await this.token.balanceOf.call(this.sale.address);

    await this.sale.sendTransaction({
      from: accounts[9],
      value: (5950010 - presold) * 100
    });
    let newCirculatingSupply = await this.vesting.circulatingSupply.call();
    let newSaleBalance = await this.token.balanceOf.call(this.sale.address);

    let granted = await this.vesting.totalVestedTokens.call({
      from: accounts[9]
    });

    allocated = allocated.plus(bought);
    collected = collected.plus(5950010 - presold);

    assert(error < bought.valueOf() * this.maxError);
    assert.equal(granted.valueOf(), allocated.sub(preallocated));
    assert.equal(newSaleBalance.valueOf(), saleBalance.sub(bought));
    assert.equal(newCirculatingSupply.valueOf(), circulatingSupply.valueOf());
    assert.equal(await this.sale.raised.call(), collected.valueOf());
    assert.equal(await this.sale.soldTokens.call(), allocated.valueOf());
  });

  it("Should fail if no contract owner", async function() {
    try {
      await this.sale.btcPurchase(accounts[9], 20000000, {
        from: accounts[9]
      });
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("Should be possible to stop the sale", async function() {
    this.sale.stop();
    try {
      await this.sale.btcPurchase(accounts[9], 70000000);
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("Should be possible to resume the sale", async function() {
    await this.sale.resume();
    await this.sale.btcPurchase(accounts[9], 100000);
  });

  it("Should be possible finalize sale", async function() {
    await this.sale.finalize(
      accounts[2],
      accounts[3],
      accounts[4],
      accounts[5]
    );

    let granted2 = await this.vesting.totalVestedTokens.call({
      from: accounts[2]
    });
    let granted3 = await this.vesting.totalVestedTokens.call({
      from: accounts[3]
    });
    let granted4 = await this.vesting.totalVestedTokens.call({
      from: accounts[4]
    });
    let granted5 = await this.vesting.totalVestedTokens.call({
      from: accounts[5]
    });

    let saleBalance = await this.token.balanceOf.call(this.sale.address);
    let supply = await this.token.totalSupply.call();

    let sold = await this.sale.soldTokens.call();
    let total = 70000000 * 10 ** 18;

    let soldFraction = sold / total;

    let poolA = 175000000 * 10 ** 18;
    let poolB = 168000000 * 10 ** 18;
    let poolC = 70000000 * 10 ** 18;
    let poolD = 49000000 * 10 ** 18;

    /* sold + allocated pools + 1% (7M) reserve allocated on sale init */
    let expectedSupply =
      poolA + poolB + poolC + poolD + 7000000 * 10 ** 18 + sold.toNumber() + 161000000 * 10 ** 18;

    assert(math.abs(granted2 - poolA) < 1 * 10 ** 18); //1 SDT or error margin
    assert(math.abs(granted3 - poolB) < 1 * 10 ** 18); //1 SDT or error margin
    assert(math.abs(granted4 - poolC) < 1 * 10 ** 18); //1 SDT or error margin
    assert(math.abs(granted5 - poolD) < 1 * 10 ** 18); //1 SDT or error margin
    assert.equal(saleBalance, 0);
    assert(math.abs(supply - expectedSupply) < 1 * 10 ** 18); //1 SDT or error margin
  });

  it("Should fail if distribution not started", async function() {
    try {
      await this.distributionContract.getStage.call();
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("Stage should be 0", async function() {
    await increaseTimeTo(latestTime() + 2001);
    assert.equal((await this.distributionContract.getStage.call()), 0);
  });

  it("Stage should be 1", async function() {
    await increaseTimeTo(latestTime() + 86400);
    assert.equal((await this.distributionContract.getStage.call()).toString(), 1);
  });

  it("Stage should be 2", async function() {
    await increaseTimeTo(latestTime() + 86400);
    assert.equal((await this.distributionContract.getStage.call()).toString(), 2);
  });

  it("Should fail if not wei/usd rate", async function() {
    try {
      await this.distributionContract.sendTransaction({
        from: accounts[7],
        value: 4000
      });
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("should fail if not owner", async function() {
    try {
      await this.distributionContract.setWeiUsdRate.call(10, {from: accounts[1]});
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("should fail if not initialized", async function() {
    await this.distributionContract.setWeiUsdRate(10);
    try {
      await this.distributionContract.sendTransaction({
        from: accounts[7],
        value: 4000
      });
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("4000 wei @ 10 wei/usd, @ 0.20 usd/sdt", async function() {
    await this.distributionContract.init(161000000 * 10 ** 18);
    await this.distributionContract.sendTransaction({
      from: accounts[7],
      value: 4000
    });

    distRaisedUSD = 400;
    distRaisedETH = 4000;
    distSold = 2000 * 10 ** 18;

    assert.equal(await this.token.balanceOf.call(accounts[7]), distSold);
    assert.equal(await this.distributionContract.raisedUSD.call(), distRaisedUSD);
    assert.equal(await this.distributionContract.raisedETH.call(), distRaisedETH);
    assert.equal(await this.distributionContract.soldTokens.call(), distSold);
    assert.equal(await this.distributionContract.sold.call(2), distSold);
    assert.equal(await this.distributionContract.contributions.call(accounts[7], 2), distSold);
  });

  it("4000 wei", async function() {
    await this.distributionContract.sendTransaction({
      from: accounts[7],
      value: 4000
    });

    let price = 0.2 + (19.8 * (distSold / 10 ** 18) / 161000000);
    let sold = 400 * 10 ** 18 / price;

    distRaisedUSD += 400;
    distRaisedETH += 4000;
    distSold += sold;

    assert.equal(await this.token.balanceOf.call(accounts[7]), distSold);
    assert.equal(await this.distributionContract.raisedUSD.call(), distRaisedUSD);
    assert.equal(await this.distributionContract.raisedETH.call(), distRaisedETH);
    assert.equal(await this.distributionContract.soldTokens.call(), distSold);
    assert.equal(await this.distributionContract.sold.call(2), distSold);
    assert.equal(await this.distributionContract.contributions.call(accounts[7], 2), distSold);
  });

  it("4000 wei on next stage", async function() {
    await increaseTimeTo(latestTime() + 86400);

    await this.distributionContract.sendTransaction({
      from: accounts[7],
      value: 4000
    });

    let price = 0.2 + (19.8 * (distSold / 10 ** 18) / 161000000);
    let sold = 400 * 10 ** 18 / price;

    distRaisedUSD += 400;
    distRaisedETH += 4000;
    distSold += sold;
    distStageSold = sold;

    assert(checkMaxError(await this.token.balanceOf.call(accounts[7]), distSold, this.maxError));
    assert.equal(await this.distributionContract.raisedUSD.call(), distRaisedUSD);
    assert.equal(await this.distributionContract.raisedETH.call(), distRaisedETH);
    assert(checkMaxError(await this.distributionContract.soldTokens.call(), distSold, this.maxError));
    assert(checkMaxError(await this.distributionContract.sold.call(3), sold, this.maxError));
    assert(checkMaxError(await this.distributionContract.contributions.call(accounts[7], 3), sold, this.maxError));
  });

  it("80000 wei from another account", async function() {
    await this.distributionContract.sendTransaction({
      from: accounts[6],
      value: 80000
    });

    let price = 0.2 + (19.8 * (distSold / 10 ** 18) / 161000000);
    let sold = 8000 * 10 ** 18 / price;

    distRaisedUSD += 8000;
    distRaisedETH += 80000;
    distSold += sold;
    distStageSold += sold;

    let bonus = 0.1 - (distStageSold / 10 ** 18) / 4410958.90411;
    acc6Bonus = sold * bonus;
    acc7Bonus = (distStageSold - sold) * bonus;

    assert(checkMaxError(await this.token.balanceOf.call(accounts[6]), sold, this.maxError));
    assert.equal(await this.distributionContract.raisedUSD.call(), distRaisedUSD);
    assert.equal(await this.distributionContract.raisedETH.call(), distRaisedETH);
    assert(checkMaxError(await this.distributionContract.soldTokens.call(), distSold, this.maxError));
    assert(checkMaxError(await this.distributionContract.sold.call(3), distStageSold, this.maxError));
    assert(checkMaxError(await this.distributionContract.contributions.call(accounts[6], 3), sold, this.maxError));
  });

  it("cant claim bonus if stage not finished", async function() {
    try {
      await this.distributionContract.claimBonus(3, {from: accounts[6]});
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    } 
  });

  it("should fail if exceeds the amount", async function() {
    try {
      await this.distributionContract.sendTransaction({
        from: accounts[7],
        value: 900000
      });
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("should allow up to the last stage", async function() {
    await increaseTimeTo(latestTime() + 86400 * 361);
    await this.distributionContract.sendTransaction({
      from: accounts[7],
      value: 900
    });
  });

  it("should fail if latest stage finished", async function() {
    await increaseTimeTo(latestTime() + 86400);
    try {
      await this.distributionContract.sendTransaction({
        from: accounts[7],
        value: 900
      });
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    } 
  });

  it("claim bonus", async function() {
    let supply = await this.token.totalSupply.call();

    let acc6 = await this.token.balanceOf.call(accounts[6]);
    let acc7 = await this.token.balanceOf.call(accounts[7]);

    let expectedSupply = supply.toNumber() - ((await this.distributionContract.stageCap.call()).toNumber() - acc6Bonus - acc7Bonus - (await this.distributionContract.sold.call(3)).toNumber());

    await this.distributionContract.claimBonus(3, {from: accounts[6]});

    //Should burn tokens on first claim
    assert(
      checkMaxError(
        (await this.token.totalSupply.call()), 
        expectedSupply,
        this.maxError
      )
    );

    await this.distributionContract.claimBonus(3, {from: accounts[7]});

    //Should not burn on second claim
    assert(
      checkMaxError(
        (await this.token.totalSupply.call()),
        expectedSupply,
        this.maxError
      )
    );

    assert(checkMaxError((await this.token.balanceOf(accounts[6])), acc6.toNumber() + acc6Bonus, this.maxError));
    assert(checkMaxError((await this.token.balanceOf(accounts[7])), acc7.toNumber() + acc7Bonus, this.maxError));
  });

  it("cant claim twice for the same stage", async function() {
    try {
      await this.distributionContract.claimBonus(3, {from: accounts[6]});
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    } 
  });

  it("should be possible to retrieve ETH", async function() {
    let ap = web3.eth.getBalance(accounts[5]).toNumber();
    let ac = web3.eth.getBalance(this.distributionContract.address).toNumber();

    await this.distributionContract.forwardFunds(10, accounts[5]);

    assert.equal(web3.eth.getBalance(accounts[5]).toNumber(), ap + 10);
    assert.equal(web3.eth.getBalance(this.distributionContract.address).toNumber(), ac - 10);
  });

  it("should fail if not owner", async function() {
    try {
      await this.distributionContract.forwardFunds(10, accounts[5], {from: accounts[5]});
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    } 
  });

});

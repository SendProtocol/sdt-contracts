"use strict";

const TokenSale = artifacts.require("./TokenSale.sol");
const SaleProxy = artifacts.require("./SaleProxy.sol");
const SDT = artifacts.require("./SDT.sol");
const TokenVesting = artifacts.require("./TokenVesting.sol");
const assertJump = require("./helpers/assertJump");
const math = require("mathjs");

contract("TokenSale", function(accounts) {
  let bought;
  let error;
  let allocated;
  let collected;

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

  it("should fail if not active", async function() {
    try {
      await this.sale.btcPurchase(0x1, 5000, 100, 10);
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("should fail if not owner", async function() {
    try {
      await this.sale.initialize(0x10, 0x20, 0x30, { from: accounts[1] });
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("should be possible to activate crowdsale", async function() {
    this.token = await SDT.new(this.sale.address);
    await this.sale.initialize(this.token.address, this.vesting.address, 0x30);
    await this.sale.allow(accounts[9]);

    this.proxy = await SaleProxy.new(this.sale.address, 5000, 100);
    await this.sale.addProxyContract(this.proxy.address);

    assert(await this.sale.activated.call());
    assert.equal(
      await this.token.balanceOf.call(this.sale.address),
      693 * 10 ** 24
    );
    assert.equal(
      await this.token.balanceOf.call(0x30),
      7 * 10 ** 24
    );
  });

  it("should be possible to activate vesting contract", async function() {
    await this.vesting.init(this.token.address, this.sale.address);
    assert(await this.vesting.initialized.call());
    assert(await this.vesting.active.call());
    assert.equal(await this.vesting.owner.call(), accounts[0]);
    assert.equal(await this.vesting.ico.call(), this.sale.address);
    assert.equal(await this.vesting.token.call(), await this.sale.token.call());
    assert.equal(await this.token.balanceOf.call(this.vesting.address), 0);
    await this.sale.setBtcUsdRate(10);
    await this.sale.setWeiUsdRate(100);
  });

  it("should fail if purchasing less than min", async function() {
    try {
      await this.proxy.btcPurchase(accounts[9], 90);

      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("should fail if address not whitelisted", async function() {
    try {
      await this.proxy.btcPurchase(accounts[8], 90);

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

    await this.proxy.btcPurchase(accounts[9], 100);
    let newCirculatingSupply = await this.vesting.circulatingSupply.call();
    let newSaleBalance = await this.token.balanceOf.call(this.sale.address);

    let granted = await this.vesting.totalVestedTokens.call({
      from: accounts[9]
    });

    allocated = granted;
    collected = 10;

    assert(error < bought.valueOf() * this.maxError);
    assert.equal(granted.valueOf(), bought.valueOf());
    assert.equal(newSaleBalance, saleBalance - granted);
    assert.equal(newCirculatingSupply.valueOf(), circulatingSupply.valueOf());
    assert.equal(await this.sale.raised.call(), collected);
    assert.equal(await this.sale.soldTokens.call(), granted.valueOf());
  });

  it("[BTC] 49990 USD at 0.14 - should return the right amount with a maximum error of 0.001%", async function() {
    //Calculate tokens
    bought = await this.sale.computeTokens.call(49990);
    error = math.abs(bought.valueOf() - 49990 / 0.14 * 10 ** 18);

    //execute purchase
    let circulatingSupply = await this.vesting.circulatingSupply.call();
    let saleBalance = await this.token.balanceOf.call(this.sale.address);

    await this.proxy.btcPurchase(accounts[9], 499900);
    let newCirculatingSupply = await this.vesting.circulatingSupply.call();
    let newSaleBalance = await this.token.balanceOf.call(this.sale.address);

    let granted = await this.vesting.totalVestedTokens.call({
      from: accounts[9]
    });

    allocated = allocated.plus(bought);
    collected += 49990;

    assert(error < bought.valueOf() * this.maxError);
    assert.equal(granted.valueOf(), allocated.valueOf());
    assert.equal(newSaleBalance.valueOf(), saleBalance - bought);
    assert.equal(newCirculatingSupply.valueOf(), circulatingSupply.valueOf());
    assert.equal(await this.sale.raised.call().valueOf(), collected);
    assert.equal(await this.sale.soldTokens.call(), granted.valueOf());
  });

  it("[ETH] 5,950,010 USD at 0.14 - should return right amount with a maximum error of 0.001%", async function() {
    //Calculate tokens
    bought = await this.sale.computeTokens.call(5950010);
    error = math.abs(bought.valueOf() - 5950010 / 0.14 * 10 ** 18);

    //execute purchase
    let circulatingSupply = await this.vesting.circulatingSupply.call();
    let saleBalance = await this.token.balanceOf.call(this.sale.address);

    await this.proxy.sendTransaction({from: accounts[9], value: 595001000});
    let newCirculatingSupply = await this.vesting.circulatingSupply.call();
    let newSaleBalance = await this.token.balanceOf.call(this.sale.address);

    let granted = await this.vesting.totalVestedTokens.call({
      from: accounts[9]
    });

    allocated = allocated.plus(bought);
    collected += 5950010;

    assert(error < bought.valueOf() * this.maxError);
    assert.equal(granted.valueOf(), allocated.valueOf());
    assert.equal(newSaleBalance.valueOf(), saleBalance.sub(bought).valueOf());
    assert.equal(newCirculatingSupply.valueOf(), circulatingSupply.valueOf());
    assert.equal(await this.sale.raised.call().valueOf(), collected);
    assert.equal(await this.sale.soldTokens.call(), granted.valueOf());
  });

  it(
    "[BTC] 2M USD with 6M and 10 USD sold," +
      "should return 999990 USD 0.14 and 1000010 with incremental price formula," +
      "with a maximum error of 0.001%",
    async function() {
      let val1 = 999990 / 0.14 * 10 ** 18;
      let val2 = 70000000 * math.log(1.07142928571) * 10 ** 18;

      bought = await this.sale.computeTokens.call(2000000);
      error = math.abs(bought.valueOf() - val1 - val2);

      //execute purchase
      let circulatingSupply = await this.vesting.circulatingSupply.call();
      let saleBalance = await this.token.balanceOf.call(this.sale.address);

      await this.proxy.btcPurchase(accounts[9], 20000000);
      let newCirculatingSupply = await this.vesting.circulatingSupply.call();
      let newSaleBalance = await this.token.balanceOf.call(this.sale.address);

      let granted = await this.vesting.totalVestedTokens.call({
        from: accounts[9]
      });

      allocated = allocated.plus(bought);
      collected += 2000000;

      assert(error < bought.valueOf() * this.maxError);
      assert.equal(granted.valueOf(), allocated.valueOf());
      assert.equal(newSaleBalance.valueOf(), saleBalance.sub(bought).valueOf());
      assert.equal(newCirculatingSupply.valueOf(), circulatingSupply.valueOf());
      assert.equal(await this.sale.raised.call().valueOf(), collected);
      assert.equal(await this.sale.soldTokens.call(), granted.valueOf());
    }
  );

  it(
    "[ETH] 7M USD with 8M and 10 USD sold, should return the right amout " +
      "with a maximum error of 0.001%",
    async function() {
      let val1 = 70000000 * math.log(1.46666635556) * 10 ** 18;

      bought = await this.sale.computeTokens.call(7000000);
      error = math.abs(bought.valueOf() - val1);

      //execute purchase
      let circulatingSupply = await this.vesting.circulatingSupply.call();
      let saleBalance = await this.token.balanceOf.call(this.sale.address);

      await this.proxy.sendTransaction({from: accounts[9], value: 700000000});
      let newCirculatingSupply = await this.vesting.circulatingSupply.call();
      let newSaleBalance = await this.token.balanceOf.call(this.sale.address);

      let granted = await this.vesting.totalVestedTokens.call({
        from: accounts[9]
      });

      allocated = allocated.plus(bought);
      collected += 7000000;

      assert(error < bought.valueOf() * this.maxError);
      assert.equal(granted.valueOf(), allocated.valueOf());
      assert.equal(newSaleBalance.valueOf(), saleBalance.sub(bought).valueOf());
      assert.equal(newCirculatingSupply.valueOf(), circulatingSupply.valueOf());
      assert.equal(await this.sale.raised.call().valueOf(), collected);
      assert.equal(await this.sale.soldTokens.call(), granted.valueOf());
    }
  );

  it(
    "[ETH] 49999 USD with 15M and 10 USD sold, should return the right amout " +
      "with a maximum error of 0.001%",
    async function() {
      let val1 = 70000000 * math.log(1.00227268079) * 10 ** 18;

      bought = await this.sale.computeTokens.call(49999);
      error = math.abs(bought.valueOf() - val1);

      //execute purchase
      let circulatingSupply = await this.vesting.circulatingSupply.call();
      let saleBalance = await this.token.balanceOf.call(this.sale.address);

      await this.proxy.sendTransaction({from: accounts[9], value: 4999900});
      let newCirculatingSupply = await this.vesting.circulatingSupply.call();
      let newSaleBalance = await this.token.balanceOf.call(this.sale.address);

      let granted = await this.vesting.totalVestedTokens.call({
        from: accounts[9]
      });

      allocated = allocated.plus(bought);
      collected += 49999;

      assert(error < bought.valueOf() * this.maxError);
      assert.equal(granted.valueOf(), allocated.valueOf());
      assert.equal(newSaleBalance.valueOf(), saleBalance.sub(bought).valueOf());
      assert.equal(newCirculatingSupply.valueOf(), circulatingSupply.valueOf());
      assert.equal(await this.sale.raised.call().valueOf(), collected);
      assert.equal(await this.sale.soldTokens.call(), granted.valueOf());
    }
  );

  it("Should be possible to stop the sale", async function() {
    this.sale.stop();
    try {
      await this.proxy.btcPurchase(accounts[9], 70000000);
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("Should be possible to resume the sale", async function() {
    await this.sale.resume();
    await this.proxy.btcPurchase(accounts[9], 70000000);
  });

  it("Should be possible finalize sale", async function() {
    await this.sale.finalize(accounts[2], accounts[3], accounts[4], accounts[5],);

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
    let total = 231000000 * 10 ** 18;

    let soldFraction =  sold / total;

    let poolA = soldFraction * 175000000 * 10 ** 18;
    let poolB = soldFraction * 168000000 * 10 ** 18;
    let poolC = soldFraction * 70000000 * 10 ** 18;
    let poolD = 49000000 * 10 ** 18;

    /* sold + allocated pools + 1% (7M) reserve allocated on sale init */
    let expectedSupply = poolA + poolB + poolC + poolD + 7000000 * 10 ** 18 + sold.toNumber(); 

    assert(math.abs(granted2 - poolA) < 1 * 10 ** 18); //1 SDT or error margin
    assert(math.abs(granted3 - poolB) < 1 * 10 ** 18); //1 SDT or error margin
    assert(math.abs(granted4 - poolC) < 1 * 10 ** 18); //1 SDT or error margin
    assert(math.abs(granted5 - poolD) < 1 * 10 ** 18); //1 SDT or error margin
    assert.equal(saleBalance, 0)
    assert(math.abs(supply -  expectedSupply) < 1 * 10 ** 18) //1 SDT or error margin

  });

  it("[BTC] Should allocate the right amount", async function() {
    this.sale = await TokenSale.new(
      this.currentDate - 1,
      this.currentDate + 1000,
      accounts[7],
      this.currentDate + 100
    );
    this.vesting = await TokenVesting.new();
    this.token = await SDT.new(this.sale.address);
    await this.sale.initialize(this.token.address, this.vesting.address, 0x30);
    await this.sale.allow(accounts[9]);

    this.proxy = await SaleProxy.new(this.sale.address, 5000, 100);
    await this.sale.addProxyContract(this.proxy.address);

    assert(await this.sale.activated.call());

    await this.vesting.init(this.token.address, this.sale.address);
    await this.sale.setBtcUsdRate(10);
    await this.sale.setWeiUsdRate(100);

    await this.proxy.btcPurchase(accounts[9], 69999990);

    //Calculate tokens
    bought = await this.sale.computeTokens.call(49999);
    error = math.abs(bought.valueOf() - 
            1 / 0.14 * 10 ** 18 - 
            70000000 * math.log(1.00357128597) * 10 ** 18);

    //execute purchase
    let circulatingSupply = await this.vesting.circulatingSupply.call();
    let saleBalance = await this.token.balanceOf.call(this.sale.address);

    await this.proxy.sendTransaction({from: accounts[9], value: 499990});
    let newCirculatingSupply = await this.vesting.circulatingSupply.call();
    let newSaleBalance = await this.token.balanceOf.call(this.sale.address);

    let granted = await this.vesting.totalVestedTokens.call({
      from: accounts[9]
    });

    collected = 6999999 + 49999;

    assert(error < bought.valueOf() * this.maxError);
  });

});

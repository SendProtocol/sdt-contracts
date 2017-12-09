"use strict";

const TokenSale = artifacts.require("./TokenSale.sol");
const SDT = artifacts.require("./SDT.sol");
const TokenVesting = artifacts.require("./TokenVesting.sol");
const assertJump = require("./helpers/assertJump");
const math = require("mathjs");

contract("TokenSale", function(accounts) {
  let sale;
  let vesting;
  let token;
  let bought;
  let error;
  let allocated;
  let collected;
  let maxError = 0.00001;
  let currentDate = math.floor(Date.now() / 1000);

  it("should fail if not active", async function() {
    sale = await TokenSale.deployed();
    vesting = await TokenVesting.deployed();
    try {
      await sale.purchase(10, 0, 0, 0x1, 100, currentDate + 5000, 0);
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("should fail if not owner", async function() {
    try {
      await sale.deploy(700 * 10 ** 6, 0, 0x20, { from: accounts[1] });
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("should be possible to activate crowdsale", async function() {
    await sale.deploy(700 * 10 ** 6, 0, vesting.address);

    let _tokenAddress = await sale.token.call();
    token = await SDT.at(_tokenAddress);

    assert(sale.activated.call());
    assert.equal(await token.balanceOf.call(sale.address), 700 * 10 ** 24);
  });

  it("should be possible to activate vesting contract", async function() {
    vesting.init(token.address, sale.address);
    assert(await vesting.initialized.call());
    assert(await vesting.active.call());
    assert.equal(await vesting.owner.call(), accounts[0]);
    assert.equal(await vesting.ico.call(), sale.address);
    assert.equal(await vesting.token.call(), await sale.token.call());
    assert.equal(await token.balanceOf.call(vesting.address), 0);
  });

  it("should fail if purchasing less than min", async function() {
    try {
      await sale.purchase(9, 0, 0, 0x1, 100, currentDate + 5000, 0);
      assert.fail("should have thrown before");
    } catch (error) {
      assertJump(error);
    }
  });

  it("10 USD at 0.14 - should return the right amount with a maximum error of 0.001%", async function() {
    //Calculate tokens
    bought = await sale.computeTokens.call(10);
    error = math.abs(bought.valueOf() - 10 / 0.14 * 10 ** 18);

    //execute purchase
    let circulatingSupply = await vesting.circulatingSupply.call();
    let saleBalance = await token.balanceOf.call(sale.address);
    await sale.purchase(10, 10, 0, accounts[9], 100, currentDate + 5000, 0);
    let newCirculatingSupply = await vesting.circulatingSupply.call();
    let newSaleBalance = await token.balanceOf.call(sale.address);

    let granted = await vesting.totalVestedTokens.call({ from: accounts[9] });

    allocated = granted;
    collected = 10;

    assert(error < bought.valueOf() * maxError);
    assert.equal(granted.valueOf(), bought.valueOf());
    assert.equal(newSaleBalance, saleBalance - granted);
    assert.equal(newCirculatingSupply.valueOf(), circulatingSupply.valueOf());
    assert.equal(await sale.raised.call(), collected);
    assert.equal(await sale.soldTokens.call(), granted.valueOf());
  });

  it("6M USD at 0.14 - should return right amount with a maximum error of 0.001%", async function() {
    //Calculate tokens
    bought = await sale.computeTokens.call(6000000);
    error = math.abs(bought.valueOf() - 6000000 / 0.14 * 10 ** 18);

    //execute purchase
    let circulatingSupply = await vesting.circulatingSupply.call();
    let saleBalance = await token.balanceOf.call(sale.address);
    await sale.purchase(6000000, 0, 0, accounts[9], 100, currentDate + 5000, 0);
    let newCirculatingSupply = await vesting.circulatingSupply.call();
    let newSaleBalance = await token.balanceOf.call(sale.address);

    let granted = await vesting.totalVestedTokens.call({ from: accounts[9] });

    allocated = allocated.plus(bought);
    collected += 6000000;

    assert(error < bought.valueOf() * maxError);
    assert.equal(granted.valueOf(), allocated.valueOf());
    assert.equal(newSaleBalance.valueOf(), saleBalance - bought);
    assert.equal(newCirculatingSupply.valueOf(), circulatingSupply.valueOf());
    assert.equal(await sale.raised.call().valueOf(), collected);
    assert.equal(await sale.soldTokens.call(), granted.valueOf());

    assert(error < bought.valueOf() * maxError);
  });

  it(
    "2M USD with 6M and 10 USD sold," +
      "should return 999990 USD 0.14 and 1000010 with incremental price formula," +
      "with a maximum error of 0.001%",
    async function() {
      let val1 = 999990 / 0.14 * 10 ** 18;
      let val2 = 70000000 * math.log(1.07142928571) * 10 ** 18;

      bought = await sale.computeTokens.call(2000000);
      error = math.abs(bought.valueOf() - val1 - val2);

      //execute purchase
      let circulatingSupply = await vesting.circulatingSupply.call();
      let saleBalance = await token.balanceOf.call(sale.address);
      await sale.purchase(
        2000000,
        0,
        0,
        accounts[9],
        100,
        currentDate + 5000,
        0
      );
      let newCirculatingSupply = await vesting.circulatingSupply.call();
      let newSaleBalance = await token.balanceOf.call(sale.address);

      let granted = await vesting.totalVestedTokens.call({ from: accounts[9] });

      allocated = allocated.plus(bought);
      collected += 2000000;

      assert(error < bought.valueOf() * maxError);
      assert.equal(granted.valueOf(), allocated.valueOf());
      assert.equal(newSaleBalance.valueOf(), saleBalance.sub(bought).valueOf());
      assert.equal(newCirculatingSupply.valueOf(), circulatingSupply.valueOf());
      assert.equal(await sale.raised.call().valueOf(), collected);
      assert.equal(await sale.soldTokens.call(), granted.valueOf());
    }
  );

  it(
    "7M USD with 8M and 10 USD sold, should return the right amout " +
      "with a maximum error of 0.001%",
    async function() {
      let val1 = 70000000 * math.log(1.46666635556) * 10 ** 18;

      bought = await sale.computeTokens.call(7000000);
      error = math.abs(bought.valueOf() - val1);

      //execute purchase
      let circulatingSupply = await vesting.circulatingSupply.call();
      let saleBalance = await token.balanceOf.call(sale.address);
      await sale.purchase(
        7000000,
        0,
        0,
        accounts[9],
        100,
        currentDate + 5000,
        0
      );
      let newCirculatingSupply = await vesting.circulatingSupply.call();
      let newSaleBalance = await token.balanceOf.call(sale.address);

      let granted = await vesting.totalVestedTokens.call({ from: accounts[9] });

      allocated = allocated.plus(bought);
      collected += 7000000;

      assert(error < bought.valueOf() * maxError);
      assert.equal(granted.valueOf(), allocated.valueOf());
      assert.equal(newSaleBalance.valueOf(), saleBalance.sub(bought).valueOf());
      assert.equal(newCirculatingSupply.valueOf(), circulatingSupply.valueOf());
      assert.equal(await sale.raised.call().valueOf(), collected);
      assert.equal(await sale.soldTokens.call(), granted.valueOf());
    }
  );
});

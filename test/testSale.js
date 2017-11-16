'use strict';

const TokenSale = artifacts.require('./TokenSale.sol');
const SDT = artifacts.require('./SDT.sol');
const assertJump = require('./helpers/assertJump');
const math = require('mathjs');

contract('TokenSale', function(accounts) {
	let sale;
	let token;
	let bought;
	let error;
	let maxError = 0.00001;
	let currentDate = math.floor(Date.now() / 1000);

    it('should fail if not active', async function() 
    {
        sale = await TokenSale.deployed();
		try {
			await sale.purchase(10, 0, 0, 0x1, 100, currentDate + 5000, 0);
			assert.fail('should have thrown before');
		} catch(error) {
			assertJump(error);
		}
    });

    it('should fail if not owner', async function() 
    {
		try {
			await sale.deploy(700*10**6, 0, {from: accounts[1]});
			assert.fail('should have thrown before');
		} catch(error) {
			assertJump(error);
		}
    });

    it('should be possible to activate crowdsale', async function() 
    {
        await sale.deploy(700*10**6, 0);
        assert (sale.activated.call());

    	let _tokenAddress = await sale.token.call();
    	token = await SDT.at(_tokenAddress);
    	assert.equal(await token.balanceOf.call(accounts[1]), 700 * 10 ** 24);
    });

    it('should fail if purchasing less than min', async function() 
    {
		try {
			await sale.purchase(9, 0, 0, 0x1, 100, currentDate + 5000, 0);
			assert.fail('should have thrown before');
		} catch(error) {
			assertJump(error);
		}
    });

    it('10 USD at 0.14 - should return the right amount with a maximum error of 0.001%', async function() 
    {
        bought = await sale.computeTokens(10);
        await sale.purchase(10, 0, 0, 0x1, 100, currentDate + 5000, 0);
        error = math.abs(bought.valueOf() - 10/0.14 * 10**18);

        assert(error < bought.valueOf() * maxError);
    });

    it('6M USD at 0.14 - should return right amount with a maximum error of 0.001%', async function() 
    {
    	bought = await sale.computeTokens(6000000);
        await sale.purchase(6000000, 0, 0, 0x1, 100, currentDate + 5000, 0);
        error = math.abs(bought.valueOf() - 6000000/0.14 * 10**18);

        assert(error < bought.valueOf() * maxError);
    });

    it('2M USD with 6M and 10 USD sold,' +
    	'should return 999990 USD 0.14 and 1000010 with incremental price formula,' +
    	'with a maximum error of 0.001%', async function() 
    {
        let val1 = 999990/0.14 * 10**18;
        let val2 = 70000000 * math.log(1.07142928571) * 10 ** 18;

    	bought = await sale.computeTokens(2000000);
        await sale.purchase(2000000, 0, 0, 0x1, 100, currentDate + 5000, 0);

        error = math.abs(bought.valueOf() - val1 - val2);

        assert(error < bought.valueOf() * maxError);
    });

    it('7M USD with 8M and 10 USD sold, should return the right amout ' +
    	'with a maximum error of 0.001%', async function() 
    {
    	let val1 = 70000000 * math.log(1.46666635556) * 10 ** 18;

    	bought = await sale.computeTokens(7000000);
        await sale.purchase(7000000, 0, 0, 0x1, 100, currentDate + 5000, 0);
        error = math.abs(bought.valueOf() - val1);

        assert(error < bought.valueOf() * maxError);
    });


});

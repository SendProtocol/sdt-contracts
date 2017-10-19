const SDT = artifacts.require("./SDT.sol");

contract('SDT', function(accounts) {

    it("contract deploy should put 700M * 10^18 SDT in the first account", async function() {
        let sdtInstance = await SDT.deployed();
        let balance = await sdtInstance.balanceOf.call(accounts[0])
        assert.equal(balance.valueOf(), 700*10**24, "700M * 10^18 wasn't in the first account");
    });

});

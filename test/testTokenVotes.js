const SDT = artifacts.require("./SDT.sol");

function amount(a){
	return a*10**18;
}

contract('SDT', function(accounts) {
	let token;

	it("a verified user can create a poll", async function() {
		token = await SDT.new(1);
		await token.createPoll(1, "is this working?", ["yes", "nope"], 1, 0, 32503680000);
		let poll = await token.polls.call(1);
		assert.equal(poll[0], accounts[0]);
		assert.equal(poll[1].valueOf(), 1);
		assert.equal(poll[2].valueOf(), 0);
		assert.equal(poll[3].valueOf(),32503680000);
	})
})
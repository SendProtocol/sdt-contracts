"use strict";

const SDT = artifacts.require("./SDT.sol");
const Polls = artifacts.require("./Polls.sol");
const assertJump = require("./helpers/assertJump");
const { increaseTimeTo, duration } = require("./helpers/time.js");

contract("Polls", function(accounts) {
  let poll;
  let token;
  let polls;
  let activePoll;

  let futureDate = new Date().valueOf() + 3600;

  describe("create poll", function() {
    it("should store new poll if user is owner", async function() {
      token = await SDT.new(1, accounts[0], accounts[1], 100);
      polls = await Polls.new(token.address);
      await token.setPolls(polls.address);

      assert.equal(await token.snapshotBlock.call(), 0);

      await polls.createPoll(
        "is this working?",
        ["yes", "nope"],
        1,
        futureDate
      );

      poll = await polls.poll.call();

      assert.equal(await token.snapshotBlock.call(), poll[0].valueOf());
      assert.equal(poll[1].valueOf(), 1);
      assert.equal(poll[2].valueOf(), futureDate);
    });

    it("should fail if another user user tries to create a poll", async function() {
      try {
        await polls.createPoll(
          "is this working?",
          ["yes", "nope"],
          1,
          futureDate,
          { from: accounts[1] }
        );
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });
  });

  describe("vote", function() {
    it("should return true if voting user meets condition", async function() {
      token = await SDT.new(1, accounts[0], accounts[1], 100);
      polls = await Polls.new(token.address);
      await token.setPolls(polls.address);

      await polls.createPoll(
        "is this working?",
        ["yes", "nope"],
        1,
        futureDate
      );
      let response = await polls.vote(1);
      assert(response);
    });

    it("should fail if user tries to vote a second time in the same poll", async function() {
      try {
        await polls.vote(1);
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should fail if an user with no enough tokens tries to vote", async function() {
      try {
        await polls.vote(1, { from: accounts[1] });
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should fail if an user with no enough tokens at the time of the poll tries to vote", async function() {
      await polls.vote(1);
      await token.transfer(await token.balanceOf(accounts[0]), accounts[1]);
      try {
        await polls.vote(1, { from: accounts[1] });
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("should fail if user tries to vote after end date", async function() {
      await polls.createPoll("is this working?", ["yes", "nope"], 1, 1);
      try {
        await polls.vote(1);
        assert.fail("should have thrown before");
      } catch (error) {
        assertJump(error);
      }
    });

    it("Should show results after time has passed", async function() {
      token = await SDT.new(1, accounts[0], accounts[1], 100);
      polls = await Polls.new(token.address);
      await token.setPolls(polls.address);

      await polls.createPoll(
        "is this working?",
        ["yes", "nope"],
        1,
        new Date().valueOf() + duration.minutes(1)
      );
      await polls.vote(1);
      await increaseTimeTo(new Date().valueOf() + duration.minutes(2));
      assert.equal(await polls.showResults(0), 0);
      assert.equal(await polls.showResults(1), 1);
    });
  });
});

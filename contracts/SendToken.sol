pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import './SCNS1.sol';

contract SendToken is StandardToken, SCNS1 {
	
	//Voting
	struct poll {
		address creator;
		bytes32 question;
		bytes32[] options;
		uint256 minimumTokens;
		uint256 startTime;
		uint256 endTime;
	}

	mapping (uint256 => poll) internal polls;
	mapping (address => bool) internal isVerified;
	mapping (uint256 => mapping(address => bool)) internal voted;

	function createPoll(uint256 _id, bytes32 _question, bytes32[] _options, uint256 _minimumTokens, uint256 _startTime, uint256 _endTime) public returns (bool){
		require(isVerified[msg.sender]);
		require(polls[_id].creator != 0);
		polls[_id].creator = msg.sender;
		polls[_id].question = _question;
		polls[_id].options = _options;
		polls[_id].minimumTokens = _minimumTokens;
		polls[_id].startTime = _startTime;
		polls[_id].endTime = _endTime;
		PollCreated(msg.sender, _id, _question, _options, _minimumTokens, _startTime, _endTime);
		return true;
	}
	function vote(uint256 _id, uint256 _option) public returns (bool){
		require(polls[_id].creator != 0);
		require(voted[_id][msg.sender] == false);
		require(balances[msg.sender] >= polls[_id].minimumTokens);
		require(polls[_id].startTime >= block.timestamp);
		require(polls[_id].endTime <= block.timestamp);
		voted[_id][msg.sender] = true;
		Voted(_id, msg.sender, _option);
		return true;
	}
	/*
	//Escrow
	function approveLockedTransfer(address to, address authority, uint256 referenceId, uint256 value, uint256 authorityFee, uint256 expirationTime, bool backIfExpires){

	}
	function executeLockedTransfer(address sender, uint256 referenceId){

	}
	function rollbackLockedTransfer(address sender, uint256 referenceId){

	}
	function claimLockedTransfer(address sender, address authority, uint256 referenceId){

	}
	function invalidateLockedTransferExpiration(address sender, uint256 referenceId){

	}
	*/
	//Consensus Network
	function verifiedTransferFrom(address _from, address _to, uint256 _value, uint256 _referenceId, uint256 _exchangeRate, uint256 _fee) public returns (bool) {
		require(_to != address(0));

		uint256 total = _value.add(_fee);

		require(total <= balances[_from]);
		require(total <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);

		if(_fee >= 0){
			balances[_from] = balances[_from].sub(_fee);
			balances[msg.sender] = balances[msg.sender].add(_fee);
		}

		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(total);
		VerifiedTransfer(_from, _to, msg.sender, _value, _referenceId, _exchangeRate);

		return true;
		}

}
pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import './SCNS1.sol';

contract SendToken is StandardToken, SCNS1 {
	/*
	//Voting
	function createPoll(uint256 _id, bytes32 _question, bytes32[] _options, uint256 _minimumTokens, uint256 _startTime, uint256 _endTime){

	}
	function vote(uint256 id, bytes32 option){

	}
	function getResultsForOption(uint256 id, bytes32 option){

	}

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
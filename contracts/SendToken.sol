pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import './SCNS1.sol';

contract SendToken is StandardToken, SCNS1 {

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

	//Consensus Network
	function verifiedTransferFrom(address from, address to, uint256 value, uint256 referenceId, uint256 exchangeRate){

	}

}
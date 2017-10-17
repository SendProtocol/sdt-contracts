pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/token/ERC20.sol';

contract SCNS1 is ERC20 {

	//Voting
	function createPoll(uint256 id, bytes32 question, bytes32[] options, uint256 minimumTokens, uint256 startTime, uint256 endTime) public returns (bool);
	function vote(uint256 id, bytes32 option) public returns (bool);
	function getResultsForOption(uint256 id, bytes32 option) public returns (bool);
	event PollCreated(address indexed creator, uint256 indexed id, bytes32 question, bytes32[] options, uint256 minimumTokens, uint256 startTime, uint256 endTime);

	//Escrow
	function approveLockedTransfer(address to, address authority, uint256 referenceId, uint256 value, uint256 authorityFee, uint256 expirationTime, bool backIfExpires) public returns (uint256);
	function executeLockedTransfer(address sender, uint256 referenceId) public returns (bool);
	function rollbackLockedTransfer(address sender, uint256 referenceId) public returns (bool);
	function claimLockedTransfer(address sender, address authority, uint256 referenceId) public returns (bool);
	function invalidateLockedTransferExpiration(address sender, uint256 referenceId) public returns (bool);
	event EscrowCreated(address indexed sender, address indexed recipient, address authority, uint256 referenceId);
	event EscrowResolved(address indexed sender, address indexed recipient, address authority, uint256 referenceId, address resolver, address sentTo);

	//Consensus Network
	function verifiedTransferFrom(address from, address to, uint256 value, uint256 referenceId, uint256 exchangeRate) public returns (bool);
	event EerifiedTransfer(address indexed owner, address indexed spender, uint256 value, uint256 referenceId, uint256 exchangeRate);
}
pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import './SCNS1.sol';

contract SendToken is SCNS1, StandardToken {
	
	struct poll {
		address creator;
		uint256 minimumTokens;
		uint256 startTime;
		uint256 endTime;
	}

	struct lock {
		uint256 value;
		uint256 fee;
		uint256 expirationTime;
	}

	address public owner;

	mapping (uint256 => poll) public polls;
	mapping (address => bool) internal verifiedAddresses;
	mapping (address => uint256) internal lockedBalances;
	mapping (uint256 => mapping(address => bool)) internal voted;
	mapping (address => mapping(address => mapping(uint256 => lock))) internal lockedAllowed;

	function isVerified(address _address) public constant returns (bool){
		return verifiedAddresses[_address];
	}

	function lockedBalanceOf(address _owner) public constant returns (uint256){
		return lockedBalances[_owner];
	}

	function verify(address _address) returns (bool) {
		require(msg.sender == owner);
		verifiedAddresses[_address] = true;
		return true;
	}

	function unverify(address _address) returns (bool) {
		require(msg.sender == owner);
		verifiedAddresses[_address] = false;
		return true;
	}

	function createPoll(uint256 _id, bytes32 _question, bytes32[] _options, uint256 _minimumTokens, uint256 _startTime, uint256 _endTime) public returns (bool){
		require(verifiedAddresses[msg.sender]);
		require(polls[_id].creator == 0);

		polls[_id].creator = msg.sender;
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
		require(polls[_id].startTime <= block.timestamp);
		require(polls[_id].endTime >= block.timestamp);

		voted[_id][msg.sender] = true;
		Voted(_id, msg.sender, _option);

		return true;
	}

	function approveLockedTransfer(address _authority, uint256 _referenceId, uint256 _value, uint256 _authorityFee, uint256 _expirationTime) public returns (bool){
		uint256 total = _value + _authorityFee;

		require(lockedAllowed[msg.sender][_authority][_referenceId].value == 0);
		require(balances[msg.sender] >= total);

		lockedAllowed[msg.sender][_authority][_referenceId].value = _value;
		lockedAllowed[msg.sender][_authority][_referenceId].fee = _authorityFee;
		lockedAllowed[msg.sender][_authority][_referenceId].expirationTime = _expirationTime;

		lockedBalances[msg.sender] = lockedBalances[msg.sender].add(total);
		balances[msg.sender] = balances[msg.sender].sub(total);

		EscrowCreated(msg.sender, _authority, _referenceId);

		return true;
	}

	function executeLockedTransfer(address _sender, address _recipient, uint256 _referenceId, uint256 _exchangeRate) public returns (bool){
		uint256 _value = lockedAllowed[_sender][msg.sender][_referenceId].value;
		uint256 _fee = lockedAllowed[_sender][msg.sender][_referenceId].fee;

		require(_value > 0);

		if (verifiedAddresses[msg.sender]){
			require(_exchangeRate > 0);
		} else {
			require(_exchangeRate == 0);
		}

		lockedBalances[_sender] = lockedBalances[_sender].sub(_value + _fee);
		balances[_recipient] = balances[_recipient].add(_value);
		if(_fee > 0) balances[msg.sender] = balances[msg.sender].add(_fee);

		delete lockedAllowed[_sender][msg.sender][_referenceId];

		EscrowResolved(_sender, msg.sender, _referenceId, msg.sender, _recipient);

		if(_sender == _recipient) return true;

		if(_exchangeRate == 0) {
			Transfer(_sender, _recipient, _value);
		} else {
			VerifiedTransfer(_sender, _recipient, msg.sender, _value, _referenceId, _exchangeRate);
		}
		return true;

	}
	function claimLockedTransfer(address _authority, uint256 _referenceId) public returns (bool){
		require(lockedAllowed[msg.sender][_authority][_referenceId].value > 0);
		require(lockedAllowed[msg.sender][_authority][_referenceId].expirationTime < block.timestamp);
		require(lockedAllowed[msg.sender][_authority][_referenceId].expirationTime != 0);

		uint256 _value = lockedAllowed[msg.sender][_authority][_referenceId].value;
		uint256 _fee = lockedAllowed[msg.sender][_authority][_referenceId].fee;

		lockedBalances[msg.sender] = lockedBalances[msg.sender].sub(_value.add(_fee));
		balances[msg.sender] = balances[msg.sender].add(_value.add(_fee));

		delete lockedAllowed[msg.sender][_authority][_referenceId];

		EscrowResolved(msg.sender, _authority, _referenceId, msg.sender, msg.sender);
		return true;
	}

	function invalidateLockedTransferExpiration(address _sender, uint256 _referenceId) public returns (bool){
		require(lockedAllowed[_sender][msg.sender][_referenceId].value > 0);
		lockedAllowed[_sender][msg.sender][_referenceId].expirationTime = 0;
		return true;
	}
	
	function verifiedTransferFrom(address _from, address _to, uint256 _value, uint256 _referenceId, uint256 _exchangeRate, uint256 _fee) public returns (bool) {
		require(verifiedAddresses[msg.sender]);
		require(_to != address(0));
		require(_exchangeRate > 0);

		uint256 total = _value.add(_fee);

		require(total <= balances[_from]);
		require(total <= allowed[_from][msg.sender]);

		balances[_from] = balances[_from].sub(total);
		balances[_to] = balances[_to].add(_value);
		if(_fee >= 0) balances[msg.sender] = balances[msg.sender].add(_fee);

		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(total);
		VerifiedTransfer(_from, _to, msg.sender, _value, _referenceId, _exchangeRate);

		return true;
		}

}
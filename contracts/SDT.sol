pragma solidity ^0.4.15;

import './SendToken.sol';

contract SDT is SendToken {
	string public name = "SEND Token";
	string public symbol = "SDT";
	uint256 public decimals = 18;

	function SDT(uint256 _supply){
		balances[msg.sender] = _supply;
		totalSupply = _supply;
	}

}
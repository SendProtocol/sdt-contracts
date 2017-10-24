pragma solidity ^0.4.15;

import './SendToken.sol';


contract SDT is SendToken {
	string public name = 'SEND Token';
	string public symbol = 'SDT';
	uint256 public decimals = 18;

	function SDT(uint256 _supply){
		uint256 supply = _supply*10**decimals;
		owner = msg.sender;
		verifiedAddresses[msg.sender] = true;
		balances[msg.sender] = supply;
		totalSupply = supply;
	}	

}
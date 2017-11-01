pragma solidity ^0.4.15;

import './SendToken.sol';


contract SDT is SendToken {
	string public name = 'SEND Token';
	string public symbol = 'SDT';
	uint256 public decimals = 18;

    modifier validAddress(address _address){
        require(_address != address(0x0));
        _;
    }

    function SDT (
    	uint256 _supply,
        address _owner,
        address _saleWallet,
        uint8 _ownerPool,
        uint8 _salePool
    )
        validAddress(_owner)
        validAddress(_saleWallet)
    {
        require (_ownerPool + _salePool == 100);

		maxSupply = _supply*10**decimals;

		owner = _owner;
		ico = msg.sender;
		saleWallet = _saleWallet;

		verifiedAddresses[msg.sender] = true;

		balances[_owner] = maxSupply * _ownerPool / 100;
		balances[_saleWallet] = maxSupply * _salePool / 100;	

		totalSupply = balances[_owner];
    }

}
pragma solidity ^0.4.18;

import './SendToken.sol';

/**
 * @title To instance SendToken for SEND foundation crowdasale
 * @dev see https://send.sd/token
 */
contract SDT is SendToken {
  string public name = 'SEND Token';
  string public symbol = 'SDT';
  uint256 public decimals = 18;

  modifier validAddress(address _address){
    require(_address != address(0x0));
    _;
  }

  /**
  * @dev Constructor
  * @param _supply Number of tokens
  * @param _owner The owner of this contract
  * @param _sale Address that will hold all vesting allocated tokens
  * @param _ownerPool Percentage of tokens to allocate on owner address
  * @notice _supply*10^18 will be created
  * @notice contract owner will have special powers in the contract
  * @notice _sale should hold all tokens in production as all pool will be vested
  * @notice _salewallet will get all tokens not assigned to owner address
  * @return A uint256 representing the locked amount of tokens
  */
  function SDT(
      uint256 _supply,
      address _owner,
      address _sale,
      uint256 _ownerPool
  ) public validAddress(_owner) validAddress(_sale) {
    require(_ownerPool <= 100);
    maxSupply = _supply * 10**decimals;

    owner = _owner;
    ico = msg.sender;
    saleWallet = _sale;

    verifiedAddresses[msg.sender] = true;

    balances[_owner] = maxSupply * _ownerPool / 100;
    balances[_sale] = maxSupply * (100 - _ownerPool) / 100;

    totalSupply = balances[_owner];
  }
}

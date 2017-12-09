pragma solidity ^0.4.18;

/**
 * @title SCNS1 (Send Consensus Network Standard v1) interface
 * @dev token interface built on top of ERC20 standard interface
 * @dev see https://send.sd/token
 */
contract SCNS1 {
  function isVerified(address _address) public constant returns(bool);

  function verify(address _address) public;

  function unverify(address _address) public;

  function verifiedTransferFrom(
      address from,
      address to,
      uint256 value,
      uint256 referenceId,
      uint256 exchangeRate,
      uint256 fee
  ) public;

  event VerifiedTransfer(
      address indexed from,
      address indexed to,
      address indexed verifiedAddress,
      uint256 value,
      uint256 referenceId,
      uint256 exchangeRate
  );
}

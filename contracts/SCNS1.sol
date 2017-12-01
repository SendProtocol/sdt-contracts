pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/ERC20.sol';

/**
 * @title SCNS1 (Send Consensus Network Standard v1) interface
 * @dev token interface built on top of ERC20 standard interface
 * @dev see https://send.sd/token
 */
contract SCNS1 is ERC20 {
  function isVerified(address _address) public constant returns(bool);

  function verify(address _address) public;

  function unverify(address _address) public;

  function createPoll(
      bytes32 question,
      bytes32[] options,
      uint256 minimumTokens,
      uint256 endTime
  ) public;

  function vote(uint256 option) public;

  event PollCreated(
      uint256 block,
      bytes32 question,
      bytes32[] options,
      uint256 minimumTokens,
      uint256 endTime
  );

  event Voted(
      uint256 indexed poll,
      address indexed voter,
      uint256 option,
      uint256 weight
  );

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

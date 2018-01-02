pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/BurnableToken.sol';


/**
 * @title Snapshot Token
 *
 * @dev Snapshot Token interface
 * @dev https://send.sd/token
 */
contract ISnapshotToken is BurnableToken {
  address public polls;

  modifier pollsResticted() {
    require(msg.sender == address(polls));
    _;
  }

  function requestSnapshots(uint256 _blockNumber) public;
  function takeSnapshot(address _owner) public returns(uint256);
}

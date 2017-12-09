pragma solidity ^0.4.18;

/**
 * @title Send token
 *
 * @dev Implementation of Send Consensus network Standard
 * @dev https://send.sd/token
 */
contract ISnapshotToken {
  address public polls;

  modifier pollsResticted() {
    require(msg.sender == address(polls));
    _;
  }

  function requestSnapshots(uint256 _blockNumber) public;
  function takeSnapshot(address _owner) public returns(uint256);
}

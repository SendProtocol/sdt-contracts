pragma solidity ^0.4.15;

import './SendToken.sol';

contract SDT is SendToken {
  string public name = "SEND Token";
  string public symbol = "SDT";
  uint256 public decimals = 18;
}
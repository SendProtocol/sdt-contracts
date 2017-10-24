pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/token/ERC20.sol';


contract SCNS1 is ERC20 {

    //consensus network
    function isVerified(address _address) public constant returns (bool);
    function verify(address _address) returns (bool);
    function unverify(address _address) returns (bool);

    //Voting
    function createPoll(uint256 id, bytes32 question, bytes32[] options, uint256 minimumTokens, uint256 startTime, uint256 endTime) public returns (bool);
    function vote(uint256 id, uint256 option) public returns (bool);
    event PollCreated(address creator, uint256 id, bytes32 question, bytes32[] options, uint256 minimumTokens, uint256 startTime, uint256 endTime);
    event Voted(uint256 indexed pollId, address voter, uint256 option);
    
    //Escrow
    function lockedBalanceOf(address _owner) public constant returns (uint256);
    function approveLockedTransfer(address authority, uint256 referenceId, uint256 value, uint256 authorityFee, uint256 expirationTime) public returns (bool);
    function executeLockedTransfer(address sender, address recipient, uint256 referenceId, uint256 exchangeRate) public returns (bool);
    function claimLockedTransfer(address authority, uint256 referenceId) public returns (bool);
    function invalidateLockedTransferExpiration(address sender, uint256 referenceId) public returns (bool);
    event EscrowCreated(address indexed sender, address indexed authority, uint256 referenceId);
    event EscrowResolved(address indexed sender, address indexed authority, uint256 referenceId, address resolver, address sentTo);
    
    //Consensus Network
    function verifiedTransferFrom(address from, address to, uint256 value, uint256 referenceId, uint256 exchangeRate, uint256 fee) public returns (bool);
    event VerifiedTransfer(address indexed from, address indexed to, address indexed verifiedAddress, uint256 value, uint256 referenceId, uint256 exchangeRate);
}
pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/token/ERC20.sol';

/**
 * @title SCNS1 (Send Consensus Network Standard v1) interface
 * @dev token interface built on top of ERC20 standard interface 
 * @dev see https://send.sd/token
 */
contract SCNS1 is ERC20 {

    function isVerified (
        address _address
    ) public constant returns (bool);
    
    function verify (
        address _address
    );
    
    function unverify (
        address _address
    );

    function createPoll (
        uint256 id, 
        bytes32 question, 
        bytes32[] options, 
        uint256 minimumTokens, 
        uint256 startTime, 
        uint256 endTime
    ) public;

    function vote (
        uint256 id, 
        uint256 option
    ) public;
    
    event PollCreated (
        address creator, 
        uint256 id, 
        bytes32 question, 
        bytes32[] options, 
        uint256 minimumTokens, 
        uint256 startTime, 
        uint256 endTime
    );

    event Voted (
        uint256 indexed pollId, 
        address voter, 
        uint256 option
    );
    
    function lockedBalanceOf (
        address _owner
    ) public constant returns (uint256);
    
    function approveLockedTransfer(
        address authority, 
        uint256 referenceId, 
        uint256 value, 
        uint256 authorityFee, 
        uint256 expirationTime
    ) public;
    
    function executeLockedTransfer (
        address sender, 
        address recipient, 
        uint256 referenceId, 
        uint256 exchangeRate
    ) public;

    function claimLockedTransfer (
        address authority, 
        uint256 referenceId
    ) public;

    function invalidateLockedTransferExpiration (
        address sender, 
        uint256 referenceId
    ) public;

    event EscrowCreated (
        address indexed sender, 
        address indexed authority, 
        uint256 referenceId
    );
    
    event EscrowResolved (
        address indexed sender, 
        address indexed authority, 
        uint256 referenceId, 
        address resolver, 
        address sentTo
    );
    
    function verifiedTransferFrom (
        address from, 
        address to, 
        uint256 value, 
        uint256 referenceId, 
        uint256 exchangeRate, 
        uint256 fee
    ) public;

    event VerifiedTransfer (
        address indexed from, 
        address indexed to, 
        address indexed verifiedAddress, 
        uint256 value, 
        uint256 referenceId, 
        uint256 exchangeRate
    );

    function claimTokens() public;

    function claimTokensFor(address to) public;

    function calculateVestedTokens(
        uint256 tokens,
        uint256 vesting,
        uint256 start,
        uint256 claimed
    ) internal constant returns (uint256);

    function grantVestedTokens(
        address _to,
        uint256 _value,
        uint64 _start,
        uint64 _vesting
    ) public;

    event NewTokenGrant (
        address indexed to, 
        uint256 value, 
        uint64 start, 
        uint64 vesting
    );

    event NewTokenClaim (
        address indexed holder, 
        uint256 value
    );
}
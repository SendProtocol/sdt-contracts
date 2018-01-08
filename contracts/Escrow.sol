pragma solidity ^0.4.18;

import './ISendToken.sol';

/**
 * @title Vesting contract for SDT
 * @dev see https://send.sd/token
 */
contract Escrow {
  address public tokenAddress;
  ISendToken public token;

  struct Lock {
    address sender;
    address recipient;
    uint256 value;
    uint256 fee;
    uint256 expiration;
    bool paid;
  }

  mapping(address => mapping(uint256 => Lock)) internal escrows;

  function Escrow(address _token) public {
    token = ISendToken(_token);
  }

  event Created(
    address indexed sender,
    address indexed recipient,
    address indexed arbitrator,
    uint256 transactionId
  );
  event Released(address indexed arbitrator, address indexed sentTo, uint256 transactionId);
  event Dispute(address indexed arbitrator, uint256 transactionId);
  event Paid(address indexed arbitrator, uint256 transactionId);

  modifier tokenRestricted() {
    require (msg.sender == address(token));
    _;
  }

  /**
   * @dev Create a record for held tokens
   * @param _arbitrator Address to be authorized to spend locked funds
   * @param _transactionId Intenral ID for applications implementing this
   * @param _tokens Amount of tokens to lock
   * @param _fee A fee to be paid to arbitrator (may be 0)
   * @param _expiration After this timestamp, user can claim tokens back.
   */
  function create(
      address _sender,
      address _recipient,
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee,
      uint256 _expiration
  ) public tokenRestricted {

    require(_tokens > 0);
    require(_fee >= 0);
    require(escrows[_arbitrator][_transactionId].value == 0);

    escrows[_arbitrator][_transactionId].sender = _sender;
    escrows[_arbitrator][_transactionId].recipient = _recipient;
    escrows[_arbitrator][_transactionId].value = _tokens;
    escrows[_arbitrator][_transactionId].fee = _fee;
    escrows[_arbitrator][_transactionId].expiration = _expiration;

    Created(_sender, _recipient, _arbitrator, _transactionId);
  }

  /**
   * @dev Fund escrow record
   * @param _arbitrator Address to be authorized to spend locked funds
   * @param _transactionId Intenral ID for applications implementing this
   * @param _tokens Amount of tokens to lock
   * @param _fee A fee to be paid to arbitrator (may be 0)
   */
  function fund(
      address _sender,
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee
  ) public tokenRestricted {

    require(escrows[_arbitrator][_transactionId].sender == _sender);
    require(escrows[_arbitrator][_transactionId].value == _tokens);
    require(escrows[_arbitrator][_transactionId].fee == _fee);

    escrows[_arbitrator][_transactionId].paid = true;

    Paid(_arbitrator, _transactionId);
  }

  /**
   * @dev Transfer a locked amount
   * @notice Only authorized address
   * @notice Exchange rate has 18 decimal places
   * @param _sender Address with locked amount
   * @param _recipient Address to send funds to
   * @param _transactionId App/user internal associated ID
   * @param _exchangeRate Rate to be reported to the blockchain
   */
  function release(
      address _sender,
      address _recipient,
      uint256 _transactionId,
      uint256 _exchangeRate
  ) public {

    Lock memory lock = escrows[msg.sender][_transactionId];

    require(lock.sender == _sender);
    require(lock.recipient == _recipient || lock.sender == _recipient);
    require(lock.paid);

    token.transfer(_recipient, lock.value);

    if (lock.fee > 0) {
      token.transfer(msg.sender, lock.fee);
    }

    delete escrows[msg.sender][_transactionId];

    token.issueExchangeRate(
      _sender,
      _recipient,
      msg.sender,
      lock.value,
      _transactionId,
      _exchangeRate
    );
    Released(msg.sender, _recipient, _transactionId);
  }

  /**
   * @dev Claim back locked amount after expiration time
   * @dev Cannot be claimed if expiration == 0
   * @notice Only works after lock expired
   * @param _arbitrator Authorized lock address
   * @param _transactionId transactionId ID from App/user
   */
  function claim(
      address _arbitrator,
      uint256 _transactionId
  ) public {
    Lock memory lock = escrows[_arbitrator][_transactionId];

    require(lock.sender == msg.sender);
    require(lock.paid);
    require(lock.expiration < block.timestamp);
    require(lock.expiration != 0);

    delete escrows[_arbitrator][_transactionId];

    token.transfer(msg.sender, lock.value + lock.fee);

    Released(
      _arbitrator,
      msg.sender,
      _transactionId
    );
  }

  /**
   * @dev Remove expiration time on a lock
   * @notice User wont be able to claim tokens back after this is called by arbitrator address
   * @notice Only authorized address
   * @param _transactionId App/user internal associated ID
   */
  function mediate(
      uint256 _transactionId
  ) public {
    require(escrows[msg.sender][_transactionId].paid);

    escrows[msg.sender][_transactionId].expiration = 0;

    Dispute(msg.sender, _transactionId);
  }
}

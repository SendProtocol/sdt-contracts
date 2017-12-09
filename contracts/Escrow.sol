pragma solidity ^0.4.18;

import './SendToken.sol';

/**
 * @title Vesting contract for SDT
 * @dev see https://send.sd/token
 */
contract Escrow {
  address public tokenAddress;
  SendToken public token;

  struct Lock {
    uint256 value;
    uint256 fee;
    uint256 expiration;
  }

  mapping (address => mapping(address => mapping(uint256 => Lock))) internal escrows;

  function Escrow(address _token) public {
    token = SendToken(_token);
  }

  event EscrowCreated(
    address indexed sender,
    address indexed authority,
    uint256 reference
  );

  event EscrowResolved(
    address indexed sender,
    address indexed authority,
    uint256 reference,
    address resolver,
    address sentTo
  );

  event EscrowMediation(
    address indexed sender,
    address indexed authority,
    uint256 reference
  );

  modifier tokenRestricted(){
    require (msg.sender == address(token));
    _;
  }

  /**
   * @dev Create a record for held tokens
   * @param _authority Address to be authorized to spend locked funds
   * @param _reference Intenral ID for applications implementing this
   * @param _tokens Amount of tokens to lock
   * @param _fee A fee to be paid to authority (may be 0)
   * @param _expiration After this timestamp, user can claim tokens back.
   */
  function escrowTransfer(
      address _sender,
      address _authority,
      uint256 _reference,
      uint256 _tokens,
      uint256 _fee,
      uint256 _expiration
  ) public tokenRestricted {

    require(escrows[_sender][_authority][_reference].value == 0);

    escrows[_sender][_authority][_reference].value = _tokens;
    escrows[_sender][_authority][_reference].fee = _fee;
    escrows[_sender][_authority][_reference].expiration = _expiration;

    EscrowCreated(_sender, _authority, _reference);
  }

  /**
   * @dev Transfer a locked amount
   * @notice Only authorized address
   * @notice Exchange rate has 18 decimal places
   * @param _sender Address with locked amount
   * @param _recipient Address to send funds to
   * @param _reference App/user internal associated ID
   * @param _exchangeRate Rate to be reported to the blockchain
   */
  function executeEscrowTransfer(
      address _sender,
      address _recipient,
      uint256 _reference,
      uint256 _exchangeRate
  ) public {

    uint256 value = escrows[_sender][msg.sender][_reference].value;
    uint256 fee = escrows[_sender][msg.sender][_reference].fee;

    require(value > 0);

    token.transfer(_recipient, value);

    if (fee > 0) {
      token.transfer(msg.sender, fee);
    }

    delete escrows[_sender][msg.sender][_reference];

    token.issueExchangeRate(
      _sender,
      _recipient,
      msg.sender,
      value,
      _reference,
      _exchangeRate
    );
    EscrowResolved(_sender, msg.sender, _reference, msg.sender, _recipient);
  }

  /**
   * @dev Claim back locked amount after expiration time
   * @dev Cannot be claimed if expiration == 0
   * @notice Only works after lock expired
   * @param _authority Authorized lock address
   * @param _reference reference ID from App/user
   */
  function claimEscrowTransfer(
      address _authority,
      uint256 _reference
  ) public {
    require(escrows[msg.sender][_authority][_reference].value > 0);
    require(escrows[msg.sender][_authority][_reference].expiration < block.timestamp);
    require(escrows[msg.sender][_authority][_reference].expiration != 0);

    uint256 value = escrows[msg.sender][_authority][_reference].value;
    uint256 fee = escrows[msg.sender][_authority][_reference].fee;

    delete escrows[msg.sender][_authority][_reference];

    token.transfer(msg.sender, value + fee);

    EscrowResolved(
      msg.sender,
      _authority,
      _reference,
      msg.sender,
      msg.sender
    );
  }

  /**
   * @dev Remove expiration time on a lock
   * @notice User wont be able to claim tokens back after this is called by authority address
   * @notice Only authorized address
   * @param _sender Address with locked amount
   * @param _reference App/user internal associated ID
   */
  function invalidateEscrowTransferExpiration(
      address _sender,
      uint256 _reference
  ) public {
    require(escrows[_sender][msg.sender][_reference].value > 0);
    escrows[_sender][msg.sender][_reference].expiration = 0;
    EscrowMediation(_sender, msg.sender, _reference);
  }
}

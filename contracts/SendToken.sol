pragma solidity ^0.4.18;

import './SCNS1.sol';
import './Escrow.sol';
import './SnapshotToken.sol';


/**
 * @title Send token
 *
 * @dev Implementation of Send Consensus network Standard
 * @dev https://send.sd/token
 */
contract SendToken is SnapshotToken, SCNS1 {
  Escrow public escrow;

  mapping (address => bool) internal verifiedAddresses;

  modifier verifiedResticted(){
    require(verifiedAddresses[msg.sender]);
    _;
  }

  modifier escrowResticted(){
    require(msg.sender == address(escrow));
    _;
  }

  /**
   * @dev Check if an address is whitelisted by SEND
   * @param _address Address to check
   * @return bool
   */
  function isVerified(address _address) public view returns(bool) {
    return verifiedAddresses[_address];
  }

  /**
   * @dev Verify an addres
   * @notice Only contract owner
   * @param _address Address to verify
   */
  function verify(address _address) public onlyOwner {
    verifiedAddresses[_address] = true;
  }

  /**
   * @dev Remove Verified status of a given address
   * @notice Only contract owner
   * @param _address Address to unverify
   */
  function unverify(address _address) public onlyOwner {
    verifiedAddresses[_address] = false;
  }

  /**
   * @dev Remove Verified status of a given address
   * @notice Only contract owner
   * @param _address Address to unverify
   */
  function setEscrow(address _address) public onlyOwner {
    escrow = Escrow(_address);
  }

  /**
   * @dev Transfer from one address to another issuing ane xchange rate
   * @notice Only verified addresses
   * @notice Exchange rate has 18 decimal places
   * @notice Value + fee <= allowance
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   * @param _referenceId internal app/user ID
   * @param _exchangeRate Exchange rate to sign transaction
   * @param _fee fee tot ake from sender
   */
  function verifiedTransferFrom(
      address _from,
      address _to,
      uint256 _value,
      uint256 _referenceId,
      uint256 _exchangeRate,
      uint256 _fee
  ) public verifiedResticted {
    require(_exchangeRate > 0);

    transferFrom(_from, _to, _value);
    transferFrom(_from, msg.sender, _fee);

    VerifiedTransfer(
      _from,
      _to,
      msg.sender,
      _value,
      _referenceId,
      _exchangeRate
    );
  }

  /**
   * @dev execute an escrow transfer
   * @dev specified amount will be locked on escrow contract
   * @param _authority Address authorized to approve/reject transaction
   * @param _reference Intenral ID for applications implementing this
   * @param _tokens Amount of tokens to lock
   * @param _fee A fee to be paid to authority (may be 0)
   * @param _expiration After this timestamp, user can claim tokens back.
   */
  function escrowTransfer(
      address _authority,
      uint256 _reference,
      uint256 _tokens,
      uint256 _fee,
      uint256 _expiration
  ) public {
    uint256 total = _tokens + _fee;
    transfer(escrow, total);

    escrow.escrowTransfer(
      msg.sender,
      _authority,
      _reference,
      _tokens,
      _fee,
      _expiration
    );
  }

  /**
   * @dev Issue exchange rates from escrow contract
   */
  function issueExchangeRate(
      address _from,
      address _to,
      address _verifiedAddress,
      uint256 _value,
      uint256 _referenceId,
      uint256 _exchangeRate
  ) public escrowResticted {
    require(_exchangeRate >= 0);
    bool v = isVerified(_verifiedAddress);
    bool noRate = (_exchangeRate == 0);
    if (v){
      require(!noRate);
      VerifiedTransfer(
        _from,
        _to,
        _verifiedAddress,
        _value,
        _referenceId,
        _exchangeRate
      );
    } else {
      require(noRate);
    }
  }
}

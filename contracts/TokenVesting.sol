pragma solidity ^0.4.18;

import './SendToken.sol';

/**
 * @title Vesting contract for SDT
 * @dev see https://send.sd/token
 */
contract TokenVesting {
  address public owner;
  address public ico;
  bool public initialized;
  bool public active;
  SendToken public token;
  mapping (address => TokenGrant[]) public grants;

  uint256 public circulatingSupply = 0;

  struct TokenGrant {
    uint256 value;
    uint256 claimed;
    uint256 vesting;
    uint256 start;
  }

  event NewTokenGrant (
    address indexed to,
    uint256 value,
    uint256 start,
    uint256 vesting
  );

  event NewTokenClaim (
    address indexed holder,
    uint256 value
  );

  modifier ownerRestricted() {
    require(msg.sender == owner);
    _;
  }

  modifier icoResticted() {
    require(msg.sender == ico);
    _;
  }

  modifier isActive(){
    require(active);
    _;
  }

  function TokenVesting() public {
    owner = msg.sender;
    active = false;
  }

  function init(address _token, address _ico) public ownerRestricted {
    require(!active);
    require(!initialized);
    token = SendToken(_token);
    ico = _ico;
    initialized = true;
    active = true;
  }

  function stop() public isActive ownerRestricted {
    active = false;
  }

  function resume() public isActive ownerRestricted {
    require(!active);
    require(initialized);
    active = true;
  }

  /**
  * @dev Grant vested tokens.
  * @notice Only for ICO contract address.
  * @param _to Addres to grant tokens to.
  * @param _value Number of tokens granted.
  * @param _vesting Vesting finish timestamp.
  * @param _start Vesting start timestamp.
  */
  function grantVestedTokens(
      address _to,
      uint256 _value,
      uint256 _start,
      uint256 _vesting
  ) public icoResticted {
    require (_value > 0);
    require (_vesting > _start);
    require (grants[_to].length < 10);

    TokenGrant memory grant = TokenGrant(_value, 0, _vesting, _start);
    grants[_to].push(grant);

    NewTokenGrant(_to, _value, _start, _vesting);
  }

  /**
  * @dev Calculate vested claimable tokens on current time
  * @param _tokens Number of tokens granted
  * @param _vesting Vesting finish timestamp
  * @param _start Vesting start timestamp
  * @param _claimed Number of tokens already claimed
  */
  function calculateVestedTokens(
      uint256 _tokens,
      uint256 _vesting,
      uint256 _start,
      uint256 _claimed
  ) internal constant returns (uint256) {
    uint256 time = block.timestamp;

    if (time < _start) {
      return 0;
    }
    if (time >= _vesting) {
      return SafeMath.sub(_tokens, _claimed);
    }
    uint256 vestedTokens = SafeMath.div(
      SafeMath.mul(_tokens, SafeMath.sub(time, _start)),
      SafeMath.sub(_vesting, _start)
    );

    return SafeMath.sub(vestedTokens, _claimed);
  }

  /**
  * @dev Claim all vested tokens up to current date for myself
  */
  function claimTokens() public {
    claimTokensFor(msg.sender);
  }

  /**
  * @dev Claim all vested tokens up to current date in behaviour of an user
  */
  function claimTokensFor(address _to) public ownerRestricted {
    claimTokensFor(_to);
  }

  /**
  * @dev Claim all vested tokens up to current date
  */
  function claim(address _to) internal {
    uint256 numberOfGrants = grants[_to].length;

    if (numberOfGrants == 0) {
      return;
    }

    uint256 claimable = 0;
    uint256 claimableFor = 0;
    for (uint256 i = 0; i < numberOfGrants; i++) {
      claimableFor = calculateVestedTokens (
        grants[_to][i].value,
        grants[_to][i].vesting,
        grants[_to][i].start,
        grants[_to][i].claimed
      );
      claimable = SafeMath.add (
        claimable,
        claimableFor
      );
      grants[_to][i].claimed = SafeMath.add (
        grants[_to][i].claimed,
        claimableFor
      );
    }

    token.transfer(_to, claimable);
    circulatingSupply += claimable;

    NewTokenClaim(_to, claimable);
  }

  /**
  * @dev Get claimable tokens
  */
  function claimableTokens() public constant returns (uint256) {
    address _to = msg.sender;
    uint256 numberOfGrants = grants[_to].length;
  
    if (numberOfGrants == 0) {
      return 0;
    }

    uint256 claimable = 0;
    uint256 claimableFor = 0;
    for (uint256 i = 0; i < numberOfGrants; i++) {
      claimableFor = calculateVestedTokens (
        grants[_to][i].value,
        grants[_to][i].vesting,
        grants[_to][i].start,
        grants[_to][i].claimed
      );
      claimable = SafeMath.add (
        claimable,
        claimableFor
      );
    }
    return claimable;
  }

  function totalVestedTokens() public constant returns (uint256) {
    address _to = msg.sender;
    uint256 numberOfGrants = grants[_to].length;

    if (numberOfGrants == 0) {
      return 0;
    }

    uint256 claimable = 0;
    for (uint256 i = 0; i < numberOfGrants; i++) {
      claimable = SafeMath.add (
        claimable,
        SafeMath.sub (grants[_to][i].value, grants[_to][i].claimed)
      );
    }
    return claimable;
  }

}

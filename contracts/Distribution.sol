pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/BurnableToken.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

/**
 * @title Distribution contract
 * @dev see https://send.sd/distribution
 */
contract Distribution is Ownable {
  using SafeMath for uint256;

  uint16 public stages; 
  uint256 public stageDuration; 
  uint256 public startTime;

  uint256 public soldTokens;
  uint256 public bonusClaimedTokens;
  uint256 public raisedETH;
  uint256 public raisedUSD;

  uint256 public weiUsdRate;

  BurnableToken public token;

  bool public isActive;
  uint256 public cap;
  uint256 public stageCap;

  mapping (address => mapping (uint16 => uint256)) public contributions;
  mapping (uint16 => uint256) public sold;
  mapping (uint16 => bool) public burned;
  mapping (address => mapping (uint16 => bool)) public claimed;

  event NewPurchase(
    address indexed purchaser,
    uint256 sdtAmount,
    uint256 usdAmount,
    uint256 ethAmount
  );

  event NewBonusClaim(
    address indexed purchaser,
    uint256 sdtAmount
  );

  function Distribution(
      uint256 _startTime,
      uint16 _stages,
      uint256 _stageDuration,
      address _token
  ) public {
    require(_startTime > block.timestamp);

    startTime = _startTime;
    stages = _stages;
    stageDuration = _stageDuration;

    isActive = false;
    token = BurnableToken(_token);
  }

  /**
   * @dev Initialize distribution
   * @param _cap uint256 The amount of tokens for distribution
   */
  function init(uint256 _cap) public onlyOwner {
   require (token.balanceOf(this) == _cap);
    cap = _cap;
    stageCap = cap / stages;
    isActive = true;
  }

  /**
   * @dev contribution function
   */
  function () external payable {
    require (isActive);
    require (weiUsdRate > 0);
    require (getStage() < stages);

    uint256 usd = msg.value / weiUsdRate;
    uint256 tokens = computeTokens(usd);
    uint16 stage = getStage();

    sold[stage] += tokens;
    require (sold[stage] < stageCap);

    contributions[msg.sender][stage] += tokens;
    soldTokens += tokens;
    raisedETH += msg.value;
    raisedUSD += usd;

    NewPurchase(msg.sender, tokens, usd, msg.value);
    token.transfer(msg.sender, tokens);
  }

  /**
   * @dev retrieve bonus from specified stage
   * @param _stage uint16 The stage
   */
  function claimBonus(uint16 _stage) public {
    require(!claimed[msg.sender][_stage]);
    require (getStage() > _stage);

    if (!burned[_stage]) {
      token.burn(stageCap - sold[_stage] - sold[_stage] * computeBonus(_stage) / 1000000000000000000);
      burned[_stage] = true;
    }

  	uint256 tokens = computeAddressBonus(_stage);
  	token.transfer(msg.sender, tokens);
  	bonusClaimedTokens += tokens;
  	claimed[msg.sender][_stage] = true;

  	NewBonusClaim(msg.sender, tokens);
  }

  /**
   * @dev set an exchange rate in wei
   * @param _rate uint256 The new exchange rate
   */
  function setWeiUsdRate(uint256 _rate) public onlyOwner {
    require(_rate > 0);
    weiUsdRate = _rate;
  }

  /**
   * @dev retrieve ETH 
   * @param _amount uint256 The new exchange rate
   * @param _address address The address to receive ETH
   */
  function forwardFunds(uint256 _amount, address _address) public onlyOwner {
    _address.transfer(_amount);
  }

  /**
   * @dev compute tokens given a USD value
   * @param _usd uint256 Value in USD
   */
  function computeTokens(uint256 _usd) public view returns(uint256) {
  	return _usd * 1000000000000000000000000000000000000 / (200000000000000000 + 19800000000000000000 * soldTokens / cap);
  }

  /**
   * @dev current stage
   */
  function getStage() public view returns(uint16) {
    require (block.timestamp >= startTime);
  	return uint16((block.timestamp - startTime) / stageDuration);
  }

  /**
   * @dev compute bonus (%) for a specified stage
   * @param _stage uint16 The stage
   */
  function computeBonus(uint16 _stage) public view returns(uint256) {
  	return (100000000000000000 - (sold[_stage] * 100000 / 441095890411));
  }

  /**
   * @dev compute for a specified stage
   * @param _stage uint16 The stage
   */
  function computeAddressBonus(uint16 _stage) public view returns(uint256) {
  	return contributions[msg.sender][_stage] * computeBonus(_stage) / 1000000000000000000;
  }
}
pragma solidity ^0.4.18;

import "./TokenVesting.sol";
import "./ITokenSale.sol";
import "./ISendToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";


/**
 * @title Crowdsale contract
 * @dev see https://send.sd/crowdsale
 */
contract TokenSale is Ownable, ITokenSale {
  using SafeMath for uint256;

  /* Leave 10 tokens margin error in order to succedd
  with last pool allocation in case hard cap is reached */
  uint256 public hardcap = 230999990 ether;

  uint256 public startTime;
  uint256 public endTime;
  address public wallet;

  uint256 public vestingStarts;
  uint256 public weiUsdRate;
  uint256 public btcUsdRate;

  uint256 public soldTokens;
  uint256 public raised;

  bool public activated = false;
  bool public isStopped = false;
  bool public isFinalized = false;

  ISendToken public token;
  TokenVesting public vesting;

  mapping (address => bool) internal proxies;
  mapping (address => bool) public allowed;

  event NewBuyer(
    address indexed holder,
    uint256 sndAmount,
    uint256 usdAmount,
    uint256 ethAmount,
    uint256 btcAmount
  );

  modifier validAddress(address _address) {
    require(_address != address(0x0));
    _;
  }

  modifier isActive() {
    require(activated);
    require(!isStopped);
    require(!isFinalized);
    require(block.timestamp >= startTime);
    require(block.timestamp <= endTime);
    _;
  }

  function TokenSale(
      uint256 _startTime,
      uint256 _endTime,
      address _wallet,
      uint256 _vestingStarts
  ) public validAddress(_wallet) {
    require(_startTime > block.timestamp - 60);
    require(_endTime > startTime);
    require(_vestingStarts > startTime);

    vestingStarts = _vestingStarts;
    startTime = _startTime;
    endTime = _endTime;
    wallet = _wallet;
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
   * @dev set an exchange rate in satoshis
   * @param _rate uint256 The new exchange rate
   */
  function setBtcUsdRate(uint256 _rate) public onlyOwner {
    require(_rate > 0);
    btcUsdRate = _rate;
  }

  /**
   * @dev Allow an address to send ETH purchases
   * @param _address address The address to whitelist
   */
  function allow(address _address) public onlyOwner {
    allowed[_address] = true;
  }

  /**
   * @dev initialize the contract and set token
   */
  function initialize(
      address _sdt,
      address _vestingContract,
      address _icoCostsPool
  ) public validAddress(_sdt) validAddress(_vestingContract) onlyOwner {
    require(!activated);

    token = ISendToken(_sdt);
    vesting = TokenVesting(_vestingContract);

    // 1% reserve is released on deploy
    token.transfer(_icoCostsPool, 7000000 ether);

    //rearly backers allocation

    uint256 threeMonths = vestingStarts.add(90 days);
    uint256 twoYears = vestingStarts.add(2 years);

    updateStats(1016000, 17310000 ether);
    grantVestedTokens(0xd6E722A6bae8E62d1034d4620CA898601AC9350b, 860000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0xacC37F88e93ae2FD1E371f76912785E3B21A8a73, 100000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x005B9E744b0e2Ff467D748CE228694D306670c35, 100000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x7A6720b291cd2e806d7B86aD279a6de109fE002a, 180000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x90dF318D244F170F57B3669e7646C2bb693Ceb54, 100000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0xfB4EEAa3056e5d77499fa52897d4E1ef996E06DC, 100000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x93934523F6f56Ff139d6B14AF71cA759A3b8c1a0, 100000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x10eC5d603Fb471d5C0A9d4a2753dA810f4c3Ba54, 100000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0xbF85462eB89308A328882f6a66aD11FF070c1eA9, 150000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x11e64d7bc1368cCa98270290Ee574E690C82B765, 200000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x08F77e15f4f756a7C9F77dFA28847e0f5488e9B2, 860000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0xA4E2f15a770DDDC064D29f5311b3e17E24681dE0, 200000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0xaf10CcBAA460626ebA1aFfe324168624C2B568eA, 400000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x6C261AeD58bE6cf65afABA1bA45E8DbBe32382fA, 400000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x323B1A13f3DD40Db10ddc125f07DDcF021b040E0, 600000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0xd4fa81451EB5bB0E99bA56B5Fda8d804aC91D3D6, 2700000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x4571F12E28b45d5D3AdE71e368739B6216485962, 2360000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x2059236Bff26556d43772e7Cd613136025dA601b, 1950000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x93C77A6DC1fe12D64F4d97E96c6672FE517eb0Bb, 1950000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x675F249E78ca19367b9e26B206B9Bc519195De94, 1950000 ether, vestingStarts, twoYears);
    grantVestedTokens(0xb93151f6f5Cf1F416CdBE8C76745D18CDfe83395, 1950000 ether, vestingStarts, twoYears);
    activated = true;
  }

  function finalize(
      address _poolA,
      address _poolB,
      address _poolC,
      address _poolD
  )
      public
      validAddress(_poolA)
      validAddress(_poolB)
      validAddress(_poolC)
      validAddress(_poolD)
      onlyOwner
  {
    grantVestedTokens(_poolA, (175000000 ether) * soldTokens / (231000000 ether), vestingStarts, vestingStarts + 7 years);
    grantVestedTokens(_poolB, (168000000 ether) * soldTokens / (231000000 ether), vestingStarts, vestingStarts + 7 years);
    grantVestedTokens(_poolC, (70000000 ether) * soldTokens / (231000000 ether), vestingStarts, vestingStarts + 7 years);
    grantVestedTokens(_poolD, 49000000 ether, vestingStarts, vestingStarts + 4 years);

    token.burn(token.balanceOf(this));
  }

  function stop() public onlyOwner isActive returns(bool) {
    isStopped = true;
    return true;
  }

  function resume() public onlyOwner returns(bool) {
    require(isStopped);
    isStopped = false;
    return true;
  }

  function addProxyContract(address _address) public onlyOwner {
    proxies[_address] = true;
  }

  function ethPurchase(
    address _beneficiary,
    uint256 _vestingTime,
    uint256 _discountBase
  ) public validAddress(_beneficiary) payable returns (bool) {
    require(proxies[msg.sender]);

    uint256 usd = msg.value.div(weiUsdRate);

    uint256 vestingEnds = vestingStarts.add(_vestingTime);

    doPurchase(usd, msg.value, 0, _beneficiary, _discountBase, vestingEnds);
    forwardFunds();

    return true;
  }

  function btcPurchase(
      address _beneficiary,
      uint256 _vestingTime,
      uint256 _discountBase,
      uint256 _btcValue
  ) public validAddress(_beneficiary) returns (bool) {
    require(proxies[msg.sender]);

    uint256 usd = _btcValue.div(btcUsdRate);

    uint256 vestingEnds = vestingStarts.add(_vestingTime);

    doPurchase(usd, 0, _btcValue, _beneficiary, _discountBase, vestingEnds);

    return true;
  }

  /**
  * @dev Number of tokens is given by:
  * 70,000,000 ln((7,000,000 + raised + usd) / (7,000,000 + raised))
  */
  function computeTokens(uint256 usd) public view returns(uint256) {
    require(usd > 0);
    uint256 _denominator;

    if (raised < 7000000) {
      if (usd + raised <= 7000000) {
        // all of the investment belongs to the linear function.
        return usd * 100000000000000000000 / 14;
      } else {
        // only the investment needed to reach 7000000 belongs to the linear function.
        uint256 _usd = 7000000 - raised;
        // the investment above 7000000 belongs to the non-linear function.
        usd -= _usd;

        if (usd < 50000) {
          // for low investments belonging to the non-linear function we use a
          // simplification of ln.
          return (_usd * 100000000000000000000 / 14) +
            (70000000 ether / (raised + 7000000) +
            70000000 ether / (raised + usd + 7000000)) * usd / 2;
        }

        _denominator = 14000000; // 7M+7M raised
        return (_usd * 100000000000000000000 / 14) +
          (70000000 * (ln((_denominator + usd) * 10 ** 18) - ln(_denominator * 10 ** 18)));
      }
    } else {
      if (usd < 50000) {
        // for low investments belonging to the non-linear function we use a
        // simplification of ln.
        return (70000000 ether / (raised + 7000000) +
          70000000 ether / (raised + usd + 7000000)) * usd / 2;
      }

      _denominator = 7000000 + raised;
      return 70000000 * (ln((_denominator + usd) * 10 ** 18) - ln(_denominator * 10 ** 18));
    }
  }

  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  /**
   * @notice The owner of this contract is the owner of token's contract
   * @param _usd amount invested in USD
   * @param _eth amount invested in ETH y contribution was made in ETH, 0 otherwise
   * @param _btc amount invested in BTC y contribution was made in BTC, 0 otherwise
   * @param _address Address to send tokens to
   * @param _vestingEnds vesting finish timestamp
   * @param _discountBase a multiplier for tokens based on a discount choosen and a vesting time
   */
  function doPurchase(
      uint256 _usd,
      uint256 _eth,
      uint256 _btc,
      address _address,
      uint256 _discountBase,
      uint256 _vestingEnds
  )
      internal
      isActive
      returns(uint256)
  {
    require(allowed[_address]);
    require(_usd >= 10);

    uint256 soldAmount = computeTokens(_usd);

    soldAmount = computeBonus(soldAmount, _discountBase);

    updateStats(_usd, soldAmount);
    grantVestedTokens(_address, soldAmount, vestingStarts, _vestingEnds);
    NewBuyer(_address, soldAmount, _usd, _eth, _btc);

    return soldAmount;
  }

  /**
   * @dev Helper function to update collected and allocated tokens stats
   */
  function updateStats(uint256 usd, uint256 tokens) internal {
    raised = raised + usd;
    soldTokens = soldTokens + tokens;

    require(soldTokens < hardcap);
  }

  /**
   * @dev Helper function to compute bonus amount
   * @param _amount number of toknes before bonus
   * @param _discountBase percentage of price after discount
   * @notice 70 <= dicountBase <= 100
   * @notice _discountBase is the resultant of (100 - discount)
   */
  function computeBonus(
      uint256 _amount,
      uint256 _discountBase
  ) internal pure returns(uint256) {
    require(_discountBase >= 70);
    require(_discountBase <= 100);
    return _amount * 100 / _discountBase;
  }

  /**
  * @dev Computes ln(x) with 18 artifical decimal places for input and output
  * This algotihm uses a logarithm of the form
    * ln(x) = ln(y * 1.5^k) = k ln(1.5) + ln(y)
    * where ln(1.5) is a known value and ln(y) is computed with a tayilor series
    * for 1 < y < 1.5 which is within radius of convergence of the Taylor series.
    * https://en.wikipedia.org/wiki/Natural_logarithm#Derivative.2C_Taylor_series
    */
  function ln(uint256 x) internal pure returns(uint256 result) {
    uint256 n = 1;
    uint256 y;

    while (x >= 1500000000000000000) {
      result = result + 405465108108164000; // ln(1.5) = 0.405465108108164
      x = x * 2 / 3; // same as x / 1.5
    }

    x = x - 1000000000000000000;
    y = x;

    while (n < 10) {
      result = result + (y / n);
      n = n + 1;
      y = y * x / 1000000000000000000;
      result = result - (y / n);
      n = n + 1;
      y = y * x / 1000000000000000000;
    }
  }

  /**
   * @dev deploy the token itself
   * @notice The owner of this contract is the owner of token's contract
   * @param _to Adress to grant vested tokens
   * @param _value number of tokens to grant
   * @param _start vesting start timestamp
   * @param _vesting vesting finish timestamp
   */
  function grantVestedTokens(
      address _to,
      uint256 _value,
      uint256 _start,
      uint256 _vesting
  ) internal {
    token.transfer(vesting, _value);
    vesting.grantVestedTokens(_to, _value, _start, _vesting);
  }
}

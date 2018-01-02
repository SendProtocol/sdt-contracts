pragma solidity ^0.4.18;

// File: contracts/ITokenSale.sol

/**
 * @title Crowdsale contract Interface for Receiver contracts
 * @dev see https://send.sd/crowdsale
 */
contract ITokenSale {
  function ethPurchase(address _beneficiary, uint256 _vestingTime, uint256 _discountBase) public payable;
  function btcPurchase(address _beneficiary, uint256 _vestingTime, uint256 _discountBase, uint256 btcValue) public;
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/TokenVesting.sol

/**
 * @title Vesting contract for SDT
 * @dev see https://send.sd/token
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;

  address public ico;
  bool public initialized;
  bool public active;
  ERC20Basic public token;
  mapping (address => TokenGrant[]) public grants;
  mapping (address => bool) public allowed;

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

  modifier icoResticted() {
    require(msg.sender == ico);
    _;
  }

  modifier isActive() {
    require(active);
    _;
  }

  function TokenVesting() public {
    active = false;
  }

  function init(address _token, address _ico) public onlyOwner {
    token = ERC20Basic(_token);
    ico = _ico;
    initialized = true;
    active = true;
  }

  function stop() public isActive onlyOwner {
    active = false;
  }

  function resume() public onlyOwner {
    require(!active);
    require(initialized);
    active = true;
  }

  function allow(address _address) public onlyOwner {
    allowed[_address] = true;
  }

  function revoke(address _address) public onlyOwner {
    allowed[_address] = false;
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
  ) public icoResticted isActive {
    require(_value > 0);
    require(_vesting > _start);
    require(grants[_to].length < 10);

    TokenGrant memory grant = TokenGrant(_value, 0, _vesting, _start);
    grants[_to].push(grant);

    NewTokenGrant(_to, _value, _start, _vesting);
  }

  /**
  * @dev Claim all vested tokens up to current date for myself
  */
  function claimTokens() public {
    claim(msg.sender);
  }

  /**
  * @dev Claim all vested tokens up to current date in behaviour of an user
  */
  function claimTokensFor(address _to) public onlyOwner {
    claim(_to);
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
      claimableFor = calculateVestedTokens(
        grants[_to][i].value,
        grants[_to][i].vesting,
        grants[_to][i].start,
        grants[_to][i].claimed
      );
      claimable = claimable.add(claimableFor);
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
      claimable = claimable.add(
        grants[_to][i].value.sub(grants[_to][i].claimed)
      );
    }
    return claimable;
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
      return _tokens.sub(_claimed);
    }

    uint256 vestedTokens = _tokens.mul(time.sub(_start)).div(
      _vesting.sub(_start)
    );

    return vestedTokens.sub(_claimed);
  }

  /**
  * @dev Claim all vested tokens up to current date
  */
  function claim(address _to) internal {
    require(allowed[_to]);

    uint256 numberOfGrants = grants[_to].length;

    if (numberOfGrants == 0) {
      return;
    }

    uint256 claimable = 0;
    uint256 claimableFor = 0;
    for (uint256 i = 0; i < numberOfGrants; i++) {
      claimableFor = calculateVestedTokens(
        grants[_to][i].value,
        grants[_to][i].vesting,
        grants[_to][i].start,
        grants[_to][i].claimed
      );
      claimable = claimable.add(claimableFor);
      grants[_to][i].claimed = grants[_to][i].claimed.add(claimableFor);
    }

    token.transfer(_to, claimable);
    circulatingSupply += claimable;

    NewTokenClaim(_to, claimable);
  }
}

// File: contracts/TokenSale.sol

/**
 * @title Crowdsale contract
 * @dev see https://send.sd/crowdsale
 */
contract TokenSale is Ownable, ITokenSale {
  using SafeMath for uint256;

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

  ERC20Basic public token;
  TokenVesting public vesting;

  mapping (address => bool) internal proxies;

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


  function setWeiUsdRate(uint256 _rate) public onlyOwner {
    require(_rate > 0);
    weiUsdRate = _rate;
  }

  function setBtcUsdRate(uint256 _rate) public onlyOwner {
    require(_rate > 0);
    btcUsdRate = _rate;
  }

  /**
   * @dev deploy the token itself
   * @notice The owner of this contract is the owner of token's contract
   */
  function initialize(
      address _sdt,
      address _vestingContract
  ) public validAddress(_sdt) validAddress(_vestingContract) onlyOwner {
    require(!activated);
    token = ERC20Basic(_sdt);

    vesting = TokenVesting(_vestingContract);
    activated = true;
  }

  function finalize(
      address _poolA,
      address _poolB,
      address _poolC,
      address _poolD,
      address _poolE,
      address _poolF
  )
      public
      validAddress(_poolA)
      validAddress(_poolB)
      validAddress(_poolC)
      validAddress(_poolD)
      validAddress(_poolE)
      validAddress(_poolF)
      onlyOwner
  {
    grantVestedTokens(_poolA, 175000000 ether, vestingStarts, 7 years);
    grantVestedTokens(_poolB, 168000000 ether, vestingStarts, 7 years);
    grantVestedTokens(_poolC, 70000000 ether, vestingStarts, 7 years);
    grantVestedTokens(_poolD, 29000000 ether, vestingStarts, 4 years);
    grantVestedTokens(_poolE, 20000000 ether, vestingStarts, 90 days);
    token.transfer(_poolF, 7000000 ether);
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
  ) public validAddress(_beneficiary) payable {
    require(proxies[msg.sender]);

    uint256 usd = msg.value.div(weiUsdRate);

    uint256 vestingEnds = vestingStarts.add(_vestingTime);

    doPurchase(usd, msg.value, 0, _beneficiary, _discountBase, vestingEnds);
    forwardFunds();
  }

  function btcPurchase(
      address _beneficiary,
      uint256 _vestingTime,
      uint256 _discountBase,
      uint256 _btcValue
  ) public validAddress(_beneficiary) {
    require(proxies[msg.sender]);

    uint256 usd = _btcValue.div(btcUsdRate);

    uint256 vestingEnds = vestingStarts.add(_vestingTime);

    doPurchase(usd, 0, _btcValue, _beneficiary, _discountBase, vestingEnds);
  }

  /**
  * @dev Number of tokens is given by:
  * 70,000,000 ln((7,000,000 + raised + usd) / (7,000,000 + raised))
  */
  function computeTokens(uint256 usd) public view returns(uint256) {
    require(usd > 0);

    uint256 _numerator;
    uint256 _denominator;

    if (raised < 7000000) {
      if (usd + raised > 7000000) {

        uint256 _usd = 7000000 - raised;
        usd -= _usd;

        _denominator = 14000000; // 7M+7M raised
        _numerator = _denominator + usd;

        return (_usd * 100000000000000000000 / 14) +
          (70000000 * (ln(_numerator * 10 ** 18) - ln(_denominator * 10 ** 18)));

      } else {
        return usd * 100000000000000000000 / 14;
      }
    } else {
      _denominator = 7000000 + raised;
      _numerator = _denominator + usd;
      return 70000000 * (ln(_numerator * 10 ** 18) - ln(_denominator * 10 ** 18));
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
  }

  /**
   * @dev Helper function to compute bonus amount
   * @param _amount number of toknes before bonus
   * @param _discountBase percentage of price after discount
   * @notice 80 <= dicountBase <= 100
   * @notice _discountBase is the resultant of (100 - discount)
   */
  function computeBonus(
      uint256 _amount,
      uint256 _discountBase
  ) internal pure returns(uint256) {
    require(_discountBase >= 80);
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

pragma solidity ^0.4.18;

// File: contracts/ISnapshotToken.sol

/**
 * @title Snapshot Token
 *
 * @dev Snapshot Token interface
 * @dev https://send.sd/token
 */
contract ISnapshotToken {
  address public polls;

  modifier pollsResticted() {
    require(msg.sender == address(polls));
    _;
  }

  function requestSnapshots(uint256 _blockNumber) public;
  function takeSnapshot(address _owner) public returns(uint256);
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

// File: zeppelin-solidity/contracts/token/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

// File: zeppelin-solidity/contracts/token/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: zeppelin-solidity/contracts/token/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/SnapshotToken.sol

/**
 * @title Snapshot Token
 *
 * @dev Snapshot Token implementtion
 * @dev https://send.sd/token
 */
contract SnapshotToken is ISnapshotToken, StandardToken, Ownable {
  uint256 public snapshotBlock;

  mapping (address => Snapshot) internal snapshots;

  struct Snapshot {
    uint256 block;
    uint256 balance;
  }

  /**
   * @dev Remove Verified status of a given address
   * @notice Only contract owner
   * @param _address Address to unverify
   */
  function setPolls(address _address) public onlyOwner {
    polls = _address;
  }

  /**
   * @dev Extend OpenZeppelin's BasicToken transfer function to store snapshot
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    takeSnapshot(msg.sender);
    takeSnapshot(_to);
    return BasicToken.transfer(_to, _value);
  }

  /**
   * @dev Extend OpenZeppelin's StandardToken transferFrom function to store snapshot
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    takeSnapshot(_from);
    takeSnapshot(_to);
    return StandardToken.transferFrom(_from, _to, _value);
  }

  function takeSnapshot(address _owner) public returns(uint256) {
    if (snapshots[_owner].block < snapshotBlock) {
      snapshots[_owner].block = snapshotBlock;
      snapshots[_owner].balance = balanceOf(_owner);
    }
    return snapshots[_owner].balance;
  }

  function requestSnapshots(uint256 _blockNumber) public pollsResticted {
    snapshotBlock = _blockNumber;
  }
}

// File: zeppelin-solidity/contracts/token/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

// File: contracts/ISendToken.sol

/**
 * @title ISendToken - Send Consensus Network Token interface
 * @dev token interface built on top of ERC20 standard interface
 * @dev see https://send.sd/token
 */
contract ISendToken is BurnableToken, SnapshotToken {
  function isVerified(address _address) public constant returns(bool);

  function verify(address _address) public;

  function unverify(address _address) public;

  function verifiedTransferFrom(
      address from,
      address to,
      uint256 value,
      uint256 referenceId,
      uint256 exchangeRate,
      uint256 fee
  ) public;

  function issueExchangeRate(
      address _from,
      address _to,
      address _verifiedAddress,
      uint256 _value,
      uint256 _referenceId,
      uint256 _exchangeRate
  ) public;

  event VerifiedTransfer(
      address indexed from,
      address indexed to,
      address indexed verifiedAddress,
      uint256 value,
      uint256 referenceId,
      uint256 exchangeRate
  );
}

// File: contracts/ITokenSale.sol

/**
 * @title Crowdsale contract Interface for Receiver contracts
 * @dev see https://send.sd/crowdsale
 */
contract ITokenSale {
  function ethPurchase(address _beneficiary, uint256 _vestingTime, uint256 _discountBase) public payable;
  function btcPurchase(address _beneficiary, uint256 _vestingTime, uint256 _discountBase, uint256 btcValue) public;
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

  function setWeiUsdRate(uint256 _rate) public onlyOwner {
    require(_rate > 0);
    weiUsdRate = _rate;
  }

  function setBtcUsdRate(uint256 _rate) public onlyOwner {
    require(_rate > 0);
    btcUsdRate = _rate;
  }

  function allow(address _address) public onlyOwner {
    allowed[_address] = true;
  }

  /**
   * @dev deploy the token itself
   * @notice The owner of this contract is the owner of token's contract
   */
  function initialize(
      address _sdt,
      address _vestingContract,
      address _icoCostsPool
  ) public validAddress(_sdt) validAddress(_vestingContract) onlyOwner {
    require(!activated);

    token = ISendToken(_sdt);
    vesting = TokenVesting(_vestingContract);

    token.transfer(_icoCostsPool, 7000000 ether);

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
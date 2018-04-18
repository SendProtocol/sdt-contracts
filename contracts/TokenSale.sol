pragma solidity ^0.4.18;

import "./TokenVesting.sol";
import "zeppelin-solidity/contracts/token/BurnableToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";


/**
 * @title Crowdsale contract
 * @dev see https://send.sd/crowdsale
 */
contract TokenSale is Ownable {
  using SafeMath for uint256;

  /* Leave 10 tokens margin error in order to succedd
  with last pool allocation in case hard cap is reached */
  uint256 public hardcap = 70000000 ether;
  uint256 public vestingTime = 7776000;
  uint256 public weiUsdRate = 1;
  uint256 public btcUsdRate = 1;

  uint256 public vestingEnds;
  uint256 public startTime;
  uint256 public endTime;
  address public wallet;

  uint256 public vestingStarts;

  uint256 public soldTokens;
  uint256 public raised;

  bool public activated = false;
  bool public isStopped = false;
  bool public isFinalized = false;

  BurnableToken public token;
  TokenVesting public vesting;

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
    vestingEnds = vestingStarts.add(vestingTime);
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
      address _icoCostsPool,
      address _distributionContract
  ) public validAddress(_sdt) validAddress(_vestingContract) onlyOwner {
    require(!activated);

    token = BurnableToken(_sdt);
    vesting = TokenVesting(_vestingContract);

    // 1% reserve is released on deploy
    token.transfer(_icoCostsPool, 7000000 ether);
    token.transfer(_distributionContract, 161000000 ether);

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
    grantVestedTokens(_poolA, 175000000 ether, vestingStarts, vestingStarts.add(7 years));
    grantVestedTokens(_poolB, 168000000 ether, vestingStarts, vestingStarts.add(7 years));
    grantVestedTokens(_poolC, 70000000 ether, vestingStarts, vestingStarts.add(7 years));
    grantVestedTokens(_poolD, 49000000 ether, vestingStarts, vestingStarts.add(4 years));

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

  function () public payable {
    uint256 usd = msg.value.div(weiUsdRate);
    doPurchase(usd, msg.value, 0, msg.sender, vestingEnds);
    forwardFunds();
  }

  function btcPurchase(
      address _beneficiary,
      uint256 _btcValue
  ) public onlyOwner validAddress(_beneficiary) {
    uint256 usd = _btcValue.div(btcUsdRate);
    doPurchase(usd, 0, _btcValue, _beneficiary, vestingEnds);
  }

  /**
  * @dev Number of tokens is given by:
  * usd * 100 ether / 14
  */
  function computeTokens(uint256 _usd) public pure returns(uint256) {
    return _usd.mul(100 ether).div(14);
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
   */
  function doPurchase(
      uint256 _usd,
      uint256 _eth,
      uint256 _btc,
      address _address,
      uint256 _vestingEnds
  )
      internal
      isActive
      returns(uint256)
  {
    require(allowed[_address]);
    require(_usd >= 10);

    uint256 soldAmount = computeTokens(_usd);

    updateStats(_usd, soldAmount);
    grantVestedTokens(_address, soldAmount, vestingStarts, _vestingEnds);
    NewBuyer(_address, soldAmount, _usd, _eth, _btc);

    return soldAmount;
  }

  /**
   * @dev Helper function to update collected and allocated tokens stats
   */
  function updateStats(uint256 usd, uint256 tokens) internal {
    raised = raised.add(usd);
    soldTokens = soldTokens.add(tokens);

    require(soldTokens <= hardcap);
  }

  /**
   * @dev grant vested tokens
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

  //////////
  // Safety Methods
  //////////

  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyOwner {
    if (_token == 0x0) {
      owner.transfer(this.balance);
      return;
    }

    ERC20Basic erc20token = ERC20Basic(_token);
    uint256 balance = erc20token.balanceOf(this);
    erc20token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }
  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);

}

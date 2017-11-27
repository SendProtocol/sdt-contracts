pragma solidity ^0.4.18;

import './SDT.sol';

/**
 * @title Crowdsale contract
 * @dev see https://send.sd/crowdsale
 */
contract TokenSale {

	uint256 public startTime;
	uint256 public endTime;
	address public ownerWallet;
	address public foundationWallet;
	address public corpotationWallet;
	address public rewardWallet;
	address public teamWallet;
	address public saleWallet;

	uint256 public startVesting;

	uint256 public soldTokens = 0;
	uint256 public raised = 0;
	bool public activated = false;
	bool public isStopped = false;
	bool public isFinalized = false;

	SDT public token;

    event NewBuyer(
    	address indexed holder, 
    	uint256 sndAmount, 
    	uint256 usdAmount, 
    	uint256 ethAmount, 
    	uint256 btcAmount
    );

    modifier validAddress(address _address){
        require(_address != address(0x0));
        _;
    }

    modifier isActive(){
        require(activated == true);
        require(isStopped == false);
        require(isFinalized == false);
        require(block.timestamp >= startTime);
        require(block.timestamp <= endTime);
        _;
    }

    modifier isOwner(){
        require(msg.sender == ownerWallet);
        _;
    }

	function TokenSale (
		uint256 _startTime,
		uint256 _endTime,
		address _foundationWallet,
		address _corporationWallet,
		address _rewardWallet,
		address _teamWallet,
		address _saleWallet,
		uint256 _startVesting
	) 
	    public
		validAddress(_foundationWallet)
		validAddress(_corporationWallet)
		validAddress(_rewardWallet)
		validAddress(_teamWallet)
		validAddress(_saleWallet)
	{
		require(_startTime > block.timestamp - 60);
		require(_endTime > startTime);
		require(_startVesting > startTime);

		startVesting = _startVesting;
		startTime = _startTime;
		endTime = _endTime;
		ownerWallet = msg.sender;
		foundationWallet = _foundationWallet;
		corpotationWallet = _corporationWallet;
		rewardWallet = _rewardWallet;
		teamWallet = _teamWallet;
		saleWallet = _saleWallet;
	}

	/**
	 * @dev deploy the token itself
	 * @notice The owner of this contract is the owner of token's contract
	 * @param _supply Token total supply
	 * @param _ownerPool Percentage of tokens the owner assigns to himself
	 */
	function deploy (
		uint256 _supply, 
		uint256 _ownerPool
	) 
	public isOwner returns (bool) 
	{
		require(!activated);
		token = new SDT (
			_supply, 
			msg.sender, 
			saleWallet, 
			_ownerPool
		);
		activated = true;
		return true;
	}

	function stop() public isOwner isActive returns (bool) {
		isStopped = true;
		return true;
	}

	function resume() public isOwner returns (bool) {
		require(isStopped);
		isStopped = false;
		return true;
	}

	/**
	 * @dev deploy the token itself
	 * @notice The owner of this contract is the owner of token's contract
	 * @param _usd amount invested in USD
	 * @param _eth amount invested in ETH y contribution was made in ETH, 0 otherwise
	 * @param _btc amount invested in BTC y contribution was made in BTC, 0 otherwise
	 * @param _address Address to send tokens to
	 * @param _vesting vesting finish timestamp
	 * @param _discountBase a multiplier for tokens based on a discount choosen and a vesting time
	 * @param _purchaseVestingStarts Vesting start timestamp
	 */
	function purchase (
		uint256 _usd, 
		uint256 _eth, 
		uint256 _btc, 
		address _address,
		uint256 _discountBase,
		uint256 _vesting,
		uint256 _purchaseVestingStarts
	) 
		public
		isActive
		isOwner
		validAddress(_address)
		returns (uint256)
	{
		require(_usd >= 10);

		uint256 soldAmount = computeTokens(_usd);
		soldAmount = computeBonus(soldAmount, _discountBase);

		if (_purchaseVestingStarts < startVesting){
			_purchaseVestingStarts = startVesting;
		}

		grantVestedTokens(
			_address, 
			soldAmount, 
			_purchaseVestingStarts, 
			_vesting
		);
		updateStats(_usd, soldAmount);
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
	function computeBonus(uint256 _amount, uint256 _discountBase) internal pure returns (uint256){
		require (_discountBase >= 80);
		require (_discountBase <= 100);
		return _amount * 100 / _discountBase;
	}

	/**
	* @dev Number of tokens is given by:
	* 70,000,000 ln((7,000,000 + raised + usd) / (7,000,000 + raised))
	*/
	function computeTokens(uint256 usd) public constant returns (uint256) {
		require (usd > 0);

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

	/**
	* @dev Computes ln(x) with 18 artifical decimal places for input and output
	* This algotihm uses a logarithm of the form
	* ln(x) = ln(y * 1.5^k) = k ln(1.5) + ln(y)
	* where ln(1.5) is a known value and ln(y) is computed with a tayilor series for
	* 1 < y < 1.5 which is within radius of convergence of the Taylor series.
	* https://en.wikipedia.org/wiki/Natural_logarithm#Derivative.2C_Taylor_series
	*/
	function ln(uint256 x) internal pure returns (uint256) {
		uint256 result = 0;
		uint256 k = 0;
		uint256 n = 1;

		uint256 powY;
		uint256 y;

		while (x >= 1500000000000000000){
			k += 1;
			x = x * 2 / 3; // same as x / 1.5
		}

		result = k * 405465000000000000;
		y = x - 1000000000000000000;
		powY = y;

		while (n < 10){
			result = result + (powY / n);
			n = n + 1;
			powY = powY * y / 1000000000000000000;
			result = result - (powY / n);
			n = n + 1;
			powY = powY * y / 1000000000000000000;
		}

		return result;
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
    ) 
        internal
    {
        token.grantVestedTokens(
	        _to,
	        _value,
	        _start,
	        _vesting
        );
    }
}
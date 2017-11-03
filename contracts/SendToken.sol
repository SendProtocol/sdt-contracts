pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import './SCNS1.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';


/**
 * @title Send token
 *
 * @dev Implementation of Send Consensus network Standard
 * @dev https://send.sd/token
 */
contract SendToken is SCNS1, StandardToken {
    
    struct Poll {
        address creator;
        uint256 minimumTokens;
        uint256 startTime;
        uint256 endTime;
    }

    struct Lock {
        uint256 value;
        uint256 fee;
        uint256 expirationTime;
    }

    struct TokenGrant {
        uint256 value;
        uint256 claimed;
        uint64 cliff;
        uint64 vesting;
        uint64 start;
    }

    address public owner;
    address public ico;
    address public saleWallet;
    uint256 public maxSupply;

    mapping (address => TokenGrant[]) public grants;
    mapping (uint256 => Poll) public polls;
    mapping (address => bool) internal verifiedAddresses;
    mapping (address => uint256) internal lockedBalances;
    mapping (uint256 => mapping(address => bool)) internal voted;
    mapping (address => mapping(address => mapping(uint256 => Lock))) internal lockedAllowed;

    modifier ownerRestricted(){
        require(msg.sender == owner);
        _;
    }

    modifier verifiedResticted(){
        require(verifiedAddresses[msg.sender]);
        _;
    }

    modifier icoResticted(){
        require(msg.sender == ico);
        _;
    }

    /**
    * @dev Check if an address is whitelisted by SEND
    * @param _address Address to check
    * @return bool
    */
    function isVerified(address _address) public constant returns (bool) {
        return verifiedAddresses[_address];
    }

    /**
    * @dev Get locked balance of a given address
    * @param _owner Address to check
    * @return A uint256 representing the locked amount of tokens
    */
    function lockedBalanceOf(address _owner) public constant returns (uint256) {
        return lockedBalances[_owner];
    }

    /**
    * @dev Verify an addres
    * @notice Only contract owner
    * @param _address Address to verify
    */
    function verify(address _address) ownerRestricted {
        verifiedAddresses[_address] = true;
    }

    /**
    * @dev Remove Verified status of a given address
    * @notice Only contract owner
    * @param _address Address to unverify
    */
    function unverify(address _address) ownerRestricted {
        verifiedAddresses[_address] = false;
    }

    /**
    * @dev Create a poll
    * @dev _question and _options parameters are only for logging
    * @notice Only verified addresses
    * @param _id Poll ID. Must not exist already.
    * @param _question An string to be logged on poll creation
    * @param _options An array of strings to be logged on poll creation
    * @param _minimumTokens Minimum number of tokens to vote
    * @param _startTime Poll start time
    * @param _endTime Poll end time
    */
    function createPoll (
        uint256 _id, 
        bytes32 _question, 
        bytes32[] _options, 
        uint256 _minimumTokens, 
        uint256 _startTime, 
        uint256 _endTime
    ) 
        verifiedResticted
    {
        require(polls[_id].creator == 0);

        polls[_id].creator = msg.sender;
        polls[_id].minimumTokens = _minimumTokens;
        polls[_id].startTime = _startTime;
        polls[_id].endTime = _endTime;

        PollCreated(
            msg.sender, 
            _id, _question, 
            _options, 
            _minimumTokens, 
            _startTime, 
            _endTime
        );

    }

    /**
    * @dev vote
    * @dev will fail if doesnt meet minimumTokens requirement on poll dates
    * @notice Only once per address per poll
    * @param _id Poll ID. Must not exist already.
    * @param _option Index of option to vote (first option is 0)
    */
    function vote(uint256 _id, uint256 _option) public {
        require(polls[_id].creator != 0);
        require(voted[_id][msg.sender] == false);
        require(balances[msg.sender] >= polls[_id].minimumTokens);
        require(polls[_id].startTime <= block.timestamp);
        require(polls[_id].endTime >= block.timestamp);

        voted[_id][msg.sender] = true;
        Voted(_id, msg.sender, _option);
    }

    /**
    * @dev Authorize an address to perform a locked transfer
    * @dev specified amount will be locked on msg.sender
    * @param _authority Address to be authorized to spend locked funds
    * @param _referenceId Intenral ID for applications implementing this
    * @param _value Amount of tokens to lock
    * @param _authorityFee A fee to be paid to authority (may be 0)
    * @param _expirationTime After this timestamp, user can claim tokens back.
    */
    function approveLockedTransfer(
        address _authority, 
        uint256 _referenceId, 
        uint256 _value, 
        uint256 _authorityFee, 
        uint256 _expirationTime
    ) 
    public
    {
        uint256 total = _value + _authorityFee;

        require(lockedAllowed[msg.sender][_authority][_referenceId].value == 0);
        require(balances[msg.sender] >= total);

        lockedAllowed[msg.sender][_authority][_referenceId].value = _value;
        lockedAllowed[msg.sender][_authority][_referenceId].fee = _authorityFee;
        lockedAllowed[msg.sender][_authority][_referenceId].expirationTime = _expirationTime;

        lockedBalances[msg.sender] = lockedBalances[msg.sender].add(total);
        balances[msg.sender] = balances[msg.sender].sub(total);

        EscrowCreated(msg.sender, _authority, _referenceId);
    }

    /**
    * @dev Transfer a locked amount
    * @notice Only authorized address
    * @notice Exchange rate has 18 decimal places
    * @param _sender Address with locked amount
    * @param _recipient Address to send funds to
    * @param _referenceId App/user internal associated ID
    * @param _exchangeRate Rate to be reported to the blockchain
    */
    function executeLockedTransfer(
        address _sender, 
        address _recipient, 
        uint256 _referenceId, 
        uint256 _exchangeRate
    ) 
    public
    {
        uint256 _value = lockedAllowed[_sender][msg.sender][_referenceId].value;
        uint256 _fee = lockedAllowed[_sender][msg.sender][_referenceId].fee;

        require(_value > 0);

        if (verifiedAddresses[msg.sender]) {
            require(_exchangeRate > 0);
        } else {
            require(_exchangeRate == 0);
        }

        lockedBalances[_sender] = lockedBalances[_sender].sub(_value + _fee);
        balances[_recipient] = balances[_recipient].add(_value);
        if (_fee > 0) {
            balances[msg.sender] = balances[msg.sender].add(_fee);
        }
        delete lockedAllowed[_sender][msg.sender][_referenceId];

        EscrowResolved(
            _sender, 
            msg.sender, 
            _referenceId, 
            msg.sender, 
            _recipient
        );

        if (_sender == _recipient) {
            return;
        }
        if (_exchangeRate == 0) {
            Transfer(_sender, _recipient, _value);
        } else {
            VerifiedTransfer(
                _sender, 
                _recipient, 
                msg.sender, 
                _value, 
                _referenceId, 
                _exchangeRate
            );
        }
    }

    /**
    * @dev claim back locked amount after expiration time
    * @notice Only works after lock expired
    * @param _authority Authorized lock address
    * @param _referenceId reference ID from App/user
    */
    function claimLockedTransfer(address _authority, uint256 _referenceId) public {
        require(lockedAllowed[msg.sender][_authority][_referenceId].value > 0);
        require(lockedAllowed[msg.sender][_authority][_referenceId].expirationTime < block.timestamp);
        require(lockedAllowed[msg.sender][_authority][_referenceId].expirationTime != 0);

        uint256 _value = lockedAllowed[msg.sender][_authority][_referenceId].value;
        uint256 _fee = lockedAllowed[msg.sender][_authority][_referenceId].fee;

        lockedBalances[msg.sender] = lockedBalances[msg.sender].sub(_value.add(_fee));
        balances[msg.sender] = balances[msg.sender].add(_value.add(_fee));

        delete lockedAllowed[msg.sender][_authority][_referenceId];

        EscrowResolved (
            msg.sender, 
            _authority, 
            _referenceId, 
            msg.sender, 
            msg.sender
        );
    }

    /**
    * @dev Remove expiration time on a lock
    * @notice User wont be able to claim tokens back after this is called by authority address
    * @notice Only authorized address
    * @param _sender Address with locked amount
    * @param _referenceId App/user internal associated ID
    */
    function invalidateLockedTransferExpiration(address _sender, uint256 _referenceId) public {
        require(lockedAllowed[_sender][msg.sender][_referenceId].value > 0);
        lockedAllowed[_sender][msg.sender][_referenceId].expirationTime = 0;
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
    ) 
    verifiedResticted 
    {
        require(_to != address(0));
        require(_exchangeRate > 0);

        uint256 total = _value.add(_fee);

        require(total <= balances[_from]);
        require(total <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(total);
        balances[_to] = balances[_to].add(_value);
        if (_fee >= 0) {
            balances[msg.sender] = balances[msg.sender].add(_fee);
        }
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(total);
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
    * @dev Calculate vested claimable tokens on current time
    * @param _tokens Number of tokens granted
    * @param _cliff Cliff timestamp
    * @param _vesting Vesting finish timestamp
    * @param _start Vesting start timestamp
    * @param _claimed Number of tokens already claimed
    */
    function calculateVestedTokens(
        uint256 _tokens,
        uint256 _cliff,
        uint256 _vesting,
        uint256 _start,
        uint256 _claimed
    ) 
        internal constant returns (uint256)
    {
        uint256 time = block.timestamp;

        if (time < _cliff) {
            return 0;
        }
        if (time >= _start + _vesting) {
            return SafeMath.sub(_tokens, _claimed);
        }
        uint256 vestedTokens = SafeMath.div(
            SafeMath.mul(_tokens, SafeMath.sub(time, _start)),
            SafeMath.sub(_vesting, _start)
        );

        return SafeMath.sub(vestedTokens, _claimed);
    }

    /**
    * @dev Grant vested tokens
    * @notice Only for ICO contract address
    * @param _to Addres to grant tokens to.
    * @param _value Number of tokens granted
    * @param _cliff Cliff timestamp
    * @param _vesting Vesting finish timestamp
    * @param _start Vesting start timestamp
    */
    function grantVestedTokens(
        address _to,
        uint256 _value,
        uint64 _start,
        uint64 _cliff,
        uint64 _vesting
    ) 
        icoResticted
        public 
    {   
        require (_value > 0);
        require (_cliff > _start);
        require (_vesting > _start);
        require (_vesting > _cliff);
        require (grants[_to].length < 10);

        TokenGrant memory grant = TokenGrant(_value, 0, _cliff, _vesting, _start);
        grants[_to].push(grant);

        balances[saleWallet] = balances[saleWallet].sub(_value);
        
        NewTokenGrant(_to, _value, _cliff,  _start, _vesting);
    }

    /**
    * @dev Claim all vested tokens up to current date
    */
    function claimTokens() public returns (uint256) {
        uint256 numberOfGrants = grants[msg.sender].length;

        if (numberOfGrants == 0) {
            return 0;
        }

        uint256 claimable = 0;
        uint256 claimableFor = 0;
        for (uint256 i = 0; i < numberOfGrants; i++) {
            claimableFor = calculateVestedTokens (
                grants[msg.sender][i].value,
                grants[msg.sender][i].cliff,
                grants[msg.sender][i].vesting,
                grants[msg.sender][i].start,
                grants[msg.sender][i].claimed
            );
            claimable = SafeMath.add (
                claimable, 
                claimableFor
            );
            grants[msg.sender][i].claimed = SafeMath.add (
                grants[msg.sender][i].claimed,
                claimableFor
            );
        }

        balances[msg.sender] = balances[msg.sender].add(claimable);
        totalSupply += claimable;

        NewTokenClaim(msg.sender, claimable);
    }

}
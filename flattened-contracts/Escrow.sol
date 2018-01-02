pragma solidity ^0.4.18;

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

// File: zeppelin-solidity/contracts/token/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

// File: contracts/ISnapshotToken.sol

/**
 * @title Snapshot Token
 *
 * @dev Snapshot Token interface
 * @dev https://send.sd/token
 */
contract ISnapshotToken is BurnableToken {
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
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
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

// File: contracts/ISendToken.sol

/**
 * @title ISendToken - Send Consensus Network Token interface
 * @dev token interface built on top of ERC20 standard interface
 * @dev see https://send.sd/token
 */
contract ISendToken is SnapshotToken {
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

// File: contracts/Escrow.sol

/**
 * @title Vesting contract for SDT
 * @dev see https://send.sd/token
 */
contract Escrow {
  address public tokenAddress;
  ISendToken public token;

  struct Lock {
    uint256 value;
    uint256 fee;
    uint256 expiration;
  }

  mapping (address => mapping(address => mapping(uint256 => Lock))) internal escrows;

  function Escrow(address _token) public {
    token = ISendToken(_token);
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

  modifier tokenRestricted() {
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

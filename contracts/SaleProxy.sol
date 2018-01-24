pragma solidity ^0.4.18;

import './ITokenSale.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/token/ERC20Basic.sol';

contract SaleProxy is Ownable {
  uint256 public discountBase;
  uint256 public vestingTime;
  ITokenSale public saleContract;

  function SaleProxy(
    address _saleContract,
    uint256 _vestingTime,
    uint256 _discountBase
  ) public {
    saleContract = ITokenSale(_saleContract);
    vestingTime = _vestingTime;
    discountBase = _discountBase;
  }

  function () external payable {
    require(saleContract.ethPurchase.value(msg.value)(msg.sender, vestingTime, discountBase));
  }

  function btcPurchase(address _beneficiary, uint256 _btcValue) public {
    require(saleContract.btcPurchase(_beneficiary, vestingTime, discountBase, _btcValue));
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

    ERC20Basic token = ERC20Basic(_token);
    uint256 balance = token.balanceOf(this);
    token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
}

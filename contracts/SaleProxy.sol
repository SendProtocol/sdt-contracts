pragma solidity ^0.4.18;

import './ITokenSale.sol';

contract SaleProxy {
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
    saleContract.ethPurchase.value(msg.value)(msg.sender, vestingTime, discountBase);
  }

  function btcPurchase(address _beneficiary, uint256 _btcValue) public {
    saleContract.btcPurchase(_beneficiary, vestingTime, discountBase, _btcValue);
  }
}

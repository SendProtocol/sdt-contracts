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

// File: contracts/SaleProxy.sol

contract SaleProxy {
  uint256 public discounBase;
  uint256 public vestingTime;
  ITokenSale public saleContract;

  function SaleProxy(
    address _saleContract,
    uint256 _vestingTime,
    uint256 _discountBase
  ) public {
    saleContract = ITokenSale(_saleContract);
    vestingTime = _vestingTime;
    discounBase = _discountBase;
  }

  function () external payable {
    saleContract.ethPurchase.value(msg.value)(msg.sender, vestingTime, discounBase);
  }

  function btcPurchase(address _beneficiary, uint256 _btcValue) public {
    saleContract.btcPurchase(_beneficiary, vestingTime, discounBase, _btcValue);
  }
}

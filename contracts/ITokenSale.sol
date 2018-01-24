pragma solidity ^0.4.18;


/**
 * @title Crowdsale contract Interface for Receiver contracts
 * @dev see https://send.sd/crowdsale
 */
contract ITokenSale {
  function ethPurchase(address _beneficiary, uint256 _vestingTime, uint256 _discountBase) public payable returns(bool);
  function btcPurchase(address _beneficiary, uint256 _vestingTime, uint256 _discountBase, uint256 btcValue) public returns(bool);
}

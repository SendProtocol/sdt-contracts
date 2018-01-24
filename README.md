Contracts for SEND Token (SDT) as described in https://send.sd/documents/sale_economics.pdf and https://send.sd/documents/whitepaper.pdf

---------------------------------

For more information about SEND: https://send.sd

---------------------------------

A brief description of the contracts:

`Escrow.sol` The escrow contract for SEND token, transactions running over this escrow contract can issue exchange rate events if arbitrator is verified address.

`Polls.sol` A contract to handle poll's logic for SDT holders.

`SDT.sol` The contract to deploy the token instance itself.

`SaleProxy.col` a proxy contract to send buy with a specific discount/vesting period (as described in https://send.sd/documents/sale_economics.pdf) without the need of additional inputs on user's side.

`SendToken.sol` A token implementing SEND Token features.

`SnapshotToken.sol` A token with an efficient mechanism to sotre balance snapshots used by SEND Token.

`TokenSale.sol` A sale contract as described in https://send.sd/documents/sale_economics.pdf

`TokenVesting.sol` A contract to store vested SDT tokens where user's can claim vested tokens if whitelisted by SEND.


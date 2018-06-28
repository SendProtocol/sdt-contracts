![alt text](https://github.com/SendProtocol/sdt-contracts/blob/master/870x120.png)


## SEND (SDT)

For more information about Send (SDT) check our website: https://www.sendprotocol.com

---------------------------------

## Smart Contracts

Contracts for Send Token (SDT) as described in Send's [Token Economics](https://www.sendprotocol.com/documents/economics.pdf) and [Whitepaper](https://www.sendprotocol.com/documents/whitepaper.pdf)

### Token 
[Snapshot.sol](contracts/SnapshotToken.sol) A token with an efficient mechanism to store balance snapshots.

[SendToken.sol](contracts/SendToken.sol) A token implementing SDT features.

[SDT.sol](contracts/SDT.sol) The SDT token contract.

### Crowdsale

[TokenSale.sol](contracts/TokenSale.sol) A sale contract as described in Send's [Token Economics](https://www.sendprotocol.com/documents/economics.pdf) 

[Distribution.sol](contracts/Distribution.sol) A contract to handle SDT's distribution process as described in Send's [Token Economics](https://www.sendprotocol.com/documents/economics.pdf) 

[TokenVestg.sol](contracts/TokenVesting.sol) A contract to store vested SDT tokens. Users can claim vested tokens if whitelisted by Send.

### Utils
[Escrow.sol](contracts/Escrow.sol) The escrow contract for SDT token, transactions running on this escrow contract can issue exchange rate events if arbitrator is a verified address.

[Polls.sol](contracts/Polls.sol) A contract to handle poll's logic for SDT holders.

## Deployment flow
- Deploy sale contract
- Deploy vesting contract
- Deploy token with sale contract address
- Deploy distribution contract with token's address
- Initialize vesting contract with token and sale addresses
- Set BTC and ETH exchange rates on sale contract
- Initialize sale with token, distribution and vesting addresses
- Deploy escrow contract and link on token contract

## Reviewers and audits
- Marcio Abreu (Author) - CTO @ Send
- Klaus Hott (Author) - Blockchain Advisor @ Send
- CoinFabrik (Auditor) - Blockchain Technologies, FinTech and Smart Contracts Development: [Security audit results](https://blog.coinfabrik.com/security-audit-send-sdt-token-sale-ico-smart-contract/)
- Community review - [Bug bounty program](https://medium.com/sendprotocol/send-sdt-bug-bounty-report-3cfde316f0b7)

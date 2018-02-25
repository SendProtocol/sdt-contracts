module.exports = {
  copyNodeModules: true,
  norpc: true,
  skipFiles: [
    "Migrations.sol",
    "ISendToken.sol",
    "ISnapshotToken.sol",
    "IEscrow.sol",
    "ITokenSale.sol"
  ],
  testCommand: "node_modules/.bin/truffle test --network coverage"
};

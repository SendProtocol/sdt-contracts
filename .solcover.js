module.exports = {
  copyNodeModules: true,
  norpc: true,
  skipFiles: ["Migrations.sol"],
  testCommand: "node_modules/.bin/truffle test --network coverage"
};

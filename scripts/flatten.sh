#!/usr/bin/env bash

rm flattened-contracts/*

declare -a contracts=(
    "TokenVesting.sol"
    "TokenSale.sol"
    "SaleProxy.sol"
    "SDT.sol"
    "Escrow.sol"
)

for i in "${contracts[@]}"
do
    node_modules/.bin/truffle-flattener contracts/$i >> flattened-contracts/$i
done

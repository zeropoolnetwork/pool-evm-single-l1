#!/usr/bin/env bash
set -m
npx hardhat node --hostname 127.0.0.1 &
sleep 2
echo 'Deploying contract'
MOCK_TX_VERIFIER=true MOCK_TREE_VERIFIER=true MOCK_DELEGATED_DEPOSIT_VERIFIER=true npx hardhat run scripts/deploy-task.js --network localhost && echo 'Contract deployed'
fg

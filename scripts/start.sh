#!/usr/bin/env bash
set -m
npx hardhat node &
sleep 2
echo 'Deploying contract'
npx hardhat run scripts/deploy-task.js --network localhost && echo 'Contract deployed'
fg

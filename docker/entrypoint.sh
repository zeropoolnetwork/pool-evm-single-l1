#!/usr/bin/env bash

cd /app

yarn start:local &
NODE_PID=$!

yarn deploy:local

wait $NODE_PID

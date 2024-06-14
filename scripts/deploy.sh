#!/bin/bash

# Load variables from .env file
set -o allexport
source scripts/.env
set +o allexport

# -------------- #
# Initial checks #
# -------------- #
if [ -z "$RPC_URL" ] || [ -z "$PRIVATE_KEY" ]
then
    echo "RPC_URL or PRIVATE_KEY is not set. Set them in the .env file"
    exit 0
fi

# Prepare transactions data
cargo stylus deploy -e $RPC_URL --private-key $PRIVATE_KEY

# ./scripts/deploy.sh
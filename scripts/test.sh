#!/bin/bash

# Load variables from .env file
set -o allexport
source scripts/.env
set +o allexport

# -------------- #
# Initial checks #
# -------------- #
if [ -z "$RECEIVER_ADDRESS" ] || [ -z "$RECEIVER_PRIVATE_KEY" ]
then
    echo "RECEIVER_ADDRESS or RECEIVER_PRIVATE_KEY is not set. Set them in the .env file"
    exit 0
fi

if [ -z "$CONTRACT_ADDRESS" ]
then
    echo "CONTRACT_ADDRESS is not set"
    echo "You can run the script by setting the variables at the beginning: CONTRACT_ADDRESS=0x test.sh"
    exit 0
fi

echo "Testing contract deployed at $CONTRACT_ADDRESS"

# Initial balances
initial_balance=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "balanceOf(address) (uint256)" $ADDRESS)
echo "Initial balance of $ADDRESS: $initial_balance"
initial_receiver_balance=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "balanceOf(address) (uint256)" $RECEIVER_ADDRESS)
echo "Initial balance of $RECEIVER_ADDRESS: $initial_receiver_balance"

# Initial allowance
initial_allowance=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "allowance(address,address) (uint256)" $RECEIVER_ADDRESS $ADDRESS)
echo "Initial allowance of $ADDRESS (to transfer tokens from $RECEIVER_ADDRESS): $initial_allowance"

# Initial supply
initial_total_supply=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "totalSupply() (uint256)")
echo "Initial supply: $initial_total_supply"


# -----------------
# Token information
# -----------------
echo ""
echo "*****************"
echo "Token information"
echo "*****************"
token_name=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "name() (string)")
token_symbol=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "symbol() (string)")
token_decimals=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "decimals() (uint8)")

echo "Name: $token_name"
echo "Symbol: $token_symbol"
echo "Decimals: $token_decimals"


# ------------
# Minting test
# ------------
echo ""
echo "************"
echo "Minting test"
echo "************"

echo "Minting 15 tokens"
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $CONTRACT_ADDRESS "mint(uint256) ()" 15

echo "Minting 10 tokens to $RECEIVER_ADDRESS"
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $CONTRACT_ADDRESS "mintTo(address,uint256) ()" $RECEIVER_ADDRESS 10

# Check balances
balance_after_mint=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "balanceOf(address) (uint256)" $ADDRESS)
echo "New balance of $ADDRESS: $balance_after_mint"
expected_balance=$((initial_balance + 15))
if [ "$balance_after_mint" -ne "$expected_balance" ]; then
    echo "New balance ($balance_after_mint) is not the expected balance ($expected_balance)"
    exit 1
fi

receiver_balance_after_mint=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "balanceOf(address) (uint256)" $RECEIVER_ADDRESS)
echo "New balance of $RECEIVER_ADDRESS: $receiver_balance_after_mint"
expected_receiver_balance=$((initial_receiver_balance + 10))
if [ "$receiver_balance_after_mint" -ne "$expected_receiver_balance" ]; then
    echo "New balance ($receiver_balance_after_mint) is not the expected balance ($expected_receiver_balance)"
    exit 1
fi

# Check total supply
total_supply_after_mint=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "totalSupply() (uint256)")
echo "New total supply: $total_supply_after_mint"
expected_total_supply=$((initial_total_supply + 15 + 10))
if [ "$total_supply_after_mint" -ne "$expected_total_supply" ]; then
    echo "New total supply ($total_supply_after_mint) is not the expected total supply ($expected_total_supply)"
    exit 1
fi


# ------------
# Burning test
# ------------
echo ""
echo "************"
echo "Burning test"
echo "************"

echo "Burning 5 tokens"
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $CONTRACT_ADDRESS "burn(uint256) ()" 5

# Check balance
balance_after_burn=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "balanceOf(address) (uint256)" $ADDRESS)
echo "New balance of $ADDRESS: $balance_after_burn"
expected_balance=$((balance_after_mint - 5))
if [ "$balance_after_burn" -ne "$expected_balance" ]; then
    echo "New balance ($balance_after_burn) is not the expected balance ($expected_balance)"
    exit 1
fi

# Check total supply
total_supply_after_burn=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "totalSupply() (uint256)")
echo "New total supply: $total_supply_after_burn"
expected_total_supply=$((total_supply_after_mint - 5))
if [ "$total_supply_after_burn" -ne "$expected_total_supply" ]; then
    echo "New total supply ($total_supply_after_burn) is not the expected total supply ($expected_total_supply)"
    exit 1
fi


# -------------
# Transfer test
# -------------
echo ""
echo "*************"
echo "Transfer test"
echo "*************"

echo "Transferring 5 tokens from $ADDRESS to $RECEIVER_ADDRESS"
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $CONTRACT_ADDRESS "transfer(address,uint256) ()" $RECEIVER_ADDRESS 5

# Check balances
balance_after_transfer=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "balanceOf(address) (uint256)" $ADDRESS)
echo "New balance of $ADDRESS: $balance_after_transfer"
expected_balance=$((balance_after_burn - 5))
if [ "$balance_after_transfer" -ne "$expected_balance" ]; then
    echo "New balance ($balance_after_transfer) is not the expected balance ($expected_balance)"
    exit 1
fi

receiver_balance_after_transfer=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "balanceOf(address) (uint256)" $RECEIVER_ADDRESS)
echo "New balance of $RECEIVER_ADDRESS: $receiver_balance_after_transfer"
expected_receiver_balance=$((receiver_balance_after_mint + 5))
if [ "$receiver_balance_after_transfer" -ne "$expected_receiver_balance" ]; then
    echo "New balance ($receiver_balance_after_transfer) is not the expected balance ($expected_receiver_balance)"
    exit 1
fi

# Check total supply
total_supply_after_transfer=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "totalSupply() (uint256)")
echo "New total supply: $total_supply_after_transfer"
expected_total_supply=$total_supply_after_burn
if [ "$total_supply_after_transfer" -ne "$expected_total_supply" ]; then
    echo "New total supply ($total_supply_after_transfer) is not the expected total supply ($expected_total_supply)"
    exit 1
fi


# --------------------
# Transfer revert test
# --------------------
echo ""
echo "********************"
echo "Transfer revert test"
echo "********************"

tokens_to_transfer=$((balance_after_transfer + 10))
echo "Transferring $tokens_to_transfer tokens from $ADDRESS to $RECEIVER_ADDRESS (should revert)"
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $CONTRACT_ADDRESS "transfer(address,uint256) ()" $RECEIVER_ADDRESS $tokens_to_transfer

# Check balances
balance_after_transfer_revert=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "balanceOf(address) (uint256)" $ADDRESS)
echo "New balance of $ADDRESS: $balance_after_transfer_revert"
expected_balance=$balance_after_transfer
if [ "$balance_after_transfer_revert" -ne "$expected_balance" ]; then
    echo "New balance ($balance_after_transfer_revert) is not the expected balance ($expected_balance)"
    exit 1
fi

receiver_balance_after_transfer_revert=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "balanceOf(address) (uint256)" $RECEIVER_ADDRESS)
echo "New balance of $RECEIVER_ADDRESS: $receiver_balance_after_transfer_revert"
expected_receiver_balance=$receiver_balance_after_transfer
if [ "$receiver_balance_after_transfer_revert" -ne "$expected_receiver_balance" ]; then
    echo "New balance ($receiver_balance_after_transfer_revert) is not the expected balance ($expected_receiver_balance)"
    exit 1
fi


# -------------
# Approval test
# -------------
echo ""
echo "*************"
echo "Approval test"
echo "*************"

echo "Approving $ADDRESS to be able to spend 5 tokens from $RECEIVER_ADDRESS"
cast send --rpc-url $RPC_URL --private-key $RECEIVER_PRIVATE_KEY $CONTRACT_ADDRESS "approve(address,uint256) ()" $ADDRESS 5

# Check allowance
allowance_after_approval=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "allowance(address,address) (uint256)" $RECEIVER_ADDRESS $ADDRESS)
echo "New allowance of $ADDRESS (to transfer tokens from $RECEIVER_ADDRESS): $allowance_after_approval"
expected_allowance=$((initial_allowance + 5))
if [ "$allowance_after_approval" -ne "$expected_allowance" ]; then
    echo "New allowance ($allowance_after_approval) is not the expected allowance ($expected_allowance)"
    exit 1
fi

# -----------------
# TransferFrom test
# -----------------
echo ""
echo "*****************"
echo "TransferFrom test"
echo "*****************"

echo "Transferring 5 tokens from $RECEIVER_ADDRESS to $ADDRESS (by calling transferFrom with $ADDRESS)"
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $CONTRACT_ADDRESS "transferFrom(address,address,uint256) ()" $RECEIVER_ADDRESS $ADDRESS 5

# Check balances
balance_after_transfer_from=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "balanceOf(address) (uint256)" $ADDRESS)
echo "New balance of $ADDRESS: $balance_after_transfer_from"
expected_balance=$((balance_after_transfer + 5))
if [ "$balance_after_transfer_from" -ne "$expected_balance" ]; then
    echo "New balance ($balance_after_transfer_from) is not the expected balance ($expected_balance)"
    exit 1
fi

receiver_balance_after_transfer_from=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "balanceOf(address) (uint256)" $RECEIVER_ADDRESS)
echo "New balance of $RECEIVER_ADDRESS: $receiver_balance_after_transfer_from"
expected_receiver_balance=$((receiver_balance_after_transfer - 5))
if [ "$receiver_balance_after_transfer_from" -ne "$expected_receiver_balance" ]; then
    echo "New balance ($receiver_balance_after_transfer_from) is not the expected balance ($expected_receiver_balance)"
    exit 1
fi

# Check total supply
total_supply_after_transfer_from=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "totalSupply() (uint256)")
echo "New total supply: $total_supply_after_transfer_from"
expected_total_supply=$total_supply_after_transfer
if [ "$total_supply_after_transfer_from" -ne "$expected_total_supply" ]; then
    echo "New total supply ($total_supply_after_transfer_from) is not the expected total supply ($expected_total_supply)"
    exit 1
fi

# Check allowance
allowance_after_transfer_from=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "allowance(address,address) (uint256)" $RECEIVER_ADDRESS $ADDRESS)
echo "New allowance of $ADDRESS (to transfer tokens from $RECEIVER_ADDRESS): $allowance_after_transfer_from"
expected_allowance=$((allowance_after_approval - 5))
if [ "$allowance_after_transfer_from" -ne "$expected_allowance" ]; then
    echo "New allowance ($allowance_after_transfer_from) is not the expected allowance ($expected_allowance)"
    exit 1
fi


# ------------------------
# TransferFrom revert test
# ------------------------
echo ""
echo "************************"
echo "TransferFrom revert test"
echo "************************"

tokens_to_transfer=$((allowance_after_transfer_from + 10))
echo "Transferring $tokens_to_transfer tokens from $RECEIVER_ADDRESS to $ADDRESS (by calling transferFrom with $ADDRESS, should revert)"
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $CONTRACT_ADDRESS "transferFrom(address,address,uint256) ()" $RECEIVER_ADDRESS $ADDRESS $tokens_to_transfer

# Check balances
balance_after_transfer_from_revert=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "balanceOf(address) (uint256)" $ADDRESS)
echo "New balance of $ADDRESS: $balance_after_transfer_from_revert"
expected_balance=$balance_after_transfer_from
if [ "$balance_after_transfer_from_revert" -ne "$expected_balance" ]; then
    echo "New balance ($balance_after_transfer_from_revert) is not the expected balance ($expected_balance)"
    exit 1
fi

receiver_balance_after_transfer_from_revert=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "balanceOf(address) (uint256)" $RECEIVER_ADDRESS)
echo "New balance of $RECEIVER_ADDRESS: $receiver_balance_after_transfer_from_revert"
expected_receiver_balance=$receiver_balance_after_transfer_from
if [ "$receiver_balance_after_transfer_from_revert" -ne "$expected_receiver_balance" ]; then
    echo "New balance ($receiver_balance_after_transfer_from_revert) is not the expected balance ($expected_receiver_balance)"
    exit 1
fi

# Check allowance
allowance_after_transfer_from_revert=$(cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "allowance(address,address) (uint256)" $RECEIVER_ADDRESS $ADDRESS)
echo "New allowance of $ADDRESS (to transfer tokens from $RECEIVER_ADDRESS): $allowance_after_transfer_from_revert"
expected_allowance=$allowance_after_transfer_from
if [ "$allowance_after_transfer_from_revert" -ne "$expected_allowance" ]; then
    echo "New allowance ($allowance_after_transfer_from_revert) is not the expected allowance ($expected_allowance)"
    exit 1
fi


echo "All tests passed!"

# CONTRACT_ADDRESS= ./scripts/test.sh
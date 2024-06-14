#!/bin/bash

# Load variables from .env file
set -o allexport
source scripts/.env
set +o allexport

# Helper constants
DEPLOY_CONTRACT_RESULT_FILE=create_contract_result

# -------------- #
# Initial checks #
# -------------- #
if [ -z "$RPC_URL" ] || [ -z "$PRIVATE_KEY" ]
then
    echo "RPC_URL or PRIVATE_KEY is not set. Set them in the .env file"
    exit 0
fi

echo ""
echo "-------------------------"
echo "Deploying ERC-20 contract"
echo "-------------------------"

# Prepare transactions data
cargo stylus deploy -e $RPC_URL --private-key $PRIVATE_KEY > $DEPLOY_CONTRACT_RESULT_FILE

# Get contract address (last "sed" command removes the color codes of the output)
# (Note: last regex obtained from https://stackoverflow.com/a/51141872)
erc20_contract_address_str=$(cat $DEPLOY_CONTRACT_RESULT_FILE | sed -n 2p)
if ! [[ $erc20_contract_address_str == *0x* ]]
then
    # When the program needs activation, the output of the command is slightly different
    erc20_contract_address_str=$(cat $DEPLOY_CONTRACT_RESULT_FILE | sed -n 3p)
fi
erc20_contract_address_array=($erc20_contract_address_str)
erc20_contract_address=$(echo ${erc20_contract_address_array[2]} | sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g')
rm $DEPLOY_CONTRACT_RESULT_FILE

# Final result
echo "ERC-20 contract deployed and activated at address: $erc20_contract_address"

echo ""
echo "------------------------"
echo "Deploying Proxy contract"
echo "------------------------"

# Move to nft folder
cd ./proxy

# Get current block number for filtering events later
from_block=$(cast block-number --rpc-url $RPC_URL)

# Compile and deploy Proxy contract
initialize_data=0x
forge build
forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY src/Proxy.sol:Proxy --constructor-args $erc20_contract_address $ADDRESS $initialize_data > $DEPLOY_CONTRACT_RESULT_FILE

# Get contract address
proxy_contract_address_str=$(cat $DEPLOY_CONTRACT_RESULT_FILE | sed -n 3p)
proxy_contract_address_array=($proxy_contract_address_str)
proxy_contract_address=${proxy_contract_address_array[2]}

# Get transaction hash (to obtain the ProxyAdmin address)
transaction_hash_str=$(cat $DEPLOY_CONTRACT_RESULT_FILE | sed -n 4p)
transaction_hash_array=($transaction_hash_str)
transaction_hash=${transaction_hash_array[2]}

# Obtain logs and extract proxy admin address
admin_changed_log_data_str=$(cast logs --rpc-url $RPC_URL --from-block $from_block --to-block latest --address $proxy_contract_address 'AdminChanged(address previousAdmin, address newAdmin)' | sed -n 4p)
admin_changed_log_data_array=($admin_changed_log_data_str)
admin_changed_log_data=${admin_changed_log_data_array[1]}
proxy_admin_address=$(echo $admin_changed_log_data | grep -o ".\{40\}$")

# Remove all files
rm $DEPLOY_CONTRACT_RESULT_FILE

# Final result
echo "Proxy contract deployed at address: $proxy_contract_address"
echo "Proxy admin: 0x$proxy_admin_address"

# ------------ #
# Final result #
# ------------ #
echo ""
echo "Contracts deployed and initialized"
echo "Solidity ERC-20 contract deployed at address: $erc20_contract_address"
echo "Proxy contract deployed at address: $proxy_contract_address"
echo "Proxy admin created at address: 0x$proxy_admin_address"

# ./scripts/deployWithProxy.sh
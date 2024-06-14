# Stylus ERC-20 example

Implementation example of an ERC-20 token contract written in Rust for Arbitrum Stylus. 

Disclaimer: this code is unaudited and not fit for production use.

## Getting started

Follow the instructions in the [Stylus quickstart](https://docs.arbitrum.io/stylus/stylus-quickstart) to configure your development environment.

## Deploying and testing the contract

The `scripts` folder contains two scripts to deploy and test the contract:

1. [./scripts/deploy.sh](./scripts/deploy.sh) deploys the contract to the chain specified in the .env file, using cargo-stylus
2. [./scripts/test.sh](./scripts/test.sh) performs a series of calls to verify that the contract behaves as expected 

Remember to set the environment variables in an `.env` file.

## Deploying behind a proxy

This project also includes a Solidity Proxy to deploy the ERC-20 contract behind it, so it can be upgraded in the future. To do this, use the script [./scripts/deployWithProxy.sh](./scripts/deployWithProxy.sh).

To update the logic contract, use the script [./scripts/updateLogic.sh](./scripts/updateLogic.sh).

Note that this Proxy is based on the TransparentUpgradeableProxy of Solidity, but the ERC-20 contract itself is not Initializable.


## How to run a local Stylus dev node

Instructions to setup a local Stylus dev node can be found [here](https://docs.arbitrum.io/stylus/how-tos/local-stylus-dev-node).

## How to get ETH for the Stylus testnet

The Stylus testnet is an L3 chain that settles to Arbitrum Sepolia. The usual way of obtaining ETH is to bridge it from Arbitrum Sepolia through the [Arbitrum Bridge](https://bridge.arbitrum.io/?destinationChain=stylus-testnet&sourceChain=arbitrum-sepolia). You can find a list of Arbitrum Sepolia faucets [here](https://docs.arbitrum.io/stylus/reference/testnet-information#faucets).

## Useful resources

- [Stylus quickstart](https://docs.arbitrum.io/stylus/stylus-quickstart)
- [Stylus by example](https://arbitrum-stylus-by-example.vercel.app/)
- [Awesome Stylus](https://github.com/OffchainLabs/awesome-stylus)
- [Stylus Telegram group](https://t.me/arbitrum_stylus)
- [Discord channel](https://discord.com/channels/585084330037084172/1146789176939909251)

## Stylus reference links

- [Stylus documentation](https://docs.arbitrum.io/stylus/stylus-gentle-introduction)
- [Stylus SDK](https://github.com/OffchainLabs/stylus-sdk-rs)
- [Cargo Stylus](https://github.com/OffchainLabs/cargo-stylus)

-include .env

build:; forge build

deploy-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(ETH_SEPOLIA_RPC_URL) --account defaultKey --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

# https://github.com/Cyfrin/foundry-fund-me-cu/blob/main/Makefile
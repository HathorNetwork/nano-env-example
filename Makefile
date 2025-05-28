# Hathor Wallet Helper Commands
# Default wallet ID
WALLET_ID ?= test-wallet

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help start-wallet get-addresses get-balance get-last-tx-hash get-last-tx get-tx-by-id send-tx deploy-blueprints

help: ## Show this help message
	@echo "$(GREEN)Hathor Wallet Helper Commands$(NC)"
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Usage: make <command> [WALLET_ID=your-wallet-id] [TX_ID=transaction-hash]"
	@echo "Default WALLET_ID: $(WALLET_ID)"

start-wallet: ## Start the wallet with default seed
	@echo "$(GREEN)Starting wallet with ID: $(WALLET_ID)$(NC)"
	@curl -X POST --data "wallet-id=$(WALLET_ID)" \
		--data "seedKey=default" \
		http://wallet.localhost:1337/start

get-addresses: ## Get wallet addresses
	@echo "$(GREEN)Getting addresses for wallet ID: $(WALLET_ID)$(NC)"
	@curl -X GET -H "X-Wallet-Id: $(WALLET_ID)" \
		http://wallet.localhost:1337/wallet/address/

get-balance: ## Get wallet balance
	@echo "$(GREEN)Getting balance for wallet ID: $(WALLET_ID)$(NC)"
	@curl -X GET -H "X-Wallet-Id: $(WALLET_ID)" \
		http://wallet.localhost:1337/wallet/balance

get-last-tx-hash: ## Get the hash of the last transaction in the network
	@response=$$(curl -s -X GET "http://fullnode.localhost:1337/v1a/transaction?count=1&type=tx"); \
	echo "$$response" | jq -r '.transactions[0].hash'

get-last-tx: ## Get the entire last tx
	@response=$$(curl -s -X GET "http://fullnode.localhost:1337/v1a/transaction?count=1&type=tx"); \
	echo "$$response" | jq

get-tx-by-id: ## Get transaction by ID (usage: make get-tx-by-id <hash>)
	@TX_ID="$(filter-out $@,$(MAKECMDGOALS))"; \
	if [ -z "$$TX_ID" ]; then \
		echo "$(RED)Error: Transaction ID is required$(NC)"; \
		echo "Usage: make get-tx-by-id <transaction-hash>"; \
		exit 1; \
	fi; \
	echo "$(GREEN)Getting transaction by ID: $$TX_ID$(NC)"; \
	response=$$(curl -s -X GET "http://fullnode.localhost:1337/v1a/transaction?id=$$TX_ID"); \
	echo "$$response" | jq

send-tx: ## Send transaction (usage: make send-tx <address> <value> [token_uid])
	@ARGS="$(filter-out $@,$(MAKECMDGOALS))"; \
	ADDRESS=$$(echo $$ARGS | cut -d' ' -f1); \
	VALUE=$$(echo $$ARGS | cut -d' ' -f2); \
	TOKEN_UID=$$(echo $$ARGS | cut -d' ' -f3); \
	if [ -z "$$ADDRESS" ] || [ -z "$$VALUE" ]; then \
		echo "$(RED)Error: Address and value are required$(NC)"; \
		echo "Usage: make send-tx <address> <value> [token_uid]"; \
		echo "Example: make send-tx WjhZorHgJ73PGmCndvrciMvPUkzyrRNEZ4 1000"; \
		echo "Example: make send-tx WjhZorHgJ73PGmCndvrciMvPUkzyrRNEZ4 1000 00"; \
		exit 1; \
	fi; \
	echo "$(GREEN)Sending transaction...$(NC)"; \
	echo "$(YELLOW)To: $$ADDRESS$(NC)"; \
	echo "$(YELLOW)Value: $$VALUE$(NC)"; \
	if [ -n "$$TOKEN_UID" ]; then \
		echo "$(YELLOW)Token: $$TOKEN_UID$(NC)"; \
		curl -s -X POST -H "X-Wallet-Id: $(WALLET_ID)" \
			-H "Content-Type: application/json" \
			-d "{\"address\":\"$$ADDRESS\",\"value\":$$VALUE,\"token\":\"$$TOKEN_UID\"}" \
			http://wallet.localhost:1337/wallet/simple-send-tx | jq; \
	else \
		echo "$(YELLOW)Token: HTR (default)$(NC)"; \
		curl -s -X POST -H "X-Wallet-Id: $(WALLET_ID)" \
			-H "Content-Type: application/json" \
			-d "{\"address\":\"$$ADDRESS\",\"value\":$$VALUE}" \
			http://wallet.localhost:1337/wallet/simple-send-tx | jq; \
	fi

# Docker compose helpers
up: ## Start all services
	@echo "$(GREEN)Starting all services...$(NC)"
	@docker compose up -d

down: ## Stop all services
	@echo "$(GREEN)Stopping all services...$(NC)"
	@docker compose down

logs: ## Show wallet logs
	@echo "$(GREEN)Showing all services logs...$(NC)"
	@docker compose logs -f --tail 10

status: ## Show service status
	@echo "$(GREEN)Service status:$(NC)"
	@docker compose ps 

# Prevent make from trying to build the transaction ID as a target
%:
	@: 

deploy-blueprints: ## Deploy all nano contracts from nano_contracts folder
	@echo "$(GREEN)Deploying nano contracts...$(NC)"
	@echo "# Nano Contract Deployments - $$(date)" > deployments.txt
	@for file in nano_contracts/*.py; do \
		if [ -f "$$file" ]; then \
			name=$$(basename "$$file" .py); \
			echo "$(YELLOW)Deploying $$name...$(NC)"; \
			CODE=$$(cat "$$file" | jq -Rs .); \
			response=$$(curl -s -X POST \
				-H "X-Wallet-Id: $(WALLET_ID)" \
				-H "Content-Type: application/json" \
				-d "{\"address\":\"WhpJeUtBLrDHbKDoMC9ffMxwHqvsrNzTFV\",\"code\":$$CODE}" \
				http://wallet.localhost:1337/wallet/nano-contracts/create-on-chain-blueprint); \
			hash=$$(echo "$$response" | jq -r '.hash // empty'); \
			if [ -n "$$hash" ] && [ "$$hash" != "null" ]; then \
				echo "$$name: $$hash"; \
				echo "$$name: $$hash" >> deployments.txt; \
			else \
				echo "$(RED)$$name: FAILED$(NC)"; \
				echo "$$name: FAILED" >> deployments.txt; \
				echo "$$response" | jq; \
			fi; \
		fi; \
	done
	@echo "$(GREEN)Deployment results saved to deployments.txt$(NC)"

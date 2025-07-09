set dotenv-load

# Hathor Wallet Helper Commands
# Default wallet ID
wallet_id := "${WALLET_ID:-test-wallet}"
wallet_url := "${WALLET_URL:-http://wallet.localhost:1337}"
fullnode_url := "${FULLNODE_URL:-http://fullnode.localhost:1337}"

# Show this help message
help:
    @echo "{{GREEN + UNDERLINE}}Hathor Wallet Helper Commands{{NORMAL}}"
    @echo ""
    @just --list --unsorted
    @echo ""
    @echo "Usage: just <command> [wallet_id=your-wallet-id]"
    @echo "The {{BG_WHITE + BLACK}}WALLET_ID{{NORMAL}} can also be set in .env file"

# Start the wallet with default seed
start-wallet wallet_id=wallet_id:
    @echo "{{GREEN + UNDERLINE}}Starting wallet with ID: {{wallet_id}}{{NORMAL}}"
    @curl -X POST --data "wallet-id={{wallet_id}}" \
        --data "seedKey=default" \
        {{wallet_url}}/start

# Get wallet addresses
get-addresses wallet_id=wallet_id:
    echo "{{GREEN + UNDERLINE}}Getting addresses for wallet ID: {{wallet_id}}{{NORMAL}}"
    curl -X GET -H "X-Wallet-Id: {{wallet_id}}" \
        {{wallet_url}}/wallet/address/

# Get wallet balance
get-balance wallet_id=wallet_id:
    @echo "{{GREEN + UNDERLINE}}Getting balance for wallet ID: {{wallet_id}}{{NORMAL}}"
    @curl -X GET -H "X-Wallet-Id: {{wallet_id}}" \
        {{wallet_url}}/wallet/balance

# Get the hash of the last transaction in the network
get-last-tx-hash:
    @response=$(curl -s -X GET "{{fullnode_url}}/v1a/transaction?count=1&type=tx"); \
    echo "$response" | jq -r '.transactions[0].hash'

# Get the entire last tx
get-last-tx:
    @response=$(curl -s -X GET "{{fullnode_url}}/v1a/transaction?count=1&type=tx"); \
    echo "$response" | jq

# Get transaction by ID
get-tx-by-id tx_id:
    @echo "{{GREEN + UNDERLINE}}Getting transaction by ID: {{tx_id}}{{NORMAL}}"
    @response=$(curl -s -X GET "{{fullnode_url}}/v1a/transaction?id={{tx_id}}"); \
    echo "$response" | jq

# Send transaction
send-tx address value token_uid="" wallet_id=wallet_id:
    @echo "{{GREEN + UNDERLINE}}Sending transaction...{{NORMAL}}"
    @echo "{{YELLOW}}To: {{address}}{{NORMAL}}"
    @echo "{{YELLOW}}Value: {{value}}{{NORMAL}}"
    @if [ -n "{{token_uid}}" ]; then \
        echo "{{YELLOW}}Token: {{token_uid}}{{NORMAL}}"; \
        curl -s -X POST -H "X-Wallet-Id: {{wallet_id}}" \
            -H "Content-Type: application/json" \
            -d "{\"address\":\"{{address}}\",\"value\":{{value}},\"token\":\"{{token_uid}}\"}" \
            {{wallet_url}}/wallet/simple-send-tx | jq; \
    else \
        echo "{{YELLOW}}Token: HTR (default){{NORMAL}}"; \
        curl -s -X POST -H "X-Wallet-Id: {{wallet_id}}" \
            -H "Content-Type: application/json" \
            -d "{\"address\":\"{{address}}\",\"value\":{{value}}}" \
            {{wallet_url}}/wallet/simple-send-tx | jq; \
    fi

# Start all services
up:
    @echo "{{GREEN + UNDERLINE}}Starting all services...{{NORMAL}}"
    @docker compose up -d

# Delete all services
down:
    @echo "{{GREEN + UNDERLINE}}Deleting all services...{{NORMAL}}"
    @docker compose down

# Stop all services
start target="":
    @echo "{{GREEN + UNDERLINE}}Starting {{if target == "" {"all services..."} else {target + " service..."} }}{{NORMAL}}"
    @docker compose start {{if target == "" {""} else {target} }}

# Stop all services
stop target="":
    @echo "{{GREEN + UNDERLINE}}Stopping {{if target == "" {"all services..."} else {target + " service..."} }}{{NORMAL}}"
    @docker compose stop {{if target == "" {""} else {target} }}

# Show wallet logs
logs target="":
    @echo "{{GREEN + UNDERLINE}}Showing {{if target == "" {"all services"} else {target + " service"} }} logs...{{NORMAL}}"
    @docker compose logs {{if target == "" {""} else {target} }} -f --tail 10

# Show service status
status:
    @echo "{{GREEN + UNDERLINE}}Service status:{{NORMAL}}"
    @docker compose ps

# Deploy all nano contracts from nano_contracts folder
deploy-blueprints wallet_id=wallet_id:
    @echo "{{GREEN + UNDERLINE}}Deploying nano contracts...{{NORMAL}}"
    @echo "# Nano Contract Deployments - $(date)" > deployments.txt
    @jq . deployments.json &> /dev/null || echo "{\"date\":\"$(date)\", \"contracts\":{}}" > deployments.json
    @for file in nano_contracts/*.py; do \
        if [ -f "$file" ]; then \
            name=$(basename "$file" .py); \
            echo "{{YELLOW}}Deploying $name...{{NORMAL}}"; \
            CODE=$(cat "$file" | jq -Rs .); \
            response=$(curl -s -X POST \
                -H "X-Wallet-Id: {{wallet_id}}" \
                -H "Content-Type: application/json" \
                -d "{\"address\":\"WhpJeUtBLrDHbKDoMC9ffMxwHqvsrNzTFV\",\"code\":$CODE}" \
                {{wallet_url}}/wallet/nano-contracts/create-on-chain-blueprint); \
            hash=$(echo "$response" | jq -r '.hash // empty'); \
            if [ -n "$hash" ] && [ "$hash" != "null" ]; then \
                echo "$name: $hash"; \
                echo "$name: $hash" >> deployments.txt; \
                jq ".blueprints[\"$name\"] = \"$hash\"" deployments.json > temp.tmp && mv temp.tmp deployments.json; \
            else \
                echo "{{RED}}$name: FAILED{{NORMAL}}"; \
                echo "$name: FAILED" >> deployments.txt; \
                echo "$response" | jq; \
            fi; \
        fi; \
    done
    @echo "{{GREEN}}Deployment results saved to deployments.txt{{NORMAL}}"

create-bet:
    #!/usr/bin/env bash
    WALLET_ID={{wallet_id}}
    BLUEPRINT=$(jq -r .blueprints.bet deployments.json)
    ADDRESS=$(curl -H "X-wallet-id: $WALLET_ID" "{{wallet_url}}/wallet/address?index=0" | jq -r .address)
    ORACLE_DATA=$(curl -H "X-wallet-id: $WALLET_ID" "{{wallet_url}}/wallet/nano-contracts/oracle-data?oracle=$ADDRESS" | jq -r .oracleData)
    BODY=$(echo "{}" | jq -c ".blueprint_id = \"$BLUEPRINT\" | .address = \"$ADDRESS\" | .data.args = [\"$ORACLE_DATA\", \"00\", $(date -d "+1 month" +%s)]")
    echo $BODY
    RESPONSE=$(curl -s -X POST -H "X-Wallet-Id: $WALLET_ID" -H "Content-Type: application/json" -d "$BODY" {{wallet_url}}/wallet/nano-contracts/create)
    echo "$RESPONSE"
    CONTRACT=$(echo $RESPONSE | jq -r .hash)
    echo $CONTRACT
    jq ".contracts.bet = \"$CONTRACT\"" deployments.json > temp.tmp && mv temp.tmp deployments.json

bet result="1x0" amount="100":
    #!/usr/bin/env bash
    WALLET_ID={{wallet_id}}
    RESULT={{result}}
    AMOUNT={{amount}}
    CONTRACT=$(jq -r .contracts.bet deployments.json)
    ADDRESS=$(curl -H "X-wallet-id: $WALLET_ID" "{{wallet_url}}/wallet/address?index=0" | jq -r .address)
    BODY=$(echo '{"method": "bet", "data": {"actions": [{"type":"deposit","token":"00"}]}}' | jq -c ".nc_id = \"$CONTRACT\" | .address = \"$ADDRESS\" | .data.actions[0].amount = $AMOUNT | .data.args = [\"$ADDRESS\", \"$RESULT\"]")
    curl -s -X POST -H "X-Wallet-Id: $WALLET_ID" -H "Content-Type: application/json" -d "$BODY" {{wallet_url}}/wallet/nano-contracts/execute | jq -r .hash


bet-set-result result="1x0":
    #!/usr/bin/env bash
    WALLET_ID={{wallet_id}}
    RESULT={{result}}
    CONTRACT=$(jq -r .contracts.bet deployments.json)
    ADDRESS=$(curl -H "X-wallet-id: $WALLET_ID" "{{wallet_url}}/wallet/address?index=0" | jq -r .address)

    ORACLE_DATA=$(curl -H "X-wallet-id: $WALLET_ID" "{{wallet_url}}/wallet/nano-contracts/oracle-data?oracle=$ADDRESS" | jq -r .oracleData)
    SIGNED_RESULT=$(curl -H "X-wallet-id: $WALLET_ID" "{{wallet_url}}/wallet/nano-contracts/oracle-signed-result?oracle_data=$ORACLE_DATA&contract_id=$CONTRACT&result=$RESULT&type=str" | jq -c .signedResult)

    BODY=$(echo '{"method": "set_result"}' | jq -c ".nc_id = \"$CONTRACT\" | .address = \"$ADDRESS\" | .data.args = [$SIGNED_RESULT]")
    curl -s -X POST -H "X-Wallet-Id: $WALLET_ID" -H "Content-Type: application/json" -d "$BODY" {{wallet_url}}/wallet/nano-contracts/execute | jq -r .hash


# TODO: make complex operations with templates later
# templatebet:
#     #!/usr/bin/env bash
#     TEMPLATE=$(jq -rc ".[1].value = $(jq .blueprints.bet deployments.json) | .[0].value = \"$(date -d "+1 month" +%s)\"" templates/initialize_bet.json)
#     curl -s -X POST -H "X-Wallet-Id: {{wallet_id}}" -H "Content-Type: application/json" -d "$TEMPLATE" {{wallet_url}}/wallet/tx-template/run

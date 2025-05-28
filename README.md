# Hathor Nano Contracts Development Environment

A complete development environment for building, testing, and deploying Hathor nano contracts using Docker and Make commands.

## Architecture

This project provides a full Hathor blockchain development stack with:

- **Hathor Full Node** - Local blockchain node for development
- **Transaction Mining Service** - Handles transaction mining
- **Wallet Headless** - API-based wallet for transactions
- **Traefik Reverse Proxy** - Routes traffic to services
- **CPU Miner** - Mines blocks for the local network

## Quick Start

1. **Start the development environment:**
   ```bash
   make up
   ```

2. **Start your wallet:**
   ```bash
   make start-wallet
   ```

3. **Deploy nano contracts:**
   ```bash
   make deploy-blueprints
   ```

## Available Commands

Run `make help` to see all available commands with descriptions.

### Docker Management

| Command | Description |
|---------|-------------|
| `make up` | Start all services |
| `make down` | Stop all services |
| `make logs` | Show all services logs |
| `make status` | Show service status |

### Wallet Operations

| Command | Description | Example |
|---------|-------------|---------|
| `make start-wallet` | Start wallet with default seed | `make start-wallet` |
| `make get-addresses` | Get wallet addresses | `make get-addresses` |
| `make get-balance` | Get wallet balance | `make get-balance` |
| `make send-tx <address> <value> [token]` | Send transaction | `make send-tx WjhZorHgJ73PGmCndvrciMvPUkzyrRNEZ4 1000` |

**Wallet ID Configuration:**
All wallet commands use the `WALLET_ID` parameter (default: `test-wallet`). Override with:
```bash
make get-balance WALLET_ID=456
```

### Blockchain Queries

| Command | Description | Example |
|---------|-------------|---------|
| `make get-last-tx-hash` | Get hash of last transaction | `make get-last-tx-hash` |
| `make get-last-tx` | Get complete last transaction | `make get-last-tx` |
| `make get-tx-by-id <hash>` | Get transaction by ID | `make get-tx-by-id 0000012dfb...` |

### Nano Contract Deployment

| Command | Description |
|---------|-------------|
| `make deploy-blueprints` | Deploy all contracts from `nano_contracts/` folder |

This command:
- Automatically finds all `.py` files in `nano_contracts/`
- Deploys each contract to the blockchain
- Saves deployment results to `deployments.txt`
- Shows contract name and hash for each deployment

## Service URLs

The environment supports both `.localhost` (no setup required) and `.hathor.local` (requires `/etc/hosts`) domains:

### Direct Access
- **Traefik Dashboard:** http://localhost:1339
- **Fullnode:** http://fullnode.localhost:1337 or http://fullnode.hathor.local:1337
- **Mining Service:** http://mining.localhost:1337 or http://mining.hathor.local:1337
- **Wallet:** http://wallet.localhost:1337 or http://wallet.hathor.local:1337

## Project Structure

```
nano-headers-env/
├── docker-compose.yml          # Docker services configuration
├── Makefile                    # Development commands
├── deployments.txt            # Contract deployment results
├── nano_contracts/            # Nano contract blueprints
│   ├── authority.py          # Authority management contract
│   └── token_manager.py      # Token management contract
└── README.md                 # This file
```

## Nano Contracts

### Creating New Contracts

1. Add your `.py` file to the `nano_contracts/` folder
2. Follow the blueprint pattern (see existing contracts)
3. Run `make deploy-blueprints` to deploy all contracts

## Configuration

### Wallet Configuration
- **Default Wallet ID:** `test-wallet`
- **Seed Phrase:** Pre-configured for development
- **Network:** `testnet` (nano-testnet-alpha)

### Network Configuration
- **Blockchain:** Private Hathor testnet
- **Mining:** Automatic CPU mining enabled
- **Consensus:** Test mode with reduced difficulty

## Development Workflow

1. **Start Environment:**
   ```bash
   make up
   make start-wallet
   ```

2. **Check Wallet Status:**
   ```bash
   make get-addresses
   make get-balance
   ```

3. **Develop Contracts:**
   - Create new `.py` files in `nano_contracts/`
   - Follow existing blueprint patterns

4. **Deploy Contracts:**
   ```bash
   make deploy-blueprints
   ```

5. **Test Transactions:**
   ```bash
   make send-tx <address> <amount>
   make get-last-tx-hash
   ```

## Troubleshooting

### Services Not Starting
```bash
make status
make logs
```

### Wallet Issues
```bash
# Check if wallet is started
make get-addresses

# Restart wallet
make start-wallet
```

### Network Issues
- Ensure Docker is running
- Check if ports 1337-1339 are available
- Verify `/etc/hosts` entries for `.hathor.local` domains

### Contract Deployment Issues
- Check `deployments.txt` for error details
- Verify contract syntax in `nano_contracts/` files
- Ensure wallet has sufficient balance

## API Documentation

### Wallet API
Base URL: `http://wallet.localhost:1337`

- `POST /start` - Start wallet
- `GET /wallet/address/` - Get addresses
- `GET /wallet/balance` - Get balance
- `POST /wallet/simple-send-tx` - Send transaction
- `POST /wallet/nano-contracts/create-on-chain-blueprint` - Deploy contract

### Full Node API
Base URL: `http://fullnode.localhost:1337/v1a`

- `GET /transaction?count=1` - Get recent transactions
- `GET /transaction?id=<hash>` - Get transaction by ID
- `GET /status` - Node status

## Contributing

1. Add new nano contracts to `nano_contracts/`
2. Update this README for new features
3. Test with `make deploy-blueprints`
4. Ensure all commands work as expected

## License

This project uses the Apache License 2.0 for nano contracts and follows Hathor Labs licensing. 
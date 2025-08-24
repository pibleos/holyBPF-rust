# Synthetic Assets Protocol Example

This example demonstrates a professional synthetic assets protocol implementation in HolyC for Solana BPF, enabling the creation and management of synthetic assets that track real-world values.

## Features

- **Asset Creation**: Create synthetic assets pegged to real-world assets (stocks, commodities, currencies)
- **Collateral Management**: Over-collateralized vault system for secure asset backing
- **Price Oracle Integration**: Real-time price feeds for accurate asset valuation
- **Liquidation System**: Automated liquidation of undercollateralized positions
- **Stability Fees**: Dynamic borrowing costs to maintain system stability
- **Global Settlement**: Emergency shutdown mechanism for crisis scenarios
- **Multi-Asset Support**: Support for up to 100 different synthetic assets
- **Risk Management**: Comprehensive risk controls and safety mechanisms

## Synthetic Assets

### Supported Asset Types
The protocol can create synthetic versions of:
- **Stocks**: sSPY, sAAPL, sTSLA (synthetic stock tokens)
- **Commodities**: sGOLD, sSILVER, sOIL (synthetic commodity tokens)  
- **Currencies**: sEUR, sJPY, sGBP (synthetic currency tokens)
- **Indices**: sS&P500, sNASDAQ (synthetic index tokens)
- **Crypto**: sBTC, sETH (synthetic cryptocurrency tokens)

### Key Benefits
- **Global Access**: Trade any asset without geographic restrictions
- **24/7 Trading**: No market hours limitations
- **Fractional Ownership**: Access expensive assets with small amounts
- **No Counterparty Risk**: Decentralized and trustless system
- **Instant Settlement**: Immediate trading and transfers

## Instructions

1. **Initialize Protocol** - Set up the synthetic assets protocol with admin controls
2. **Create Synthetic Asset** - Add a new synthetic asset with oracle and parameters
3. **Open Vault** - Create a collateral vault for minting synthetic assets
4. **Deposit Collateral** - Add collateral tokens to secure synthetic asset minting
5. **Mint Synthetic** - Create synthetic asset tokens against deposited collateral
6. **Burn Synthetic** - Destroy synthetic tokens to reduce debt
7. **Withdraw Collateral** - Remove excess collateral from vault
8. **Liquidate Vault** - Liquidate undercollateralized positions
9. **Update Price** - Update asset prices from oracle feeds
10. **Global Settlement** - Emergency shutdown of the protocol

## Collateralization System

### Vault Management
```
Collateral Ratio = (Collateral Value / Debt Value) × 100%

Example:
- Deposit: $1,500 worth of SOL
- Mint: $1,000 worth of sBTC
- Collateral Ratio: 150%
```

### Safety Thresholds
- **Minimum Collateral Ratio**: 150% (protocol default)
- **Liquidation Threshold**: 130% (triggers liquidation)
- **Liquidation Penalty**: 13% (paid to liquidators)
- **Stability Fee**: 5% annual (borrowing cost)

### Liquidation Process
1. Monitor vault collateralization ratios
2. Identify vaults below 130% threshold
3. Allow liquidators to repay debt and claim collateral
4. Apply 13% penalty to protect protocol
5. Distribute penalty to liquidation fund

## Risk Management

### Price Oracle Protection
- Multiple oracle sources for price feeds
- Maximum price deviation limits
- Time-weighted average pricing (TWAP)
- Emergency pause mechanisms

### System Safeguards
- Per-asset debt ceilings
- Global collateralization monitoring
- Emergency global settlement
- Admin controls for parameter updates

### Liquidation Incentives
- Competitive liquidation market
- Penalty rewards for liquidators
- Efficient price discovery
- Fast resolution of bad debt

## Building and Testing

Build the synthetic assets program:
```bash
cargo build --release
```

Run the test suite:
```bash
cargo test
```

Compile the HolyC example:
```bash
./target/release/pible examples/synthetic-assets/src/main.hc
```

## Example Usage

### Creating a Synthetic Stock (sSPY)
```bash
# Initialize protocol
echo "00" | xxd -r -p > init.bin
cat admin_key.bin >> init.bin

# Create sSPY synthetic asset
echo "01" | xxd -r -p > create_asset.bin
cat spy_asset_id.bin >> create_asset.bin
cat spy_mint.bin >> create_asset.bin
cat sol_mint.bin >> create_asset.bin  # SOL as collateral
printf "%016x" 1500 | xxd -r -p >> create_asset.bin  # 150% collateral ratio
printf "%016x" 1300 | xxd -r -p >> create_asset.bin  # 130% liquidation ratio
printf "%016x" 42000000000 | xxd -r -p >> create_asset.bin  # $420.00 target price
printf "%016x" 100000000000000 | xxd -r -p >> create_asset.bin  # $1M debt ceiling
cat price_oracle.bin >> create_asset.bin

# Open vault for sSPY
echo "02" | xxd -r -p > open_vault.bin
cat vault_id.bin >> open_vault.bin
cat spy_asset_id.bin >> open_vault.bin
cat user_key.bin >> open_vault.bin

# Deposit SOL collateral
echo "03" | xxd -r -p > deposit.bin
cat vault_id.bin >> deposit.bin
printf "%016x" 5000000000 | xxd -r -p >> deposit.bin  # 5 SOL

# Mint sSPY tokens
echo "04" | xxd -r -p > mint.bin
cat vault_id.bin >> mint.bin
printf "%016x" 1000000000 | xxd -r -p >> mint.bin  # 10 sSPY tokens
```

### Liquidating Undercollateralized Vault
```bash
# Liquidate vault
echo "07" | xxd -r -p > liquidate.bin
cat vault_id.bin >> liquidate.bin
cat liquidator_key.bin >> liquidate.bin
```

## Security Considerations

### Vault Security
- Always maintain collateral ratio above 150%
- Monitor price movements for your collateral
- Set up alerts for liquidation risk
- Consider partial debt repayment during volatility

### Oracle Risk
- Understand oracle update frequency
- Monitor for oracle failures or attacks
- Be aware of price deviation limits
- Plan for emergency scenarios

### Smart Contract Risk
- Protocol is in development phase
- Use only with funds you can afford to lose
- Understand liquidation mechanics
- Keep emergency exit strategies

## Advanced Features

### Price Oracles
- Chainlink price feeds integration
- Pyth Network oracle support
- Custom oracle implementations
- TWAP (Time-Weighted Average Price) calculations

### Governance
- Parameter updates through governance
- New asset additions via voting
- Emergency actions by admin
- Community-driven protocol evolution

### Cross-Program Integration
- DEX integration for liquidations
- Lending protocol compatibility
- Yield farming opportunities
- Arbitrage mechanisms

This implementation demonstrates a production-ready synthetic assets protocol with comprehensive risk management, oracle integration, and liquidation systems suitable for real-world DeFi applications.
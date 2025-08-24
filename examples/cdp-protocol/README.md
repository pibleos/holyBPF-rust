# CDP Protocol Example

This example demonstrates a comprehensive Collateralized Debt Position (CDP) protocol implementation in HolyC for Solana BPF, based on the MakerDAO model with Solana-specific optimizations.

## Features

- **Multiple Collateral Types**: Support for up to 50 different collateral token types
- **Overcollateralized Lending**: Secure debt issuance against locked collateral
- **Liquidation Auctions**: Dutch auction system for liquidating unsafe positions
- **Stability Fees**: Compound interest on outstanding debt positions
- **Oracle Integration**: Real-time price feeds for accurate collateral valuation
- **Emergency Shutdown**: Global settlement mechanism for crisis scenarios
- **Fee Collection**: Accumulated fees support protocol sustainability
- **Debt Ceilings**: Risk controls limiting maximum debt per collateral type

## CDP Operations

### Core Functions
1. **Open CDP** - Create new collateralized debt position
2. **Deposit Collateral** - Add collateral tokens to increase position safety
3. **Generate Debt** - Mint stablecoin against collateral (subject to collateral ratio)
4. **Repay Debt** - Burn stablecoin to reduce debt and fees
5. **Withdraw Collateral** - Remove excess collateral (maintaining safety ratio)
6. **Liquidate CDP** - Liquidate undercollateralized positions through auctions

### Safety Mechanisms
- **Liquidation Ratio**: Minimum collateral/debt ratio (typically 150%)
- **Liquidation Penalty**: Fee for liquidated positions (typically 13%)
- **Debt Floor**: Minimum debt amount to prevent dust positions
- **Debt Ceiling**: Maximum debt allowed per collateral type

## Instructions

1. **Initialize Protocol** - Set up CDP system with global parameters
2. **Add Collateral Type** - Register new collateral token with risk parameters
3. **Open CDP** - Create new collateralized debt position
4. **Deposit Collateral** - Add collateral tokens to CDP
5. **Generate Debt** - Mint stablecoin against collateral
6. **Repay Debt** - Pay down debt and accumulated fees
7. **Withdraw Collateral** - Remove excess collateral from CDP
8. **Liquidate CDP** - Start liquidation auction for unsafe CDP
9. **Bid on Auction** - Participate in liquidation auctions
10. **Settle Auction** - Complete liquidation auction
11. **Update Prices** - Update oracle price feeds
12. **Drip Fees** - Accumulate stability fees system-wide

## Collateralization Example

```
CDP Example:
- Collateral: 10 SOL @ $100/SOL = $1,000 value
- Debt Generated: 600 stablecoin @ $1 = $600 value
- Collateral Ratio: $1,000 / $600 = 166.7%
- Status: SAFE (above 150% liquidation threshold)

Liquidation Scenario:
- SOL Price Drops to $80/SOL
- Collateral Value: 10 SOL @ $80 = $800
- Debt Value: 600 stablecoin = $600  
- Collateral Ratio: $800 / $600 = 133.3%
- Status: UNSAFE (below 150% threshold) → Liquidation triggered
```

## Liquidation Auction System

### Dutch Auction Mechanism
```
Starting Price: Current collateral market price
Price Reduction: 1% per time step
Duration: 1 hour maximum
Bidding: Highest bidder wins at auction end

Example Auction:
1. 10 SOL collateral, $800 starting value
2. Price reduces: $800 → $792 → $784 → ...
3. Bidder offers $760 for 10 SOL
4. Debt covered: $600, Liquidator profit: $160, Penalty: $78
```

### Liquidation Economics
- **Debt Coverage**: Full debt amount must be covered
- **Liquidation Penalty**: Additional fee (13% typical)
- **Liquidator Incentive**: Discount on collateral purchase
- **Remaining Collateral**: Returned to CDP owner if any

## Building and Testing

Build the CDP protocol:
```bash
cargo build --release
```

Run the test suite:
```bash
cargo test
```

Compile the HolyC example:
```bash
./target/release/pible examples/cdp-protocol/src/main.hc
```

## Example Usage

### Setting Up Collateral Type
```bash
# Initialize protocol
echo "00" | xxd -r -p > init.bin
cat admin_key.bin >> init.bin
cat fee_collector.bin >> init.bin
printf "%016x" 1000000000 | xxd -r -p >> init.bin  # $1B global debt ceiling
printf "%016x" 100 | xxd -r -p >> init.bin         # 1% base rate

# Add SOL as collateral type
echo "01" | xxd -r -p > add_collateral.bin
cat sol_mint.bin >> add_collateral.bin
cat chainlink_oracle.bin >> add_collateral.bin
printf "%016x" 15000 | xxd -r -p >> add_collateral.bin  # 150% liquidation ratio
printf "%016x" 1300 | xxd -r -p >> add_collateral.bin   # 13% liquidation penalty
printf "%016x" 500 | xxd -r -p >> add_collateral.bin    # 5% stability fee
printf "%016x" 10000000 | xxd -r -p >> add_collateral.bin # $10M debt ceiling
printf "%016x" 1000 | xxd -r -p >> add_collateral.bin   # $1K debt floor
```

### Opening and Managing CDP
```bash
# Open new CDP
echo "02" | xxd -r -p > open_cdp.bin
cat cdp_id.bin >> open_cdp.bin
cat user_key.bin >> open_cdp.bin
cat sol_mint.bin >> open_cdp.bin

# Deposit 10 SOL as collateral
echo "03" | xxd -r -p > deposit.bin
cat cdp_id.bin >> deposit.bin
printf "%016x" 10000000000 | xxd -r -p >> deposit.bin  # 10 SOL (9 decimals)

# Generate 600 stablecoin debt
echo "04" | xxd -r -p > generate.bin
cat cdp_id.bin >> generate.bin
printf "%016x" 600000000 | xxd -r -p >> generate.bin   # 600 stablecoin (6 decimals)

# Repay 100 stablecoin
echo "05" | xxd -r -p > repay.bin
cat cdp_id.bin >> repay.bin
printf "%016x" 100000000 | xxd -r -p >> repay.bin      # 100 stablecoin

# Withdraw 1 SOL collateral
echo "06" | xxd -r -p > withdraw.bin
cat cdp_id.bin >> withdraw.bin
printf "%016x" 1000000000 | xxd -r -p >> withdraw.bin  # 1 SOL
```

### Liquidation Process
```bash
# Liquidate unsafe CDP
echo "07" | xxd -r -p > liquidate.bin
cat cdp_id.bin >> liquidate.bin
cat liquidator_key.bin >> liquidate.bin

# Bid on liquidation auction
echo "08" | xxd -r -p > bid.bin
cat auction_id.bin >> bid.bin
cat bidder_key.bin >> bid.bin
printf "%016x" 750000000 | xxd -r -p >> bid.bin        # $750 bid

# Settle completed auction
echo "09" | xxd -r -p > settle.bin
cat auction_id.bin >> settle.bin
```

## Risk Management

### For CDP Owners
- **Monitor Collateral Ratio**: Keep well above liquidation threshold
- **Price Volatility**: Understand collateral price risks
- **Stability Fees**: Account for compound interest on debt
- **Emergency Plans**: Prepare for market downturns

### For Liquidators
- **Monitor Unsafe CDPs**: Track positions near liquidation
- **Auction Participation**: Bid efficiently in liquidation auctions
- **Capital Requirements**: Maintain funds for liquidation opportunities
- **Profit Calculation**: Account for gas costs and slippage

### For Protocol
- **Oracle Reliability**: Ensure accurate and timely price feeds
- **Parameter Tuning**: Adjust liquidation ratios based on volatility
- **Debt Ceiling Management**: Control exposure per collateral type
- **Emergency Procedures**: Prepare for black swan events

## Economic Model

### Stability Fee Structure
```
Total Interest Rate = Base Rate + Collateral-Specific Rate
Example: 1% base + 4% SOL rate = 5% annual

Compound Interest Formula:
New Debt = Principal × (1 + rate/periods)^(periods × time)
```

### Liquidation Economics
- **Liquidation Penalty**: Protects protocol from bad debt
- **Auction Discount**: Incentivizes liquidator participation
- **Surplus Fund**: Accumulated fees support protocol operations
- **Deficit Handling**: Mechanisms for covering protocol losses

## Advanced Features

### Multi-Collateral Support
- Different risk parameters per collateral type
- Independent debt ceilings and floors
- Collateral-specific stability fees
- Oracle-specific integrations

### Governance Integration
- Parameter updates through governance votes
- New collateral type additions
- Risk parameter adjustments
- Emergency actions coordination

### Oracle System
- Chainlink price feed integration
- Pyth Network support
- Time-weighted average pricing
- Price freshness validation
- Emergency price halts

This implementation demonstrates a production-ready CDP system with comprehensive risk management, liquidation mechanisms, and economic incentives suitable for real-world DeFi applications.
# Perpetual DEX - HolyC Implementation

A sophisticated perpetual futures trading platform built in HolyC for Solana, featuring oracle integration, liquidation mechanisms, and cross-margin trading.

## Features

- **Perpetual Futures**: Trade BTC, ETH, and SOL perpetual contracts with up to 10x leverage
- **Oracle Integration**: Real-time price feeds from Pyth Network and Switchboard
- **Liquidation Engine**: Automated position liquidation to maintain system solvency
- **Cross-Margin Trading**: Efficient capital utilization across multiple positions
- **Funding Rate Mechanism**: Dynamic funding rates to maintain perpetual contract balance

## Program Structure

```
src/
├── main.hc              # Main program entry point
├── perpetual.hc         # Core perpetual contract logic
├── oracle.hc            # Price oracle integration
├── liquidation.hc       # Liquidation engine
├── margin.hc            # Margin calculation and management
└── funding.hc           # Funding rate calculations
```

## Building

```bash
# Build the compiler
cargo build --release

# Compile the perpetual DEX program
./target/release/pible examples/perpetual-dex/src/main.hc
```

## Key Operations

1. **Open Position**: Open long or short positions with specified leverage
2. **Close Position**: Close positions at market price
3. **Add Margin**: Increase position margin to avoid liquidation
4. **Liquidate**: Liquidate undercollateralized positions
5. **Collect Funding**: Collect or pay funding based on position direction

## HolyC Implementation Highlights

```c
// Perpetual position structure
struct PerpetualPosition {
    U8[32] trader;           // Trader public key
    U8[32] market;           // Market identifier
    I64 size;                // Position size (positive for long, negative for short)
    U64 entry_price;         // Entry price in oracle format
    U64 margin;              // Position margin
    U64 last_funding_time;   // Last funding payment time
    Bool is_long;            // Position direction
};

// Open new perpetual position
U0 open_position(U8* trader, U8* market, I64 size, U64 leverage) {
    PerpetualPosition position;
    U64 oracle_price = get_oracle_price(market);
    U64 required_margin = calculate_margin(size, oracle_price, leverage);
    
    // Validate margin requirements
    if (!validate_margin(trader, required_margin)) {
        PrintF("ERROR: Insufficient margin\n");
        return;
    }
    
    // Initialize position
    position.trader = trader;
    position.market = market;
    position.size = size;
    position.entry_price = oracle_price;
    position.margin = required_margin;
    position.last_funding_time = get_current_time();
    position.is_long = size > 0;
    
    // Store position and emit event
    store_position(&position);
    emit_position_opened(&position);
    
    PrintF("Position opened: size=%ld, price=%lu, margin=%lu\n", 
           size, oracle_price, required_margin);
}
```

## Risk Management

- **Maximum Leverage**: 10x leverage cap to limit system risk
- **Liquidation Threshold**: 80% margin ratio for position liquidation
- **Oracle Safeguards**: Multiple oracle validation with deviation checks
- **Position Limits**: Per-user and global position size limits

## Testing

```bash
# Run basic functionality tests
./target/release/pible --target bpf-vm --enable-vm-testing examples/perpetual-dex/src/main.hc

# Test liquidation scenarios
./target/release/pible examples/perpetual-dex/src/liquidation.hc
```

## Divine Trading Wisdom

> "The divine intellect sees all market movements" - Terry A. Davis

This perpetual DEX implementation brings God's clarity to derivatives trading through HolyC's divine syntax and BPF's kernel-level execution.
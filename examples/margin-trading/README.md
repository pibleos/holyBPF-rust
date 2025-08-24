# Margin Trading Protocol Example

This example demonstrates a comprehensive margin trading protocol implementation in HolyC for Solana BPF, enabling leveraged trading with sophisticated risk management.

## Features

- **Leveraged Trading**: Support for 2x to 100x leverage ratios
- **Long/Short Positions**: Both bullish and bearish position types
- **Risk Management**: Real-time liquidation monitoring and execution
- **Margin Requirements**: Dynamic margin calculation and maintenance
- **Funding Rates**: Periodic funding payments between long/short positions
- **Cross/Isolated Margin**: Flexible margin allocation strategies

## Position Management

### Opening Positions
```
Example: 5x Long BTC Position
- Collateral: $10,000 USDC
- Leverage: 5x
- Position Size: $50,000 BTC
- Entry Price: $45,000
- Liquidation Price: $36,000 (20% drop)
```

### Risk Calculations
```
Maintenance Margin = Position Size × Maintenance Rate
Liquidation Price = Entry Price × (1 - Initial Margin / Leverage)
PnL = (Current Price - Entry Price) × Position Size / Entry Price
```

## Building and Testing

```bash
cargo build --release
./target/release/pible examples/margin-trading/src/main.hc
```

## Key Features

- **Real-time P&L**: Continuous profit/loss calculation
- **Auto-liquidation**: Automated position closure at liquidation thresholds
- **Risk Monitoring**: Continuous margin level monitoring
- **Position Sizing**: Intelligent position size calculation

This implementation provides the foundation for a sophisticated margin trading system with comprehensive risk management and position monitoring capabilities.
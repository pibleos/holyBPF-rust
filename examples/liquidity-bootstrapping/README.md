# Liquidity Bootstrapping Pool Example

Comprehensive liquidity bootstrapping pool implementation for fair token distribution with dynamic pricing and anti-whale mechanisms.

## Features

- **Dynamic Pricing**: Token prices decrease over time to discourage speculation
- **Fair Distribution**: Prevents large buyers from dominating token sales
- **Weight Rebalancing**: Gradual shift from project token to funding token weight
- **Price Discovery**: Market-driven price discovery through continuous trading
- **Anti-Whale Protection**: Time-based pricing discourages large early purchases

## LBP Mechanics

### Weight Schedule
```
Day 1: 90% Project Token / 10% USDC
Day 2: 50% Project Token / 50% USDC  
Day 3: 10% Project Token / 90% USDC
```

### Price Impact
- **Early buyers pay premium prices**
- **Later buyers get better deals**
- **Encourages patient, smaller purchases**
- **Natural price discovery mechanism**

## Building and Testing

```bash
cargo build --release
./target/release/pible examples/liquidity-bootstrapping/src/main.hc
```

This implementation enables fair token launches with built-in anti-speculation mechanisms and community-friendly pricing.
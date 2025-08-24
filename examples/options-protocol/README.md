# Options Protocol - HolyC Implementation

A European-style options trading platform built in HolyC for Solana, featuring automated market making, delta hedging, and sophisticated pricing models.

## Features

- **European Options**: Call and put options with standardized expiration times
- **Black-Scholes Pricing**: Sophisticated option pricing with implied volatility
- **Automated Market Making**: Dynamic bid-ask spreads based on Greeks
- **Delta Hedging**: Automated hedging strategies for market makers
- **Yield Generation**: Premium collection and time decay optimization

## Program Structure

```
src/
├── main.hc              # Main program entry point
├── options.hc           # Core options contract logic
├── pricing.hc           # Black-Scholes pricing implementation
├── greeks.hc            # Greeks calculation (delta, gamma, theta, vega)
├── amm.hc               # Automated market maker
└── hedging.hc           # Delta hedging strategies
```

## Building

```bash
# Build the compiler
cargo build --release

# Compile the options protocol
./target/release/pible examples/options-protocol/src/main.hc
```

## Key Operations

1. **Create Option**: Create new call or put option contracts
2. **Buy Option**: Purchase options at market price
3. **Exercise Option**: Exercise in-the-money options at expiration
4. **Provide Liquidity**: Add liquidity to the options AMM
5. **Hedge Delta**: Execute delta hedging trades

## HolyC Implementation Highlights

```c
// Option contract structure
struct OptionContract {
    U8[32] underlying;       // Underlying asset (SOL, BTC, ETH)
    U64 strike_price;        // Strike price in USDC
    U64 expiration;          // Expiration timestamp
    Bool is_call;            // True for call, false for put
    U64 premium;             // Current premium price
    U64 open_interest;       // Total open interest
    F64 implied_volatility;  // Current implied volatility
};

// Greeks structure for risk management
struct OptionGreeks {
    F64 delta;               // Price sensitivity
    F64 gamma;               // Delta sensitivity
    F64 theta;               // Time decay
    F64 vega;                // Volatility sensitivity
    F64 rho;                 // Interest rate sensitivity
};

// Black-Scholes option pricing
F64 black_scholes_call(F64 spot, F64 strike, F64 time_to_expiry, 
                       F64 risk_free_rate, F64 volatility) {
    F64 d1 = (log(spot / strike) + (risk_free_rate + 0.5 * volatility * volatility) * time_to_expiry) 
             / (volatility * sqrt(time_to_expiry));
    F64 d2 = d1 - volatility * sqrt(time_to_expiry);
    
    F64 call_price = spot * normal_cdf(d1) - strike * exp(-risk_free_rate * time_to_expiry) * normal_cdf(d2);
    
    return call_price;
}

// Calculate option delta for hedging
F64 calculate_delta(OptionContract* option, F64 spot_price) {
    F64 time_to_expiry = (option->expiration - get_current_time()) / 31536000.0; // Convert to years
    F64 d1 = (log(spot_price / option->strike_price) + 0.05 * time_to_expiry) 
             / (option->implied_volatility * sqrt(time_to_expiry));
    
    if (option->is_call) {
        return normal_cdf(d1);
    } else {
        return normal_cdf(d1) - 1.0;
    }
}
```

## Risk Management

- **Expiration Limits**: Maximum 90-day expiration to manage time risk
- **Strike Price Bands**: Options only available within ±20% of spot price
- **Position Limits**: Maximum position size per user and globally
- **Volatility Bounds**: Implied volatility capped between 10% and 300%

## Market Making Features

- **Dynamic Spreads**: Bid-ask spreads adjust based on volatility and liquidity
- **Greeks-Based Pricing**: Real-time pricing using calculated Greeks
- **Inventory Management**: Automatic rebalancing of option inventories
- **Cross-Asset Hedging**: Delta hedging across multiple underlying assets

## Testing

```bash
# Test option pricing models
./target/release/pible examples/options-protocol/src/pricing.hc

# Test Greeks calculations
./target/release/pible examples/options-protocol/src/greeks.hc

# Run full protocol simulation
./target/release/pible --target bpf-vm --enable-vm-testing examples/options-protocol/src/main.hc
```

## Divine Mathematics

> "God's mathematics are perfect, and so are His option prices" - Terry A. Davis

This options protocol harnesses the divine precision of mathematical finance through HolyC's blessed syntax, bringing sophisticated derivatives to the masses.
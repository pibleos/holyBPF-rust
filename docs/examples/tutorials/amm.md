---
layout: doc
title: AMM (Automated Market Maker) Tutorial
description: Build a professional constant product AMM with TWAP oracles
---

# AMM (Automated Market Maker) Tutorial

Learn how to build a professional automated market maker using the constant product formula (x × y = k). This tutorial covers advanced DeFi concepts including liquidity provision, swap mechanics, and TWAP price oracles.

## Overview

The AMM example demonstrates:
- **Constant Product Formula**: Uniswap V2-style mathematical model
- **Liquidity Provision**: Add/remove liquidity with LP tokens
- **Token Swapping**: Efficient token exchange mechanisms
- **TWAP Oracles**: Time-weighted average price calculation
- **Fee Collection**: Trading fees for liquidity providers
- **Price Impact Protection**: Slippage and impact controls

## Prerequisites

Before starting this tutorial, ensure you have:

- ✅ **Completed** [Hello World]({{ '/docs/examples/tutorials/hello-world' | relative_url }}) and [Escrow]({{ '/docs/examples/tutorials/escrow' | relative_url }}) tutorials
- ✅ **Understanding** of DeFi concepts (AMMs, liquidity pools)
- ✅ **Familiarity** with constant product formula
- ✅ **Knowledge** of token economics

### DeFi Concepts Review

**Automated Market Maker (AMM)**
- Algorithmic trading protocol without order books
- Uses mathematical formulas to price assets
- Provides continuous liquidity through liquidity pools

**Constant Product Formula**
```
x × y = k
```
- `x` and `y` are token reserves
- `k` is the constant product
- Price determined by ratio of reserves

## Architecture Overview

```
┌─────────────────────────────────────────┐
│            Divine AMM Pool              │
├─────────────────────────────────────────┤
│  💰 Token Reserves                       │
│    • Token A Reserve (x)                │
│    • Token B Reserve (y)                │
│    • Constant Product (k = x × y)       │
├─────────────────────────────────────────┤
│  🔄 Core Operations                      │
│    • Add Liquidity → Mint LP Tokens     │
│    • Remove Liquidity → Burn LP Tokens  │
│    • Swap Tokens → Update Reserves      │
├─────────────────────────────────────────┤
│  📊 Price Oracle (TWAP)                 │
│    • Time-weighted average prices       │
│    • Cumulative price tracking          │
│    • External price feeds               │
├─────────────────────────────────────────┤
│  💸 Fee System                          │
│    • Trading fees (0.3% default)        │
│    • LP rewards distribution            │
│    • Protocol fee collection            │
└─────────────────────────────────────────┘
```

## Code Walkthrough

### Core Data Structures

<div class="code-section">
  <div class="code-header">
    <span class="filename">📁 examples/amm/src/main.hc</span>
    <a href="https://github.com/pibleos/holyBPF-rust/blob/main/examples/amm/src/main.hc" class="github-link" target="_blank">View on GitHub</a>
  </div>
```c
// AMM Pool data structure
struct AmmPool {
    U8[32] token_a_mint;        // Token A mint address
    U8[32] token_b_mint;        // Token B mint address
    U64 token_a_reserve;        // Token A reserves in pool
    U64 token_b_reserve;        // Token B reserves in pool
    U64 total_lp_supply;        // Total LP token supply
    U64 fee_numerator;          // Fee rate numerator (30 for 0.3%)
    U64 fee_denominator;        // Fee rate denominator (10000)
    U8[32] lp_mint;            // LP token mint address
    U8[32] authority;          // Pool authority
    Bool is_initialized;        // Pool initialization status
    U64 last_update_time;      // Last price update timestamp
    U64 price_cumulative_0;    // Cumulative price for TWAP
    U64 price_cumulative_1;    // Cumulative price for TWAP (inverse)
};
```
</div>

#### Key Structure Components

**1. Token Information**
- **`token_a_mint`/`token_b_mint`**: Unique identifiers for trading pair
- **`token_a_reserve`/`token_b_reserve`**: Current token balances in pool
- **Reserves determine**: Current exchange rate and available liquidity

**2. Liquidity Provider (LP) System**
- **`total_lp_supply`**: Total LP tokens in circulation
- **`lp_mint`**: Address for minting/burning LP tokens
- **LP tokens represent**: Proportional ownership of pool reserves

**3. Fee Structure**
- **`fee_numerator`/`fee_denominator`**: Configurable trading fees
- **Default**: 30/10000 = 0.3% (industry standard)
- **Purpose**: Incentivize liquidity providers

**4. TWAP Oracle Data**
- **`price_cumulative_0`/`price_cumulative_1`**: Cumulative price tracking
- **`last_update_time`**: Timestamp for TWAP calculations
- **Purpose**: Manipulation-resistant price feeds

### Liquidity Provider Position

<div class="code-section">
  <div class="code-header">
    <span class="filename">📁 examples/amm/src/main.hc (continued)</span>
  </div>
```c
// Liquidity provider position
struct LpPosition {
    U8[32] pool_address;       // Associated pool
    U8[32] owner;              // Position owner
    U64 lp_tokens;             // LP tokens held
    U64 fees_earned_a;         // Accumulated fees in token A
    U64 fees_earned_b;         // Accumulated fees in token B
    U64 last_fee_collection;   // Last fee collection block
};
```
</div>

#### Position Tracking
- **Individual ownership**: Track each LP's pool share
- **Fee accumulation**: Automatic fee collection for LPs
- **Withdrawal calculation**: Determine token amounts on exit

### Constants and Configuration

<div class="code-section">
  <div class="code-header">
    <span class="filename">📁 examples/amm/src/main.hc (continued)</span>
  </div>
```c
// Global constants
static const U64 MINIMUM_LIQUIDITY = 1000;
static const U64 PRICE_PRECISION = 1000000000; // 1e9 for precise calculations
static const U64 MAX_PRICE_IMPACT = 1000; // 10% maximum price impact per transaction
```
</div>

#### Configuration Explained
- **`MINIMUM_LIQUIDITY`**: Prevents division by zero, ensures pool viability
- **`PRICE_PRECISION`**: High precision for accurate price calculations
- **`MAX_PRICE_IMPACT`**: Protects against excessive slippage

## Mathematical Foundation

### Constant Product Formula

The AMM uses the constant product formula:

```
x × y = k
```

Where:
- `x` = Token A reserves
- `y` = Token B reserves  
- `k` = Constant product (invariant)

### Price Calculation

Current price of Token A in terms of Token B:
```
Price_A = y / x
Price_B = x / y
```

### Swap Amount Calculation

For a swap of `Δx` Token A to get `Δy` Token B:

```
(x + Δx) × (y - Δy) = k
```

Solving for `Δy`:
```
Δy = (y × Δx) / (x + Δx)
```

With fees:
```
Δy = (y × Δx × (1 - fee)) / (x + Δx)
```

### Liquidity Addition

When adding liquidity proportionally:
```
LP_tokens_minted = min(
    (Δx / x) × total_LP_supply,
    (Δy / y) × total_LP_supply
)
```

## Building the AMM

### Step 1: Compile the AMM Program
```bash
cd holyBPF-rust
./target/release/pible examples/amm/src/main.hc
```

### Expected Compilation Output
```
=== Pible - HolyC to BPF Compiler ===
Divine compilation initiated...
Source: examples/amm/src/main.hc
Target: LinuxBpf
Compiled successfully: examples/amm/src/main.hc -> examples/amm/src/main.bpf
Divine compilation completed! 🙏
```

### Step 2: Verify Output
```bash
ls -la examples/amm/src/
```

Should show:
- ✅ `main.hc` - Source AMM implementation
- ✅ `main.bpf` - Compiled BPF bytecode

### Step 3: Test Execution
```bash
# Check the compiled AMM program
file examples/amm/src/main.bpf
hexdump -C examples/amm/src/main.bpf | head -5
```

## AMM Operations Deep Dive

### 1. Pool Initialization

```c
// Pseudo-code for pool initialization
U0 initialize_pool(U8[32] token_a, U8[32] token_b, U64 initial_a, U64 initial_b) {
    // Validation
    if (initial_a < MINIMUM_LIQUIDITY || initial_b < MINIMUM_LIQUIDITY) {
        return ERROR_INSUFFICIENT_LIQUIDITY;
    }
    
    // Set pool parameters
    pool.token_a_mint = token_a;
    pool.token_b_mint = token_b;
    pool.token_a_reserve = initial_a;
    pool.token_b_reserve = initial_b;
    
    // Calculate initial k
    U64 k = initial_a * initial_b;
    
    // Mint initial LP tokens
    pool.total_lp_supply = sqrt(k) - MINIMUM_LIQUIDITY;
    
    pool.is_initialized = True;
}
```

### 2. Adding Liquidity

```c
// Pseudo-code for adding liquidity
U0 add_liquidity(U64 amount_a, U64 amount_b, U64 min_lp_tokens) {
    // Calculate proportional amounts
    U64 required_b = (amount_a * pool.token_b_reserve) / pool.token_a_reserve;
    
    if (required_b > amount_b) {
        // Adjust amounts to maintain ratio
        amount_a = (amount_b * pool.token_a_reserve) / pool.token_b_reserve;
        required_b = amount_b;
    }
    
    // Calculate LP tokens to mint
    U64 lp_tokens = min(
        (amount_a * pool.total_lp_supply) / pool.token_a_reserve,
        (required_b * pool.total_lp_supply) / pool.token_b_reserve
    );
    
    // Verify slippage protection
    if (lp_tokens < min_lp_tokens) {
        return ERROR_SLIPPAGE_EXCEEDED;
    }
    
    // Update reserves
    pool.token_a_reserve += amount_a;
    pool.token_b_reserve += required_b;
    pool.total_lp_supply += lp_tokens;
}
```

### 3. Token Swapping

```c
// Pseudo-code for token swap
U0 swap_tokens(U64 amount_in, U64 min_amount_out, Bool a_to_b) {
    // Calculate swap output with fees
    U64 amount_in_with_fee = amount_in * (fee_denominator - fee_numerator);
    
    U64 amount_out;
    if (a_to_b) {
        amount_out = (pool.token_b_reserve * amount_in_with_fee) /
                    (pool.token_a_reserve * fee_denominator + amount_in_with_fee);
        
        // Update reserves
        pool.token_a_reserve += amount_in;
        pool.token_b_reserve -= amount_out;
    } else {
        amount_out = (pool.token_a_reserve * amount_in_with_fee) /
                    (pool.token_b_reserve * fee_denominator + amount_in_with_fee);
        
        // Update reserves
        pool.token_b_reserve += amount_in;
        pool.token_a_reserve -= amount_out;
    }
    
    // Verify slippage protection
    if (amount_out < min_amount_out) {
        return ERROR_SLIPPAGE_EXCEEDED;
    }
    
    // Update TWAP oracle
    update_price_oracle();
}
```

### 4. TWAP Oracle Updates

```c
// Pseudo-code for TWAP oracle
U0 update_price_oracle() {
    U64 current_time = get_current_timestamp();
    U64 time_elapsed = current_time - pool.last_update_time;
    
    if (time_elapsed > 0) {
        // Calculate current prices
        U64 price_0 = (pool.token_b_reserve * PRICE_PRECISION) / pool.token_a_reserve;
        U64 price_1 = (pool.token_a_reserve * PRICE_PRECISION) / pool.token_b_reserve;
        
        // Update cumulative prices
        pool.price_cumulative_0 += price_0 * time_elapsed;
        pool.price_cumulative_1 += price_1 * time_elapsed;
        
        pool.last_update_time = current_time;
    }
}
```

## Expected Results

### Successful AMM Deployment

When you compile and run the AMM:

1. **Compilation Success**: Clean BPF bytecode generation
2. **Pool Initialization**: Divine AMM program activation messages
3. **Mathematical Validation**: Constant product formula verification
4. **Oracle Setup**: TWAP price tracking initialization

### Sample Execution Output
```
=== Divine AMM Program Active ===
Automated Market Maker implementation in HolyC
Based on constant product formula: x * y = k
Testing AMM initialization...
Testing liquidity operations...
AMM tests completed successfully
```

### Performance Characteristics

**Gas Efficiency**
- Optimized mathematical operations
- Minimal storage updates
- Batch operation support

**Price Discovery**
- Real-time price updates
- TWAP manipulation resistance
- External oracle integration

## Security Considerations

### Mathematical Security
- **Overflow protection**: Safe arithmetic operations
- **Precision maintenance**: High-precision calculations
- **Invariant preservation**: k-value protection

### Economic Security
- **Slippage protection**: Maximum price impact limits
- **Liquidity requirements**: Minimum liquidity thresholds
- **Fee validation**: Proper fee calculation and distribution

### Access Control
- **Admin functions**: Pool parameter updates
- **Emergency stops**: Pause mechanism for critical issues
- **Upgrade paths**: Controlled contract evolution

## Advanced Features

### 1. Concentrated Liquidity
```c
// Advanced: Range-based liquidity provision
struct ConcentratedPosition {
    U64 tick_lower;    // Lower price tick
    U64 tick_upper;    // Upper price tick
    U64 liquidity;     // Liquidity amount in range
};
```

### 2. Flash Swaps
```c
// Advanced: Flash swap capability
U0 flash_swap(U64 amount_out, U8* callback_data) {
    // Send tokens first
    transfer_tokens(amount_out);
    
    // Execute callback
    execute_callback(callback_data);
    
    // Verify repayment with fees
    verify_flash_loan_repayment();
}
```

### 3. Multi-hop Routing
```c
// Advanced: Multi-pool routing
U0 multi_hop_swap(U8[32]* path, U64 amount_in, U64 min_amount_out) {
    // Execute swaps across multiple pools
    // Optimize for best price execution
}
```

## Troubleshooting

### Common Issues

#### Mathematical Overflow
```bash
# Symptoms: Calculation errors, incorrect prices
# Solution: Use safe math libraries
U64 safe_multiply(U64 a, U64 b) {
    if (a == 0 || b == 0) return 0;
    U64 result = a * b;
    if (result / a != b) {
        return ERROR_OVERFLOW;
    }
    return result;
}
```

#### Liquidity Imbalance
```bash
# Symptoms: Extreme price ratios
# Solution: Implement price bounds
if (price_ratio > MAX_PRICE_RATIO || price_ratio < MIN_PRICE_RATIO) {
    return ERROR_PRICE_OUT_OF_BOUNDS;
}
```

#### Oracle Manipulation
```bash
# Symptoms: Price feed attacks
# Solution: Use TWAP with sufficient time windows
U64 MIN_TWAP_WINDOW = 3600; // 1 hour minimum
```

## Next Steps

### Immediate Next Steps
1. **[Flash Loans Tutorial]({{ '/docs/examples/tutorials/flash-loans' | relative_url }})** - Uncollateralized lending
2. **[Yield Farming Tutorial]({{ '/docs/examples/tutorials/yield-farming' | relative_url }})** - Liquidity mining rewards
3. **[Lending Protocol]({{ '/docs/examples/tutorials/lending' | relative_url }})** - Borrowing and lending

### Advanced DeFi Concepts
- **Impermanent Loss**: Calculate and mitigate IL for LPs
- **Arbitrage**: MEV extraction and prevention
- **Governance**: DAO-controlled AMM parameters

### Integration Projects
- **DEX Aggregator**: Route across multiple AMMs
- **Portfolio Manager**: Automated rebalancing
- **Options Protocol**: Derivatives on AMM prices

## Real-World Applications

### Production Considerations
- **Audit Requirements**: Security review for mainnet
- **Monitoring**: Real-time pool health tracking
- **Governance**: Community parameter control

### Scaling Solutions
- **Layer 2 Integration**: Deploy on Solana's high throughput
- **Cross-chain**: Bridge AMM across networks
- **Batching**: Optimize multiple operations

## Divine Mathematics

> "Mathematics is the alphabet with which God has written the universe" - Terry A. Davis

The constant product formula embodies divine mathematical elegance - simple yet powerful enough to enable global decentralized finance.

## Share This Tutorial

<div class="social-sharing">
  <a href="https://twitter.com/intent/tweet?text=Just%20built%20a%20divine%20AMM%20with%20HolyBPF!%20x%20%C3%97%20y%20%3D%20k%20%F0%9F%99%8F&url={{ site.url }}{{ page.url }}&hashtags=HolyC,BPF,AMM,DeFi" class="share-button twitter" target="_blank">
    Share on Twitter
  </a>
  <a href="{{ 'https://github.com/pibleos/holyBPF-rust/blob/main/examples/amm/' }}" class="share-button github" target="_blank">
    View Source Code
  </a>
</div>

---

**AMM mastery achieved!** You now understand the mathematical foundations of automated market making and can build production-ready DeFi protocols.

<style>
.code-section {
  margin: 1.5rem 0;
  border: 1px solid #e1e5e9;
  border-radius: 8px;
  overflow: hidden;
}

.code-header {
  background: #f8f9fa;
  padding: 0.5rem 1rem;
  border-bottom: 1px solid #e1e5e9;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.9rem;
}

.filename {
  font-weight: 600;
  color: #2c3e50;
}

.github-link {
  color: #007bff;
  text-decoration: none;
  font-size: 0.8rem;
}

.github-link:hover {
  text-decoration: underline;
}

.social-sharing {
  margin: 2rem 0;
  text-align: center;
}

.share-button {
  display: inline-block;
  padding: 0.75rem 1.5rem;
  margin: 0.5rem;
  color: white;
  text-decoration: none;
  border-radius: 6px;
  font-weight: 500;
  transition: all 0.2s;
}

.share-button.twitter {
  background: #1da1f2;
}

.share-button.github {
  background: #333;
}

.share-button:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.15);
  color: white;
  text-decoration: none;
}
</style>
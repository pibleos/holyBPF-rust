# Flash Loans Example

This example demonstrates a professional flash loan implementation in HolyC for Solana BPF, enabling uncollateralized borrowing with atomic transaction execution.

## Features

- **Instant Liquidity**: Borrow large amounts without collateral
- **Dynamic Fee Structure**: Utilization-based fee calculation with surge pricing
- **Callback Execution**: Support for complex DeFi strategies through callbacks
- **Atomic Guarantees**: Automatic repayment enforcement within single transaction
- **Multiple Use Cases**: Arbitrage, liquidation, collateral swapping support
- **Security Controls**: Emergency pause, default handling, and utilization limits

## Use Cases

### 1. Arbitrage
Execute profitable trades across different exchanges using borrowed capital:
```
1. Flash loan tokens from pool
2. Buy asset on DEX A at lower price
3. Sell same asset on DEX B at higher price
4. Repay flash loan + fee
5. Keep the profit
```

### 2. Liquidation
Liquidate undercollateralized positions without having capital:
```
1. Flash loan tokens to repay user's debt
2. Claim liquidation bonus and collateral
3. Sell collateral at market price
4. Repay flash loan + fee
5. Keep liquidation reward
```

### 3. Collateral Swap
Change collateral type in lending protocols:
```
1. Flash loan new collateral tokens
2. Deposit new collateral to lending protocol
3. Withdraw original collateral
4. Sell original collateral for flash loan repayment
5. Position now uses new collateral type
```

## Instructions

1. **Initialize Pool** - Create flash loan pool with liquidity and fee parameters
2. **Provide Liquidity** - Add tokens to the lending pool
3. **Execute Flash Loan** - Borrow tokens with callback execution
4. **Repay Flash Loan** - Return borrowed amount plus fee
5. **Withdraw Liquidity** - Remove tokens from the pool (when not in use)
6. **Update Pool Parameters** - Admin function to adjust fees and limits
7. **Collect Fees** - Withdraw accumulated protocol fees
8. **Emergency Pause** - Halt all operations in emergency situations

## Fee Structure

The protocol uses dynamic fee calculation based on pool utilization:

- **Base Fee**: 0.05% (5 basis points)
- **High Utilization Threshold**: 80%
- **Surge Multiplier**: 2x when utilization > 80%
- **Maximum Fee**: 10% (safety cap)

### Fee Formula
```
utilization_rate = total_borrowed / total_liquidity
if utilization_rate > 80%:
    surge_factor = utilization_rate - 80%
    fee_multiplier = 1 + (surge_factor * 2)
    final_fee = base_fee * fee_multiplier
```

## Security Features

- **Transaction Atomicity**: Flash loan must be repaid in same transaction
- **Expiration Time**: 5-minute maximum loan duration
- **Default Handling**: Automatic pool pause on loan default
- **Emergency Controls**: Admin pause functionality
- **Utilization Limits**: Maximum loan size based on available liquidity
- **Reentrancy Protection**: Single active loan per transaction

## Pool Statistics

The protocol tracks comprehensive statistics:
- Total liquidity provided
- Total amount currently borrowed
- Number of flash loans executed
- Total fees collected
- Current utilization rate
- Real-time APY for liquidity providers

## Usage

```bash
# Compile the flash loan program
./target/release/pible examples/flash-loans/src/main.hc

# Deploy to Solana (hypothetical)
solana program deploy flash-loans.bpf
```

## Architecture

Key data structures:
- `FlashLoanPool`: Pool configuration and liquidity state
- `ActiveFlashLoan`: Current loan state and repayment requirements
- `FlashLoanCallback`: Interface for executing custom strategies
- `FlashLoanResult`: Execution results and statistics

## Testing Scenarios

The example includes tests for:
- Pool initialization with proper parameters
- Flash loan execution with different amounts
- Dynamic fee calculation under various utilization rates
- Arbitrage strategy simulation
- Liquidation scenario simulation
- Security features and emergency controls

## Risk Considerations

- **Smart Contract Risk**: Bugs in callback contracts can cause losses
- **Market Risk**: Price movements during execution can affect profitability
- **Liquidity Risk**: Large loans may cause slippage in target markets
- **Gas Risk**: Complex callbacks may exceed transaction limits
- **MEV Risk**: Miners/validators may front-run profitable opportunities

This implementation provides a solid foundation for building sophisticated DeFi applications requiring instant liquidity access.
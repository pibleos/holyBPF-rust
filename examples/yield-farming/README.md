# Yield Farming Example

This example demonstrates a comprehensive yield farming (liquidity mining) program implemented in HolyC for Solana BPF.

## Features

- **Multi-tier Boost System**: Five boost tiers (Bronze, Silver, Gold, Platinum, Diamond) with increasing rewards for longer staking periods
- **Dynamic APY Calculation**: Real-time APY computation based on reward rates and total staked amounts
- **Flexible Staking**: Support for staking, unstaking, and reward claiming operations
- **Emergency Controls**: Emergency withdrawal with penalties and admin pause functionality
- **Time-lock Security**: Configurable lock periods to prevent MEV attacks

## Boost Tiers

| Tier | Duration | Multiplier |
|------|----------|------------|
| Bronze | 0 days | 1.0x |
| Silver | 7 days | 1.1x |
| Gold | 30 days | 1.25x |
| Platinum | 90 days | 1.5x |
| Diamond | 365 days | 2.0x |

## Instructions

1. **Initialize Farm** - Set up a new farming pool with reward parameters
2. **Stake Tokens** - Deposit LP tokens to earn rewards
3. **Unstake Tokens** - Withdraw staked tokens (subject to lock period)
4. **Claim Rewards** - Collect accumulated rewards with boost multipliers
5. **Update Rewards** - Recalculate reward distribution
6. **Set Farm Rewards** - Admin function to adjust reward rates
7. **Emergency Withdraw** - Emergency unstaking with penalty
8. **Upgrade Boost** - Check and upgrade boost tier based on staking duration

## Usage

```bash
# Compile the yield farming program
./target/release/pible examples/yield-farming/src/main.hc

# Deploy to Solana (hypothetical)
solana program deploy yield-farming.bpf
```

## Architecture

The program uses several key data structures:

- `FarmPool`: Main farming pool configuration and state
- `StakePosition`: Individual staker position and rewards
- `BoostTier`: Boost multiplier tiers for long-term stakers

## Security Features

- Reentrancy protection on reward calculations
- Minimum liquidity requirements
- Emergency pause functionality
- Penalty mechanisms for early withdrawals
- Position locking to prevent flash loan attacks

## Testing

The example includes comprehensive test scenarios:

- Farm initialization with proper parameters
- Staking operations with different amounts
- Reward calculation over time
- Boost system upgrades
- Emergency withdrawal scenarios

This serves as a foundation for more complex DeFi yield farming protocols.
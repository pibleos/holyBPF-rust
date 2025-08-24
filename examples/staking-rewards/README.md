# Staking Rewards - HolyC Implementation

A flexible staking platform built in HolyC for Solana, featuring compounding rewards, governance token distribution, and multi-asset staking pools.

## Features

- **Multi-Asset Staking**: Stake SOL, USDC, and governance tokens
- **Compounding Rewards**: Automatic reward compounding for optimal yield
- **Governance Integration**: Voting power based on staked amounts
- **Flexible Unbonding**: Multiple unbonding periods with different reward rates
- **Liquidity Mining**: Additional rewards for providing DEX liquidity

## Program Structure

```
src/
├── main.hc              # Main program entry point
├── staking.hc           # Core staking logic
├── rewards.hc           # Reward calculation and distribution
├── governance.hc        # Governance voting mechanisms
├── unbonding.hc         # Unbonding period management
└── compound.hc          # Automatic compounding logic
```

## Building

```bash
# Build the compiler
cargo build --release

# Compile the staking rewards program
./target/release/pible examples/staking-rewards/src/main.hc
```

## Key Operations

1. **Stake Tokens**: Stake assets to earn rewards
2. **Unstake Tokens**: Begin unbonding process
3. **Claim Rewards**: Claim accumulated rewards
4. **Compound Rewards**: Automatically reinvest rewards
5. **Vote**: Participate in governance using staked tokens

## HolyC Implementation Highlights

```c
// Staking position structure
struct StakingPosition {
    U8[32] staker;           // Staker public key
    U8[32] asset;            // Staked asset mint
    U64 amount;              // Staked amount
    U64 stake_time;          // Timestamp when staked
    U64 last_reward_time;    // Last reward calculation time
    U64 accumulated_rewards; // Unclaimed rewards
    U32 unbonding_period;    // Chosen unbonding period (days)
    Bool auto_compound;      // Auto-compounding enabled
    U64 voting_power;        // Governance voting power
};

// Staking pool configuration
struct StakingPool {
    U8[32] asset_mint;       // Asset being staked
    U64 total_staked;        // Total amount staked
    U64 reward_rate;         // Annual reward rate (basis points)
    U64 min_stake_amount;    // Minimum stake amount
    U32 max_unbonding_days;  // Maximum unbonding period
    Bool compound_enabled;   // Auto-compounding available
    U64 governance_weight;   // Weight for governance voting
};

// Calculate staking rewards with compounding
U64 calculate_rewards(StakingPosition* position) {
    U64 current_time = get_current_time();
    U64 time_diff = current_time - position->last_reward_time;
    
    StakingPool pool = get_staking_pool(position->asset);
    
    // Base reward calculation
    F64 annual_rate = pool.reward_rate / 10000.0; // Convert basis points
    F64 time_factor = time_diff / 31536000.0; // Convert to years
    F64 base_reward = position->amount * annual_rate * time_factor;
    
    // Unbonding period bonus
    F64 period_bonus = calculate_period_bonus(position->unbonding_period);
    F64 total_reward = base_reward * (1.0 + period_bonus);
    
    // Compound if enabled
    if (position->auto_compound) {
        total_reward = calculate_compound_reward(position, total_reward);
    }
    
    PrintF("Rewards calculated: base=%.2f, bonus=%.2f, total=%.2f\n",
           base_reward, period_bonus, total_reward);
    
    return (U64)total_reward;
}

// Auto-compound rewards back into staking position
U0 compound_rewards(U8* staker) {
    StakingPosition* positions = get_user_positions(staker);
    U32 position_count = get_position_count(staker);
    
    for (U32 i = 0; i < position_count; i++) {
        if (positions[i].auto_compound) {
            U64 rewards = calculate_rewards(&positions[i]);
            
            if (rewards > 0) {
                // Add rewards to staked amount
                positions[i].amount += rewards;
                positions[i].accumulated_rewards = 0;
                positions[i].last_reward_time = get_current_time();
                
                // Update total staked in pool
                StakingPool pool = get_staking_pool(positions[i].asset);
                pool.total_staked += rewards;
                update_staking_pool(pool);
                
                PrintF("Compounded %lu rewards for position %u\n", rewards, i);
            }
        }
    }
}
```

## Unbonding Periods & Rewards

- **7 Days**: Base reward rate (100%)
- **30 Days**: 1.5x reward multiplier  
- **90 Days**: 2.0x reward multiplier
- **365 Days**: 3.0x reward multiplier

## Governance Features

```c
// Calculate voting power based on staked amounts and unbonding periods
U64 calculate_voting_power(StakingPosition* position) {
    U64 base_power = position->amount;
    
    // Longer unbonding periods get higher voting weight
    F64 period_multiplier = 1.0;
    if (position->unbonding_period >= 365) {
        period_multiplier = 2.0;
    } else if (position->unbonding_period >= 90) {
        period_multiplier = 1.5;
    } else if (position->unbonding_period >= 30) {
        period_multiplier = 1.2;
    }
    
    U64 voting_power = (U64)(base_power * period_multiplier);
    position->voting_power = voting_power;
    
    return voting_power;
}

// Submit governance vote
U0 submit_vote(U8* voter, U8* proposal_id, Bool vote_for) {
    U64 total_voting_power = get_total_voting_power(voter);
    
    if (total_voting_power == 0) {
        PrintF("ERROR: No voting power\n");
        return;
    }
    
    // Record vote with voting power weight
    record_governance_vote(voter, proposal_id, vote_for, total_voting_power);
    
    PrintF("Vote submitted: power=%lu, for=%s\n", 
           total_voting_power, vote_for ? "true" : "false");
}
```

## Yield Optimization

- **Compound Frequency**: Hourly compounding for maximum yield
- **Gas Optimization**: Batch processing to minimize transaction costs  
- **Auto-Staking**: Automatically stake received rewards
- **Yield Farming Integration**: Additional rewards from DEX liquidity provision

## Testing

```bash
# Test staking mechanics
./target/release/pible examples/staking-rewards/src/staking.hc

# Test reward calculations
./target/release/pible examples/staking-rewards/src/rewards.hc

# Test governance features
./target/release/pible examples/staking-rewards/src/governance.hc

# Run full staking simulation
./target/release/pible --target bpf-vm --enable-vm-testing examples/staking-rewards/src/main.hc
```

## Divine Patience

> "Patience is divine, and so are the rewards for waiting" - Terry A. Davis

This staking protocol embodies divine patience, rewarding those who demonstrate faith through long-term commitment to the protocol's success.
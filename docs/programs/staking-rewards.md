# Staking Rewards Protocol in HolyC

This guide covers the implementation of a multi-asset staking platform on Solana using HolyC. The protocol enables users to stake various tokens and earn rewards through compound interest and governance participation.

## Overview

A staking rewards protocol allows users to lock up tokens for a period of time in exchange for rewards. The system supports multiple assets, compound rewards, flexible staking periods, and governance integration.

### Key Concepts

**Staking Pools**: Individual pools for different tokens with specific reward rates.

**Compound Interest**: Automatic reinvestment of rewards to increase yields.

**Vesting Schedules**: Time-locked reward distribution mechanisms.

**Slashing Conditions**: Penalty mechanisms for malicious behavior.

**Governance Integration**: Staking power translates to voting rights.

## Staking Architecture

### Account Structure

```c
// Staking pool configuration
struct StakingPool {
    U8[32] pool_id;               // Unique pool identifier
    U8[32] stake_token_mint;      // Token being staked
    U8[32] reward_token_mint;     // Token distributed as rewards
    U8[32] authority;             // Pool authority
    U64 total_staked;             // Total tokens staked in pool
    U64 reward_rate;              // Annual percentage yield (basis points)
    U64 min_stake_amount;         // Minimum stake required
    U64 max_stake_amount;         // Maximum stake per user
    U64 lock_period;              // Minimum lock period (seconds)
    U64 total_rewards_distributed; // Lifetime rewards paid
    U64 pool_creation_time;       // When pool was created
    Bool compound_rewards;        // Whether to auto-compound
    Bool allow_early_withdrawal;  // Allow withdrawal before lock period
    U64 early_withdrawal_penalty; // Penalty for early withdrawal (basis points)
    U8 slashing_conditions;       // Bitmask of slashing conditions
    U64 governance_weight;        // Voting power multiplier
};

// Individual staking position
struct StakePosition {
    U8[32] position_id;           // Unique position identifier
    U8[32] staker;                // Staker address
    U8[32] pool_id;               // Staking pool
    U64 staked_amount;            // Amount staked
    U64 reward_debt;              // Reward debt for calculations
    U64 pending_rewards;          // Unclaimed rewards
    U64 stake_timestamp;          // When stake was created
    U64 last_reward_claim;        // Last reward claim time
    U64 lock_end_time;            // When lock period ends
    U64 total_rewards_earned;     // Lifetime rewards earned
    Bool is_active;               // Whether position is active
    U8 boost_multiplier;          // Reward boost (100 = 1x, 200 = 2x)
};

// Reward calculation data
struct RewardCalculation {
    U8[32] pool_id;               // Pool being calculated
    U64 accumulated_per_share;    // Accumulated rewards per share
    U64 last_reward_block;        // Last block rewards were calculated
    U64 total_allocated_rewards;  // Total rewards allocated
    U64 precision_factor;         // Precision for calculations
};
```

## Implementation Guide

### Pool Creation and Management

```c
U0 create_staking_pool(
    U8* stake_token_mint,
    U8* reward_token_mint,
    U64 reward_rate,
    U64 min_stake_amount,
    U64 lock_period,
    Bool compound_rewards,
    U64 initial_reward_funding
) {
    if (reward_rate == 0 || reward_rate > 10000) { // Max 100% APY
        PrintF("ERROR: Invalid reward rate (1-10000 basis points)\n");
        return;
    }
    
    if (min_stake_amount == 0) {
        PrintF("ERROR: Minimum stake amount must be positive\n");
        return;
    }
    
    if (lock_period < 86400) { // Minimum 1 day
        PrintF("ERROR: Lock period too short (minimum 1 day)\n");
        return;
    }
    
    // Validate token mints
    if (!validate_token_mint(stake_token_mint) || !validate_token_mint(reward_token_mint)) {
        PrintF("ERROR: Invalid token mint\n");
        return;
    }
    
    // Validate initial funding
    if (initial_reward_funding > 0) {
        if (!validate_user_balance(reward_token_mint, initial_reward_funding)) {
            PrintF("ERROR: Insufficient balance for reward funding\n");
            return;
        }
    }
    
    // Generate pool ID
    U8[32] pool_id;
    generate_staking_pool_id(pool_id, stake_token_mint, get_current_user());
    
    // Create staking pool
    StakingPool* pool = get_staking_pool_account(pool_id);
    copy_pubkey(pool->pool_id, pool_id);
    copy_pubkey(pool->stake_token_mint, stake_token_mint);
    copy_pubkey(pool->reward_token_mint, reward_token_mint);
    copy_pubkey(pool->authority, get_current_user());
    
    pool->total_staked = 0;
    pool->reward_rate = reward_rate;
    pool->min_stake_amount = min_stake_amount;
    pool->max_stake_amount = min_stake_amount * 1000; // Default max
    pool->lock_period = lock_period;
    pool->total_rewards_distributed = 0;
    pool->pool_creation_time = get_current_timestamp();
    pool->compound_rewards = compound_rewards;
    pool->allow_early_withdrawal = True;
    pool->early_withdrawal_penalty = 500; // 5% default penalty
    pool->slashing_conditions = 0; // No slashing by default
    pool->governance_weight = 100; // 1x voting weight
    
    // Initialize reward calculation
    initialize_reward_calculation(pool_id);
    
    // Fund pool with initial rewards
    if (initial_reward_funding > 0) {
        transfer_tokens_to_pool(reward_token_mint, pool_id, initial_reward_funding);
    }
    
    PrintF("Staking pool created successfully\n");
    PrintF("Pool ID: %s\n", encode_base58(pool_id));
    PrintF("Stake token: %s\n", encode_base58(stake_token_mint));
    PrintF("Reward rate: %d.%d%% APY\n", reward_rate / 100, reward_rate % 100);
    PrintF("Lock period: %d days\n", lock_period / 86400);
    PrintF("Compound rewards: %s\n", compound_rewards ? "Yes" : "No");
    
    emit_pool_created_event(pool_id, get_current_user(), reward_rate);
}

U0 fund_staking_pool(U8* pool_id, U64 amount) {
    StakingPool* pool = get_staking_pool_account(pool_id);
    
    if (!pool) {
        PrintF("ERROR: Staking pool not found\n");
        return;
    }
    
    // Only authority can fund pool
    if (!compare_pubkeys(pool->authority, get_current_user())) {
        PrintF("ERROR: Only pool authority can add funding\n");
        return;
    }
    
    if (amount == 0) {
        PrintF("ERROR: Funding amount must be positive\n");
        return;
    }
    
    // Validate user balance
    if (!validate_user_balance(pool->reward_token_mint, amount)) {
        PrintF("ERROR: Insufficient balance for funding\n");
        return;
    }
    
    // Transfer tokens to pool
    transfer_tokens_to_pool(pool->reward_token_mint, pool_id, amount);
    
    PrintF("Pool funded with %d reward tokens\n", amount);
}
```

### Staking Operations

```c
U0 stake_tokens(U8* pool_id, U64 amount) {
    StakingPool* pool = get_staking_pool_account(pool_id);
    
    if (!pool) {
        PrintF("ERROR: Staking pool not found\n");
        return;
    }
    
    if (amount < pool->min_stake_amount) {
        PrintF("ERROR: Amount below minimum stake\n");
        PrintF("Minimum: %d, Provided: %d\n", pool->min_stake_amount, amount);
        return;
    }
    
    if (amount > pool->max_stake_amount) {
        PrintF("ERROR: Amount exceeds maximum stake\n");
        return;
    }
    
    // Validate user balance
    if (!validate_user_balance(pool->stake_token_mint, amount)) {
        PrintF("ERROR: Insufficient balance to stake\n");
        return;
    }
    
    // Update pool rewards before staking
    update_pool_rewards(pool_id);
    
    // Check if user already has a position
    U8[32] position_id;
    generate_position_id(position_id, pool_id, get_current_user());
    
    StakePosition* position = get_stake_position_account(position_id);
    
    if (position && position->is_active) {
        // Add to existing position
        add_to_existing_position(position_id, amount);
    } else {
        // Create new position
        create_new_stake_position(pool_id, amount);
    }
    
    // Transfer tokens to pool
    transfer_tokens_to_pool(pool->stake_token_mint, pool_id, amount);
    
    // Update pool totals
    pool->total_staked += amount;
    
    PrintF("Tokens staked successfully\n");
    PrintF("Amount: %d\n", amount);
    PrintF("Lock period: %d seconds\n", pool->lock_period);
    
    emit_stake_event(pool_id, get_current_user(), amount);
}

U0 create_new_stake_position(U8* pool_id, U64 amount) {
    StakingPool* pool = get_staking_pool_account(pool_id);
    
    // Generate position ID
    U8[32] position_id;
    generate_position_id(position_id, pool_id, get_current_user());
    
    // Create stake position
    StakePosition* position = get_stake_position_account(position_id);
    copy_pubkey(position->position_id, position_id);
    copy_pubkey(position->staker, get_current_user());
    copy_pubkey(position->pool_id, pool_id);
    
    position->staked_amount = amount;
    position->reward_debt = calculate_reward_debt(pool_id, amount);
    position->pending_rewards = 0;
    position->stake_timestamp = get_current_timestamp();
    position->last_reward_claim = get_current_timestamp();
    position->lock_end_time = get_current_timestamp() + pool->lock_period;
    position->total_rewards_earned = 0;
    position->is_active = True;
    position->boost_multiplier = 100; // 1x default multiplier
}

U0 claim_staking_rewards(U8* pool_id) {
    StakingPool* pool = get_staking_pool_account(pool_id);
    
    if (!pool) {
        PrintF("ERROR: Staking pool not found\n");
        return;
    }
    
    // Get user's position
    U8[32] position_id;
    generate_position_id(position_id, pool_id, get_current_user());
    
    StakePosition* position = get_stake_position_account(position_id);
    
    if (!position || !position->is_active) {
        PrintF("ERROR: No active staking position found\n");
        return;
    }
    
    // Update pool and position rewards
    update_pool_rewards(pool_id);
    update_position_rewards(position_id);
    
    U64 claimable_rewards = position->pending_rewards;
    
    if (claimable_rewards == 0) {
        PrintF("No rewards to claim\n");
        return;
    }
    
    // Check if compounding is enabled
    if (pool->compound_rewards) {
        // Add rewards to staked amount
        position->staked_amount += claimable_rewards;
        pool->total_staked += claimable_rewards;
        
        PrintF("Rewards compounded: %d tokens\n", claimable_rewards);
    } else {
        // Transfer rewards to user
        transfer_tokens_from_pool(pool->reward_token_mint, pool_id, get_current_user(), claimable_rewards);
        
        PrintF("Rewards claimed: %d tokens\n", claimable_rewards);
    }
    
    // Update position state
    position->pending_rewards = 0;
    position->total_rewards_earned += claimable_rewards;
    position->last_reward_claim = get_current_timestamp();
    
    // Update pool statistics
    pool->total_rewards_distributed += claimable_rewards;
    
    emit_rewards_claimed_event(pool_id, get_current_user(), claimable_rewards);
}

U0 unstake_tokens(U8* pool_id, U64 amount) {
    StakingPool* pool = get_staking_pool_account(pool_id);
    
    if (!pool) {
        PrintF("ERROR: Staking pool not found\n");
        return;
    }
    
    // Get user's position
    U8[32] position_id;
    generate_position_id(position_id, pool_id, get_current_user());
    
    StakePosition* position = get_stake_position_account(position_id);
    
    if (!position || !position->is_active) {
        PrintF("ERROR: No active staking position found\n");
        return;
    }
    
    if (amount > position->staked_amount) {
        PrintF("ERROR: Cannot unstake more than staked amount\n");
        return;
    }
    
    // Check lock period
    Bool is_early_withdrawal = get_current_timestamp() < position->lock_end_time;
    
    if (is_early_withdrawal && !pool->allow_early_withdrawal) {
        PrintF("ERROR: Early withdrawal not allowed\n");
        PrintF("Lock expires: %d\n", position->lock_end_time);
        return;
    }
    
    // Update rewards before unstaking
    update_pool_rewards(pool_id);
    update_position_rewards(position_id);
    
    U64 withdrawal_amount = amount;
    U64 penalty = 0;
    
    // Apply early withdrawal penalty
    if (is_early_withdrawal) {
        penalty = (amount * pool->early_withdrawal_penalty) / 10000;
        withdrawal_amount = amount - penalty;
        
        PrintF("Early withdrawal penalty: %d tokens\n", penalty);
    }
    
    // Transfer tokens to user
    transfer_tokens_from_pool(pool->stake_token_mint, pool_id, get_current_user(), withdrawal_amount);
    
    // Transfer penalty to pool authority (if any)
    if (penalty > 0) {
        transfer_tokens_from_pool(pool->stake_token_mint, pool_id, pool->authority, penalty);
    }
    
    // Update position
    position->staked_amount -= amount;
    position->reward_debt = calculate_reward_debt(pool_id, position->staked_amount);
    
    // Close position if fully unstaked
    if (position->staked_amount == 0) {
        position->is_active = False;
    }
    
    // Update pool totals
    pool->total_staked -= amount;
    
    PrintF("Tokens unstaked successfully\n");
    PrintF("Amount: %d\n", withdrawal_amount);
    PrintF("Penalty: %d\n", penalty);
    
    emit_unstake_event(pool_id, get_current_user(), amount, penalty);
}
```

### Reward Calculation System

```c
U0 update_pool_rewards(U8* pool_id) {
    StakingPool* pool = get_staking_pool_account(pool_id);
    RewardCalculation* calc = get_reward_calculation(pool_id);
    
    if (!pool || !calc) {
        return;
    }
    
    U64 current_block = get_current_block_number();
    
    if (current_block <= calc->last_reward_block) {
        return; // Already updated this block
    }
    
    if (pool->total_staked == 0) {
        calc->last_reward_block = current_block;
        return; // No stakers
    }
    
    // Calculate rewards for elapsed blocks
    U64 blocks_elapsed = current_block - calc->last_reward_block;
    U64 reward_per_block = calculate_reward_per_block(pool);
    U64 total_rewards = reward_per_block * blocks_elapsed;
    
    // Update accumulated rewards per share
    U64 reward_per_share = (total_rewards * calc->precision_factor) / pool->total_staked;
    calc->accumulated_per_share += reward_per_share;
    calc->total_allocated_rewards += total_rewards;
    calc->last_reward_block = current_block;
}

U0 update_position_rewards(U8* position_id) {
    StakePosition* position = get_stake_position_account(position_id);
    RewardCalculation* calc = get_reward_calculation(position->pool_id);
    
    if (!position || !calc) {
        return;
    }
    
    // Calculate pending rewards
    U64 accumulated_rewards = (position->staked_amount * calc->accumulated_per_share) / calc->precision_factor;
    U64 pending = accumulated_rewards - position->reward_debt;
    
    // Apply boost multiplier
    pending = (pending * position->boost_multiplier) / 100;
    
    position->pending_rewards += pending;
    position->reward_debt = accumulated_rewards;
}

U64 calculate_reward_per_block(StakingPool* pool) {
    // Convert annual rate to per-block rate
    // Assuming ~2.16 seconds per block on Solana
    U64 blocks_per_year = 365 * 24 * 3600 / 2; // ~15,768,000 blocks/year
    
    // Get pool reward balance
    U64 pool_balance = get_pool_token_balance(pool->reward_token_mint, pool->pool_id);
    
    // Calculate sustainable reward rate
    U64 annual_rewards = (pool->total_staked * pool->reward_rate) / 10000;
    U64 reward_per_block = annual_rewards / blocks_per_year;
    
    // Ensure we don't exceed available rewards
    return min(reward_per_block, pool_balance / blocks_per_year);
}
```

### Governance Integration

```c
U0 get_voting_power(U8* user_address, U64* voting_power) {
    *voting_power = 0;
    
    // Iterate through all staking pools
    U8[32]* pool_ids = get_all_pool_ids();
    U64 pool_count = get_pool_count();
    
    for (U64 i = 0; i < pool_count; i++) {
        StakingPool* pool = get_staking_pool_account(pool_ids[i]);
        
        if (!pool) continue;
        
        // Get user's position in this pool
        U8[32] position_id;
        generate_position_id(position_id, pool_ids[i], user_address);
        
        StakePosition* position = get_stake_position_account(position_id);
        
        if (position && position->is_active) {
            // Calculate voting power from this position
            U64 pool_voting_power = (position->staked_amount * pool->governance_weight) / 100;
            *voting_power += pool_voting_power;
        }
    }
    
    PrintF("Total voting power: %d\n", *voting_power);
}
```

This comprehensive staking rewards protocol provides flexible multi-asset staking with compound interest, governance integration, and sophisticated reward calculation mechanisms.
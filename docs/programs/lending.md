# Borrow/Lending Protocols in HolyC

This guide covers the implementation of decentralized lending and borrowing protocols on Solana using HolyC. Lending protocols enable users to supply assets to earn interest and borrow assets against collateral.

## Overview

Decentralized lending protocols facilitate peer-to-pool lending where users supply assets to liquidity pools and borrowers draw from these pools. The protocols use algorithmic interest rate models and overcollateralization to manage risk.

### Key Concepts

**Supply and Borrow**: Users supply assets to earn interest or borrow assets by providing collateral.

**Collateral Factor**: The maximum percentage of supplied asset value that can be borrowed against.

**Liquidation**: Process of selling collateral when borrower positions become undercollateralized.

**Interest Rate Model**: Algorithmic determination of supply and borrow rates based on utilization.

## Protocol Architecture

### Core Components

1. **Asset Markets**: Individual lending markets for each supported token
2. **Interest Rate Models**: Supply and borrow rate calculations
3. **Collateral Management**: Track user collateral and borrowing power
4. **Liquidation Engine**: Automated liquidation of undercollateralized positions
5. **Risk Management**: Protocol-level risk parameters and monitoring

### Account Structure

```c
// Market account for each supported asset
struct LendingMarket {
    U8[32] asset_mint;          // Underlying asset mint
    U8[32] market_authority;    // Market authority
    U64 total_supply;           // Total supplied amount
    U64 total_borrow;           // Total borrowed amount
    U64 reserve_factor;         // Protocol reserve percentage
    U64 collateral_factor;      // Collateral factor (basis points)
    U64 liquidation_threshold;  // Liquidation threshold
    U64 liquidation_bonus;      // Liquidation bonus percentage
    U64 supply_rate;            // Current supply APY
    U64 borrow_rate;            // Current borrow APY
    U64 exchange_rate;          // cToken to underlying exchange rate
    U64 last_update_slot;       // Last interest accrual
    Bool is_active;             // Market active status
};

// User obligation tracking borrowed assets and collateral
struct UserObligation {
    U8[32] owner;               // Obligation owner
    U64 borrowed_value;         // Total borrowed value (USD)
    U64 collateral_value;       // Total collateral value (USD)
    U64 health_factor;          // Position health (1.0 = 100%)
    U64 position_count;         // Number of positions
    LendingPosition positions[MAX_POSITIONS]; // User positions
};

// Individual asset position within obligation
struct LendingPosition {
    U8[32] market;              // Market address
    U64 supply_amount;          // Supplied amount (cTokens)
    U64 borrow_amount;          // Borrowed amount (underlying)
    Bool use_as_collateral;     // Whether to use as collateral
};
```

## Implementation Guide

### Market Initialization

Create lending markets for supported assets:

```c
U0 initialize_market(U8* asset_mint, U64 collateral_factor, U64 liquidation_threshold) {
    if (collateral_factor > 9000) { // Max 90% collateral factor
        PrintF("ERROR: Collateral factor too high\n");
        return;
    }
    
    if (liquidation_threshold <= collateral_factor) {
        PrintF("ERROR: Liquidation threshold must exceed collateral factor\n");
        return;
    }
    
    // Generate market PDA
    U8[32] market_address;
    U8 bump_seed;
    find_program_address(&market_address, &bump_seed, asset_mint, "market");
    
    LendingMarket* market = get_account_data(market_address);
    copy_pubkey(market->asset_mint, asset_mint);
    market->total_supply = 0;
    market->total_borrow = 0;
    market->reserve_factor = 1000; // 10% reserve factor
    market->collateral_factor = collateral_factor;
    market->liquidation_threshold = liquidation_threshold;
    market->liquidation_bonus = 500; // 5% liquidation bonus
    market->supply_rate = 0;
    market->borrow_rate = 0;
    market->exchange_rate = 1000000; // Initial 1:1 ratio
    market->last_update_slot = get_current_slot();
    market->is_active = True;
    
    PrintF("Lending market initialized\n");
    PrintF("Asset: %s\n", encode_base58(asset_mint));
    PrintF("Collateral factor: %d.%d%%\n", collateral_factor / 100, collateral_factor % 100);
}
```

### Supply Operations

Users supply assets to earn interest:

```c
U0 supply_asset(U8* market_address, U64 supply_amount) {
    LendingMarket* market = get_account_data(market_address);
    
    if (!market->is_active) {
        PrintF("ERROR: Market not active\n");
        return;
    }
    
    // Accrue interest before supply
    accrue_interest(market);
    
    // Calculate cTokens to mint based on exchange rate
    U64 ctokens_to_mint = (supply_amount * EXCHANGE_RATE_PRECISION) / market->exchange_rate;
    
    if (ctokens_to_mint == 0) {
        PrintF("ERROR: Supply amount too small\n");
        return;
    }
    
    // Transfer underlying tokens to market
    transfer_tokens_to_market(market->asset_mint, supply_amount);
    
    // Update market state
    market->total_supply += ctokens_to_mint;
    
    // Mint cTokens to supplier
    mint_ctokens(market_address, ctokens_to_mint);
    
    // Update user obligation
    update_user_position(market_address, 0, ctokens_to_mint, 0, True);
    
    PrintF("Asset supplied successfully\n");
    PrintF("Supplied: %d underlying tokens\n", supply_amount);
    PrintF("Received: %d cTokens\n", ctokens_to_mint);
    PrintF("Exchange rate: %d\n", market->exchange_rate);
}
```

### Borrow Operations

Users borrow assets against collateral:

```c
U0 borrow_asset(U8* market_address, U64 borrow_amount) {
    LendingMarket* market = get_account_data(market_address);
    
    if (!market->is_active) {
        PrintF("ERROR: Market not active\n");
        return;
    }
    
    // Accrue interest before borrow
    accrue_interest(market);
    
    // Check available liquidity
    U64 available_liquidity = get_market_liquidity(market);
    if (borrow_amount > available_liquidity) {
        PrintF("ERROR: Insufficient market liquidity\n");
        return;
    }
    
    // Get user obligation
    UserObligation* obligation = get_user_obligation();
    
    // Calculate new borrowed value
    U64 asset_price = get_asset_price(market->asset_mint);
    U64 new_borrow_value = obligation->borrowed_value + (borrow_amount * asset_price);
    
    // Calculate borrowing power based on collateral
    U64 borrowing_power = calculate_borrowing_power(obligation);
    
    if (new_borrow_value > borrowing_power) {
        PrintF("ERROR: Insufficient collateral for borrow\n");
        PrintF("Required collateral value: %d\n", new_borrow_value);
        PrintF("Available borrowing power: %d\n", borrowing_power);
        return;
    }
    
    // Execute borrow
    market->total_borrow += borrow_amount;
    transfer_tokens_from_market(market->asset_mint, borrow_amount);
    
    // Update user obligation
    update_user_position(market_address, borrow_amount, 0, 0, False);
    
    // Recalculate health factor
    U64 new_health_factor = calculate_health_factor(obligation);
    obligation->health_factor = new_health_factor;
    
    PrintF("Asset borrowed successfully\n");
    PrintF("Borrowed: %d tokens\n", borrow_amount);
    PrintF("New health factor: %d.%d\n", new_health_factor / 100, new_health_factor % 100);
}
```

### Interest Rate Model

Implement utilization-based interest rate curves:

```c
U0 accrue_interest(LendingMarket* market) {
    U64 current_slot = get_current_slot();
    U64 slots_elapsed = current_slot - market->last_update_slot;
    
    if (slots_elapsed == 0) return;
    
    // Calculate utilization rate
    U64 utilization_rate = 0;
    if (market->total_supply > 0) {
        utilization_rate = (market->total_borrow * UTILIZATION_PRECISION) / 
                          ((market->total_supply * market->exchange_rate) / EXCHANGE_RATE_PRECISION);
    }
    
    // Calculate borrow rate based on utilization
    U64 borrow_rate = calculate_borrow_rate(utilization_rate);
    
    // Calculate supply rate (borrow rate * utilization * (1 - reserve factor))
    U64 supply_rate = (borrow_rate * utilization_rate * (10000 - market->reserve_factor)) / 
                      (UTILIZATION_PRECISION * 10000);
    
    // Apply interest accrual
    if (market->total_borrow > 0) {
        U64 interest_factor = 1000000 + (borrow_rate * slots_elapsed / SLOTS_PER_YEAR);
        market->total_borrow = (market->total_borrow * interest_factor) / 1000000;
    }
    
    // Update exchange rate for cTokens
    if (market->total_supply > 0) {
        U64 supply_interest = (supply_rate * slots_elapsed) / SLOTS_PER_YEAR;
        market->exchange_rate += (market->exchange_rate * supply_interest) / 1000000;
    }
    
    market->supply_rate = supply_rate;
    market->borrow_rate = borrow_rate;
    market->last_update_slot = current_slot;
    
    PrintF("Interest accrued: utilization=%d.%d%%, borrow_rate=%d.%d%%, supply_rate=%d.%d%%\n",
           utilization_rate / 100, utilization_rate % 100,
           borrow_rate / 100, borrow_rate % 100,
           supply_rate / 100, supply_rate % 100);
}

U64 calculate_borrow_rate(U64 utilization_rate) {
    // Kinked interest rate model
    const U64 BASE_RATE = 200;      // 2% base rate
    const U64 MULTIPLIER = 500;     // 5% multiplier
    const U64 JUMP_MULTIPLIER = 10000; // 100% jump multiplier
    const U64 KINK = 8000;          // 80% kink point
    
    if (utilization_rate <= KINK) {
        // Below kink: base rate + utilization * multiplier
        return BASE_RATE + (utilization_rate * MULTIPLIER / UTILIZATION_PRECISION);
    } else {
        // Above kink: base rate + kink * multiplier + (utilization - kink) * jump multiplier
        U64 normal_rate = BASE_RATE + (KINK * MULTIPLIER / UTILIZATION_PRECISION);
        U64 excess_util = utilization_rate - KINK;
        return normal_rate + (excess_util * JUMP_MULTIPLIER / UTILIZATION_PRECISION);
    }
}
```

### Liquidation System

Automated liquidation of undercollateralized positions:

```c
U0 liquidate_obligation(U8* obligation_address, U8* collateral_market, U8* borrow_market, U64 repay_amount) {
    UserObligation* obligation = get_account_data(obligation_address);
    LendingMarket* collateral_mkt = get_account_data(collateral_market);
    LendingMarket* borrow_mkt = get_account_data(borrow_market);
    
    // Accrue interest on both markets
    accrue_interest(collateral_mkt);
    accrue_interest(borrow_mkt);
    
    // Calculate current health factor
    U64 health_factor = calculate_health_factor(obligation);
    
    // Check if liquidation is allowed (health factor < 1.0)
    if (health_factor >= 100) {
        PrintF("ERROR: Position is healthy, liquidation not allowed\n");
        PrintF("Health factor: %d.%d\n", health_factor / 100, health_factor % 100);
        return;
    }
    
    // Get position details
    LendingPosition* collateral_pos = find_position(obligation, collateral_market);
    LendingPosition* borrow_pos = find_position(obligation, borrow_market);
    
    if (!collateral_pos || !borrow_pos) {
        PrintF("ERROR: Position not found\n");
        return;
    }
    
    // Calculate maximum liquidation amount (50% of borrow or full amount if small)
    U64 max_liquidation = borrow_pos->borrow_amount / 2;
    if (borrow_pos->borrow_amount < 100000) {
        max_liquidation = borrow_pos->borrow_amount; // Allow full liquidation for small positions
    }
    
    if (repay_amount > max_liquidation) {
        PrintF("ERROR: Liquidation amount exceeds maximum allowed\n");
        return;
    }
    
    // Calculate collateral seizure amount
    U64 collateral_price = get_asset_price(collateral_mkt->asset_mint);
    U64 borrow_price = get_asset_price(borrow_mkt->asset_mint);
    
    // Collateral value = repay value * (1 + liquidation bonus)
    U64 collateral_value = (repay_amount * borrow_price * 
                           (10000 + collateral_mkt->liquidation_bonus)) / 10000;
    U64 collateral_amount = collateral_value / collateral_price;
    
    // Convert cTokens to underlying for collateral seizure
    U64 collateral_ctokens = (collateral_amount * EXCHANGE_RATE_PRECISION) / 
                            collateral_mkt->exchange_rate;
    
    // Verify sufficient collateral
    if (collateral_ctokens > collateral_pos->supply_amount) {
        PrintF("ERROR: Insufficient collateral for liquidation\n");
        return;
    }
    
    // Execute liquidation
    // 1. Repay borrowed amount
    transfer_tokens_to_market(borrow_mkt->asset_mint, repay_amount);
    borrow_mkt->total_borrow -= repay_amount;
    borrow_pos->borrow_amount -= repay_amount;
    
    // 2. Seize collateral
    collateral_pos->supply_amount -= collateral_ctokens;
    collateral_mkt->total_supply -= collateral_ctokens;
    
    // 3. Transfer seized collateral to liquidator
    U64 underlying_collateral = (collateral_ctokens * collateral_mkt->exchange_rate) / 
                               EXCHANGE_RATE_PRECISION;
    transfer_tokens_from_market(collateral_mkt->asset_mint, underlying_collateral);
    
    // Update obligation
    obligation->borrowed_value -= repay_amount * borrow_price;
    obligation->collateral_value -= collateral_amount * collateral_price;
    obligation->health_factor = calculate_health_factor(obligation);
    
    PrintF("Liquidation executed successfully\n");
    PrintF("Repaid: %d borrowed tokens\n", repay_amount);
    PrintF("Seized: %d collateral tokens\n", underlying_collateral);
    PrintF("New health factor: %d.%d\n", obligation->health_factor / 100, obligation->health_factor % 100);
}
```

### Risk Management

Calculate health factors and borrowing power:

```c
U64 calculate_health_factor(UserObligation* obligation) {
    if (obligation->borrowed_value == 0) {
        return 1000; // 10.0 (maximum health)
    }
    
    U64 weighted_collateral = 0;
    
    // Calculate weighted collateral value using liquidation thresholds
    for (U64 i = 0; i < obligation->position_count; i++) {
        LendingPosition* pos = &obligation->positions[i];
        
        if (pos->use_as_collateral && pos->supply_amount > 0) {
            LendingMarket* market = get_account_data(pos->market);
            U64 underlying_amount = (pos->supply_amount * market->exchange_rate) / EXCHANGE_RATE_PRECISION;
            U64 asset_value = underlying_amount * get_asset_price(market->asset_mint);
            
            // Apply liquidation threshold
            weighted_collateral += (asset_value * market->liquidation_threshold) / 10000;
        }
    }
    
    // Health factor = weighted collateral / borrowed value
    if (obligation->borrowed_value == 0) return 1000;
    return (weighted_collateral * 100) / obligation->borrowed_value;
}

U64 calculate_borrowing_power(UserObligation* obligation) {
    U64 borrowing_power = 0;
    
    for (U64 i = 0; i < obligation->position_count; i++) {
        LendingPosition* pos = &obligation->positions[i];
        
        if (pos->use_as_collateral && pos->supply_amount > 0) {
            LendingMarket* market = get_account_data(pos->market);
            U64 underlying_amount = (pos->supply_amount * market->exchange_rate) / EXCHANGE_RATE_PRECISION;
            U64 asset_value = underlying_amount * get_asset_price(market->asset_mint);
            
            // Apply collateral factor
            borrowing_power += (asset_value * market->collateral_factor) / 10000;
        }
    }
    
    return borrowing_power;
}
```

## Advanced Features

### Flash Loans

Enable flash loans for arbitrage and liquidations:

```c
U0 flash_loan(U8* asset_mint, U64 loan_amount, U8* instruction_data, U64 instruction_len) {
    LendingMarket* market = get_market_by_mint(asset_mint);
    
    if (!market || !market->is_active) {
        PrintF("ERROR: Market not available for flash loans\n");
        return;
    }
    
    U64 available_liquidity = get_market_liquidity(market);
    if (loan_amount > available_liquidity) {
        PrintF("ERROR: Insufficient liquidity for flash loan\n");
        return;
    }
    
    // Calculate flash loan fee (0.09%)
    U64 fee_amount = (loan_amount * 9) / 10000;
    U64 total_repay = loan_amount + fee_amount;
    
    // Record initial balance
    U64 initial_balance = get_token_balance(asset_mint);
    
    // Transfer loan amount to borrower
    transfer_tokens_from_market(asset_mint, loan_amount);
    PrintF("Flash loan executed: %d tokens\n", loan_amount);
    
    // Execute borrower's instructions
    execute_flash_loan_instructions(instruction_data, instruction_len);
    
    // Verify repayment
    U64 final_balance = get_token_balance(asset_mint);
    U64 repaid_amount = final_balance - initial_balance + loan_amount;
    
    if (repaid_amount < total_repay) {
        PrintF("ERROR: Flash loan not repaid in full\n");
        revert_transaction();
        return;
    }
    
    // Collect fee
    transfer_tokens_to_market(asset_mint, total_repay);
    
    PrintF("Flash loan repaid: %d tokens + %d fee\n", loan_amount, fee_amount);
}
```

### Interest Rate Optimization

Dynamic interest rate adjustments:

```c
U0 optimize_interest_rates(U8* market_address) {
    LendingMarket* market = get_account_data(market_address);
    
    // Calculate current utilization
    U64 utilization = 0;
    if (market->total_supply > 0) {
        U64 total_underlying = (market->total_supply * market->exchange_rate) / EXCHANGE_RATE_PRECISION;
        utilization = (market->total_borrow * UTILIZATION_PRECISION) / total_underlying;
    }
    
    // Target utilization rate (80%)
    const U64 TARGET_UTILIZATION = 8000;
    const U64 ADJUSTMENT_FACTOR = 100; // 1% adjustment
    
    if (utilization > TARGET_UTILIZATION + 500) { // Above 85%
        // Increase borrow rate to reduce utilization
        increase_interest_rate_multiplier(market, ADJUSTMENT_FACTOR);
        PrintF("Interest rates increased due to high utilization\n");
    } else if (utilization < TARGET_UTILIZATION - 500) { // Below 75%
        // Decrease borrow rate to increase utilization
        decrease_interest_rate_multiplier(market, ADJUSTMENT_FACTOR);
        PrintF("Interest rates decreased due to low utilization\n");
    }
    
    PrintF("Utilization: %d.%d%%, Target: %d.%d%%\n", 
           utilization / 100, utilization % 100,
           TARGET_UTILIZATION / 100, TARGET_UTILIZATION % 100);
}
```

## Security Considerations

### Oracle Protection

Protect against oracle manipulation:

```c
U0 validate_price_feed(U8* asset_mint, U64 price) {
    // Get historical prices for validation
    U64 previous_price = get_historical_price(asset_mint, 1); // 1 slot ago
    U64 twap_price = get_twap_price(asset_mint, 100); // 100 slot TWAP
    
    // Check for price deviation (max 10% change)
    U64 max_deviation = previous_price / 10;
    if (price > previous_price + max_deviation || 
        price < previous_price - max_deviation) {
        PrintF("WARNING: Large price movement detected\n");
        
        // Use TWAP as fallback if deviation is extreme
        if (price > twap_price * 2 || price < twap_price / 2) {
            PrintF("Using TWAP price as fallback\n");
            update_asset_price(asset_mint, twap_price);
            return;
        }
    }
    
    update_asset_price(asset_mint, price);
}
```

### Position Limits

Implement borrowing and supply limits:

```c
U0 enforce_position_limits(UserObligation* obligation, U8* market_address, U64 amount, Bool is_borrow) {
    LendingMarket* market = get_account_data(market_address);
    U64 asset_price = get_asset_price(market->asset_mint);
    U64 position_value = amount * asset_price;
    
    // Per-user limits
    const U64 MAX_USER_POSITION = 10000000; // $10M equivalent
    const U64 MAX_USER_BORROW = 5000000;    // $5M equivalent
    
    if (is_borrow) {
        if (obligation->borrowed_value + position_value > MAX_USER_BORROW) {
            PrintF("ERROR: Exceeds maximum user borrow limit\n");
            revert_transaction();
            return;
        }
    } else {
        if (obligation->collateral_value + position_value > MAX_USER_POSITION) {
            PrintF("ERROR: Exceeds maximum user position limit\n");
            revert_transaction();
            return;
        }
    }
    
    // Per-market limits
    const U64 MAX_MARKET_UTILIZATION = 9500; // 95%
    
    if (is_borrow) {
        U64 new_utilization = ((market->total_borrow + amount) * 10000) / 
                             ((market->total_supply * market->exchange_rate) / EXCHANGE_RATE_PRECISION);
        
        if (new_utilization > MAX_MARKET_UTILIZATION) {
            PrintF("ERROR: Would exceed maximum market utilization\n");
            revert_transaction();
            return;
        }
    }
}
```

This comprehensive lending protocol implementation provides a robust foundation for decentralized borrowing and lending on Solana, with proper risk management, liquidation mechanisms, and security features.
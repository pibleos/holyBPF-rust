# Synthetic Assets Protocol in HolyC

This guide covers the implementation of a comprehensive synthetic assets protocol on Solana using HolyC. Synthetic assets enable the creation of tokenized derivatives that track the price of underlying assets without requiring direct ownership.

## Overview

A synthetic assets protocol allows users to mint and trade synthetic tokens that mirror the price movements of external assets like stocks, commodities, forex, or crypto assets. The protocol uses collateral backing, oracle price feeds, and liquidation mechanisms to maintain the peg to underlying assets.

### Key Concepts

**Synthetic Assets (Synths)**: Tokenized derivatives that track underlying asset prices through oracle feeds.

**Collateral Vaults**: User deposits that back synthetic asset positions, ensuring system solvency.

**Liquidation Engine**: Automated system that liquidates undercollateralized positions to protect the protocol.

**Oracle Integration**: External price feeds that provide real-time asset pricing data.

**Debt Pool**: Shared debt mechanism where synth holders collectively own protocol debt.

## Protocol Architecture

### Core Components

1. **Asset Management**: Create and manage synthetic asset types
2. **Collateral System**: Handle user deposits and collateralization ratios
3. **Minting Engine**: Create synthetic assets against collateral
4. **Liquidation System**: Maintain system health through position liquidations
5. **Oracle Integration**: Price feed management and updates
6. **Debt Tracking**: Global debt pool and user debt allocation

### Account Structure

```c
// Synthetic asset definition
struct SyntheticAsset {
    U8[32] asset_id;           // Unique asset identifier
    U8[32] oracle_address;     // Price oracle for this asset
    U8[64] asset_symbol;       // Asset symbol (e.g., "sSPY", "sGOLD")
    U8[128] asset_name;        // Full asset name
    U64 current_price;         // Latest oracle price
    U64 last_price_update;     // Timestamp of last price update
    U64 total_supply;          // Total synthetic tokens in circulation
    U64 min_collateral_ratio;  // Minimum collateralization (e.g., 150%)
    U64 liquidation_ratio;     // Liquidation threshold (e.g., 125%)
    U64 liquidation_penalty;   // Penalty for liquidation (e.g., 10%)
    U64 stability_fee;         // Annual fee rate (basis points)
    Bool is_active;            // Whether asset is active for minting
    Bool allow_shorting;       // Whether short positions are allowed
};

// User collateral vault
struct CollateralVault {
    U8[32] vault_id;           // Unique vault identifier
    U8[32] owner;              // Vault owner address
    U8[32] collateral_mint;    // Collateral token mint
    U64 collateral_amount;     // Amount of collateral deposited
    U64 debt_amount;           // Amount of debt (in USD value)
    U64 collateral_ratio;      // Current collateralization ratio
    U64 last_fee_collection;   // Last stability fee collection
    U64 liquidation_price;     // Price at which vault gets liquidated
    U8 vault_status;           // 0 = Active, 1 = Liquidated, 2 = Closed
    U64 creation_timestamp;    // When vault was created
};

// Synthetic token position
struct SynthPosition {
    U8[32] position_id;        // Unique position identifier
    U8[32] owner;              // Position owner
    U8[32] vault_id;           // Associated collateral vault
    U8[32] synth_asset;        // Synthetic asset being minted
    U64 synth_amount;          // Amount of synthetic tokens
    U64 entry_price;           // Price when position was opened
    U64 debt_share;            // Share of global debt pool
    U64 last_fee_payment;      // Last stability fee payment
    Bool is_short;             // Whether this is a short position
};

// Global debt pool state
struct DebtPool {
    U64 total_debt_value;      // Total USD value of all debt
    U64 total_debt_shares;     // Total debt shares issued
    U64 debt_per_share;        // Current debt value per share
    U64 last_debt_update;      // Last debt pool update timestamp
    U64 stability_fee_pool;    // Accumulated stability fees
};
```

## Implementation Guide

### Asset Creation

Register new synthetic assets for minting:

```c
U0 create_synthetic_asset(
    U8* asset_symbol,
    U8* asset_name,
    U8* oracle_address,
    U64 min_collateral_ratio,
    U64 liquidation_ratio,
    U64 stability_fee_rate
) {
    if (min_collateral_ratio < 11000) { // Minimum 110%
        PrintF("ERROR: Collateral ratio too low\n");
        return;
    }
    
    if (liquidation_ratio >= min_collateral_ratio) {
        PrintF("ERROR: Liquidation ratio must be below minimum collateral ratio\n");
        return;
    }
    
    if (stability_fee_rate > 2000) { // Maximum 20% annual
        PrintF("ERROR: Stability fee too high\n");
        return;
    }
    
    // Generate asset ID
    U8[32] asset_id;
    generate_asset_id(asset_id, asset_symbol, oracle_address);
    
    // Check if asset already exists
    if (asset_exists(asset_id)) {
        PrintF("ERROR: Asset already exists\n");
        return;
    }
    
    // Validate oracle
    if (!validate_oracle_address(oracle_address)) {
        PrintF("ERROR: Invalid oracle address\n");
        return;
    }
    
    // Create synthetic asset
    SyntheticAsset* asset = get_synth_asset_account(asset_id);
    copy_pubkey(asset->asset_id, asset_id);
    copy_pubkey(asset->oracle_address, oracle_address);
    copy_string(asset->asset_symbol, asset_symbol, 64);
    copy_string(asset->asset_name, asset_name, 128);
    
    asset->current_price = get_oracle_price(oracle_address);
    asset->last_price_update = get_current_timestamp();
    asset->total_supply = 0;
    asset->min_collateral_ratio = min_collateral_ratio;
    asset->liquidation_ratio = liquidation_ratio;
    asset->liquidation_penalty = 1000; // 10% default penalty
    asset->stability_fee = stability_fee_rate;
    asset->is_active = True;
    asset->allow_shorting = True;
    
    PrintF("Synthetic asset created successfully\n");
    PrintF("Symbol: %s\n", asset_symbol);
    PrintF("Oracle: %s\n", encode_base58(oracle_address));
    PrintF("Min collateral ratio: %d.%d%%\n", min_collateral_ratio / 100, min_collateral_ratio % 100);
}
```

### Collateral Management

Handle user collateral deposits and vault management:

```c
U0 create_collateral_vault(U8* collateral_mint, U64 initial_deposit) {
    if (initial_deposit == 0) {
        PrintF("ERROR: Initial deposit must be positive\n");
        return;
    }
    
    // Validate collateral type
    if (!is_approved_collateral(collateral_mint)) {
        PrintF("ERROR: Collateral type not approved\n");
        return;
    }
    
    // Validate user balance
    if (!validate_user_balance(collateral_mint, initial_deposit)) {
        PrintF("ERROR: Insufficient collateral balance\n");
        return;
    }
    
    // Generate vault ID
    U8[32] vault_id;
    generate_vault_id(vault_id, get_current_user(), collateral_mint);
    
    // Check if vault already exists
    if (vault_exists(vault_id)) {
        PrintF("ERROR: Vault already exists for this collateral type\n");
        return;
    }
    
    // Create vault
    CollateralVault* vault = get_collateral_vault_account(vault_id);
    copy_pubkey(vault->vault_id, vault_id);
    copy_pubkey(vault->owner, get_current_user());
    copy_pubkey(vault->collateral_mint, collateral_mint);
    
    vault->collateral_amount = initial_deposit;
    vault->debt_amount = 0;
    vault->collateral_ratio = U64_MAX; // Infinite ratio with no debt
    vault->last_fee_collection = get_current_timestamp();
    vault->liquidation_price = 0;
    vault->vault_status = 0; // Active
    vault->creation_timestamp = get_current_timestamp();
    
    // Transfer collateral to vault
    transfer_tokens_to_vault(collateral_mint, initial_deposit);
    
    PrintF("Collateral vault created\n");
    PrintF("Vault ID: %s\n", encode_base58(vault_id));
    PrintF("Initial deposit: %d\n", initial_deposit);
}

U0 deposit_collateral(U8* vault_id, U64 amount) {
    CollateralVault* vault = get_collateral_vault_account(vault_id);
    
    if (!vault || vault->vault_status != 0) {
        PrintF("ERROR: Vault not available\n");
        return;
    }
    
    if (!compare_pubkeys(vault->owner, get_current_user())) {
        PrintF("ERROR: Not vault owner\n");
        return;
    }
    
    if (amount == 0) {
        PrintF("ERROR: Deposit amount must be positive\n");
        return;
    }
    
    // Validate user balance
    if (!validate_user_balance(vault->collateral_mint, amount)) {
        PrintF("ERROR: Insufficient balance\n");
        return;
    }
    
    // Transfer collateral to vault
    transfer_tokens_to_vault(vault->collateral_mint, amount);
    
    // Update vault state
    vault->collateral_amount += amount;
    
    // Recalculate collateral ratio
    if (vault->debt_amount > 0) {
        U64 collateral_value = get_collateral_value(vault->collateral_mint, vault->collateral_amount);
        vault->collateral_ratio = (collateral_value * 10000) / vault->debt_amount;
        vault->liquidation_price = calculate_liquidation_price(vault);
    }
    
    PrintF("Collateral deposited successfully\n");
    PrintF("Amount: %d\n", amount);
    PrintF("New collateral ratio: %d.%d%%\n", vault->collateral_ratio / 100, vault->collateral_ratio % 100);
}

U0 withdraw_collateral(U8* vault_id, U64 amount) {
    CollateralVault* vault = get_collateral_vault_account(vault_id);
    
    if (!vault || vault->vault_status != 0) {
        PrintF("ERROR: Vault not available\n");
        return;
    }
    
    if (!compare_pubkeys(vault->owner, get_current_user())) {
        PrintF("ERROR: Not vault owner\n");
        return;
    }
    
    if (amount == 0 || amount > vault->collateral_amount) {
        PrintF("ERROR: Invalid withdrawal amount\n");
        return;
    }
    
    // Calculate new collateral ratio after withdrawal
    U64 remaining_collateral = vault->collateral_amount - amount;
    
    if (vault->debt_amount > 0) {
        U64 remaining_value = get_collateral_value(vault->collateral_mint, remaining_collateral);
        U64 new_ratio = (remaining_value * 10000) / vault->debt_amount;
        
        // Find minimum collateral ratio for any asset in vault
        U64 min_ratio = get_vault_min_collateral_ratio(vault_id);
        
        if (new_ratio < min_ratio) {
            PrintF("ERROR: Withdrawal would violate collateral ratio\n");
            PrintF("Required: %d.%d%%, Would be: %d.%d%%\n", 
                   min_ratio / 100, min_ratio % 100,
                   new_ratio / 100, new_ratio % 100);
            return;
        }
        
        vault->collateral_ratio = new_ratio;
        vault->liquidation_price = calculate_liquidation_price(vault);
    }
    
    // Update vault state
    vault->collateral_amount -= amount;
    
    // Transfer collateral to user
    transfer_tokens_from_vault(vault->collateral_mint, amount);
    
    PrintF("Collateral withdrawn successfully\n");
    PrintF("Amount: %d\n", amount);
    if (vault->debt_amount > 0) {
        PrintF("New collateral ratio: %d.%d%%\n", vault->collateral_ratio / 100, vault->collateral_ratio % 100);
    }
}
```

### Synthetic Asset Minting

Create synthetic tokens against collateral:

```c
U0 mint_synthetic_asset(U8* vault_id, U8* asset_id, U64 synth_amount) {
    CollateralVault* vault = get_collateral_vault_account(vault_id);
    SyntheticAsset* asset = get_synth_asset_account(asset_id);
    
    if (!vault || vault->vault_status != 0) {
        PrintF("ERROR: Vault not available\n");
        return;
    }
    
    if (!asset || !asset->is_active) {
        PrintF("ERROR: Asset not available for minting\n");
        return;
    }
    
    if (!compare_pubkeys(vault->owner, get_current_user())) {
        PrintF("ERROR: Not vault owner\n");
        return;
    }
    
    if (synth_amount == 0) {
        PrintF("ERROR: Mint amount must be positive\n");
        return;
    }
    
    // Update asset price from oracle
    update_asset_price(asset_id);
    
    // Calculate USD value of synthetic tokens to mint
    U64 synth_value = (synth_amount * asset->current_price) / PRICE_PRECISION;
    
    // Calculate new debt amount
    U64 new_debt = vault->debt_amount + synth_value;
    
    // Calculate collateral value
    U64 collateral_value = get_collateral_value(vault->collateral_mint, vault->collateral_amount);
    
    // Check collateral ratio
    U64 new_ratio = (collateral_value * 10000) / new_debt;
    
    if (new_ratio < asset->min_collateral_ratio) {
        PrintF("ERROR: Insufficient collateral\n");
        PrintF("Required: %d.%d%%, Would be: %d.%d%%\n",
               asset->min_collateral_ratio / 100, asset->min_collateral_ratio % 100,
               new_ratio / 100, new_ratio % 100);
        return;
    }
    
    // Collect stability fees before minting
    collect_stability_fees(vault_id);
    
    // Update vault state
    vault->debt_amount = new_debt;
    vault->collateral_ratio = new_ratio;
    vault->liquidation_price = calculate_liquidation_price(vault);
    
    // Create or update synthetic position
    create_synth_position(vault_id, asset_id, synth_amount, asset->current_price);
    
    // Update global debt pool
    update_debt_pool(synth_value, True); // Add debt
    
    // Update asset supply
    asset->total_supply += synth_amount;
    
    // Mint synthetic tokens to user
    mint_synth_tokens(asset_id, synth_amount);
    
    PrintF("Synthetic asset minted successfully\n");
    PrintF("Asset: %s\n", asset->asset_symbol);
    PrintF("Amount: %d\n", synth_amount);
    PrintF("Value: %d USD\n", synth_value);
    PrintF("New collateral ratio: %d.%d%%\n", new_ratio / 100, new_ratio % 100);
}

U0 burn_synthetic_asset(U8* vault_id, U8* asset_id, U64 synth_amount) {
    CollateralVault* vault = get_collateral_vault_account(vault_id);
    SyntheticAsset* asset = get_synth_asset_account(asset_id);
    
    if (!vault || vault->vault_status != 0) {
        PrintF("ERROR: Vault not available\n");
        return;
    }
    
    if (!asset) {
        PrintF("ERROR: Asset not found\n");
        return;
    }
    
    if (!compare_pubkeys(vault->owner, get_current_user())) {
        PrintF("ERROR: Not vault owner\n");
        return;
    }
    
    // Validate user has synthetic tokens to burn
    if (!validate_user_balance(asset->asset_id, synth_amount)) {
        PrintF("ERROR: Insufficient synthetic tokens\n");
        return;
    }
    
    // Update asset price from oracle
    update_asset_price(asset_id);
    
    // Calculate USD value of synthetic tokens to burn
    U64 synth_value = (synth_amount * asset->current_price) / PRICE_PRECISION;
    
    // Validate burn amount doesn't exceed debt
    if (synth_value > vault->debt_amount) {
        synth_value = vault->debt_amount;
        synth_amount = (synth_value * PRICE_PRECISION) / asset->current_price;
    }
    
    // Collect stability fees before burning
    collect_stability_fees(vault_id);
    
    // Burn synthetic tokens from user
    burn_synth_tokens(asset_id, synth_amount);
    
    // Update vault state
    vault->debt_amount -= synth_value;
    
    if (vault->debt_amount > 0) {
        U64 collateral_value = get_collateral_value(vault->collateral_mint, vault->collateral_amount);
        vault->collateral_ratio = (collateral_value * 10000) / vault->debt_amount;
        vault->liquidation_price = calculate_liquidation_price(vault);
    } else {
        vault->collateral_ratio = U64_MAX; // Infinite ratio with no debt
        vault->liquidation_price = 0;
    }
    
    // Update synthetic position
    update_synth_position(vault_id, asset_id, synth_amount, False); // Remove
    
    // Update global debt pool
    update_debt_pool(synth_value, False); // Remove debt
    
    // Update asset supply
    asset->total_supply -= synth_amount;
    
    PrintF("Synthetic asset burned successfully\n");
    PrintF("Asset: %s\n", asset->asset_symbol);
    PrintF("Amount burned: %d\n", synth_amount);
    PrintF("Debt reduced by: %d USD\n", synth_value);
    
    if (vault->debt_amount > 0) {
        PrintF("New collateral ratio: %d.%d%%\n", vault->collateral_ratio / 100, vault->collateral_ratio % 100);
    } else {
        PrintF("Vault debt fully repaid\n");
    }
}
```

### Liquidation System

Automated liquidation of undercollateralized positions:

```c
U0 liquidate_vault(U8* vault_id, U8* asset_to_liquidate) {
    CollateralVault* vault = get_collateral_vault_account(vault_id);
    SyntheticAsset* asset = get_synth_asset_account(asset_to_liquidate);
    
    if (!vault || vault->vault_status != 0) {
        PrintF("ERROR: Vault not available for liquidation\n");
        return;
    }
    
    if (!asset) {
        PrintF("ERROR: Asset not found\n");
        return;
    }
    
    // Update all oracle prices
    update_asset_price(asset_to_liquidate);
    
    // Calculate current collateral ratio
    U64 collateral_value = get_collateral_value(vault->collateral_mint, vault->collateral_amount);
    U64 current_ratio = (collateral_value * 10000) / vault->debt_amount;
    
    // Check if vault is below liquidation threshold
    if (current_ratio >= asset->liquidation_ratio) {
        PrintF("ERROR: Vault not eligible for liquidation\n");
        PrintF("Current ratio: %d.%d%%, Liquidation threshold: %d.%d%%\n",
               current_ratio / 100, current_ratio % 100,
               asset->liquidation_ratio / 100, asset->liquidation_ratio % 100);
        return;
    }
    
    // Get position for this asset
    SynthPosition* position = get_synth_position(vault_id, asset_to_liquidate);
    if (!position || position->synth_amount == 0) {
        PrintF("ERROR: No position to liquidate\n");
        return;
    }
    
    // Calculate liquidation amounts
    U64 debt_to_cover = (position->synth_amount * asset->current_price) / PRICE_PRECISION;
    U64 collateral_to_seize = (debt_to_cover * (10000 + asset->liquidation_penalty)) / 10000;
    
    // Convert collateral value to collateral tokens
    U64 collateral_price = get_collateral_price(vault->collateral_mint);
    U64 collateral_tokens = (collateral_to_seize * PRICE_PRECISION) / collateral_price;
    
    // Ensure we don't seize more collateral than available
    if (collateral_tokens > vault->collateral_amount) {
        collateral_tokens = vault->collateral_amount;
        collateral_to_seize = (collateral_tokens * collateral_price) / PRICE_PRECISION;
    }
    
    // Validate liquidator has synthetic tokens to repay debt
    if (!validate_user_balance(asset->asset_id, position->synth_amount)) {
        PrintF("ERROR: Liquidator insufficient synthetic tokens\n");
        return;
    }
    
    // Execute liquidation
    
    // 1. Burn synthetic tokens from liquidator
    burn_synth_tokens_from_user(asset->asset_id, position->synth_amount, get_current_user());
    
    // 2. Transfer collateral to liquidator
    transfer_tokens_from_vault(vault->collateral_mint, collateral_tokens);
    
    // 3. Update vault state
    vault->collateral_amount -= collateral_tokens;
    vault->debt_amount -= debt_to_cover;
    
    // 4. Update position
    position->synth_amount = 0;
    
    // 5. Update global debt pool
    update_debt_pool(debt_to_cover, False); // Remove debt
    
    // 6. Update asset supply
    asset->total_supply -= position->synth_amount;
    
    // 7. Check if vault should be marked as liquidated
    if (vault->debt_amount == 0 || vault->collateral_amount == 0) {
        vault->vault_status = 1; // Liquidated
    } else {
        // Recalculate collateral ratio
        U64 remaining_collateral_value = get_collateral_value(vault->collateral_mint, vault->collateral_amount);
        vault->collateral_ratio = (remaining_collateral_value * 10000) / vault->debt_amount;
        vault->liquidation_price = calculate_liquidation_price(vault);
    }
    
    // 8. Distribute liquidation penalty
    U64 penalty_amount = (collateral_to_seize * asset->liquidation_penalty) / 10000;
    distribute_liquidation_penalty(penalty_amount);
    
    PrintF("Vault liquidated successfully\n");
    PrintF("Debt covered: %d USD\n", debt_to_cover);
    PrintF("Collateral seized: %d tokens (%d USD)\n", collateral_tokens, collateral_to_seize);
    PrintF("Liquidation penalty: %d USD\n", penalty_amount);
    
    emit_liquidation_event(vault_id, asset_to_liquidate, debt_to_cover, collateral_to_seize);
}

U0 check_vault_health(U8* vault_id) {
    CollateralVault* vault = get_collateral_vault_account(vault_id);
    
    if (!vault || vault->vault_status != 0) {
        return; // Skip inactive vaults
    }
    
    if (vault->debt_amount == 0) {
        return; // No debt to check
    }
    
    // Update collateral value with latest prices
    U64 collateral_value = get_collateral_value(vault->collateral_mint, vault->collateral_amount);
    U64 current_ratio = (collateral_value * 10000) / vault->debt_amount;
    
    vault->collateral_ratio = current_ratio;
    
    // Check all positions in vault for liquidation eligibility
    SynthPosition* positions = get_vault_positions(vault_id);
    U64 position_count = get_vault_position_count(vault_id);
    
    for (U64 i = 0; i < position_count; i++) {
        SyntheticAsset* asset = get_synth_asset_account(positions[i].synth_asset);
        
        if (current_ratio < asset->liquidation_ratio) {
            PrintF("LIQUIDATION_ALERT: Vault %s below threshold for %s\n",
                   encode_base58(vault_id), asset->asset_symbol);
            PrintF("Current ratio: %d.%d%%, Threshold: %d.%d%%\n",
                   current_ratio / 100, current_ratio % 100,
                   asset->liquidation_ratio / 100, asset->liquidation_ratio % 100);
            
            // Mark for automatic liquidation
            queue_liquidation(vault_id, positions[i].synth_asset);
        }
    }
}
```

## Advanced Features

### Short Positions

Enable users to take short positions on synthetic assets:

```c
U0 open_short_position(U8* vault_id, U8* asset_id, U64 short_amount) {
    SyntheticAsset* asset = get_synth_asset_account(asset_id);
    
    if (!asset || !asset->allow_shorting) {
        PrintF("ERROR: Shorting not allowed for this asset\n");
        return;
    }
    
    // Shorting requires minting synthetic tokens and immediately selling them
    // User receives USD value upfront but owes the synthetic tokens
    
    update_asset_price(asset_id);
    
    U64 usd_received = (short_amount * asset->current_price) / PRICE_PRECISION;
    
    // Create short position
    SynthPosition* position = create_synth_position(vault_id, asset_id, short_amount, asset->current_price);
    position->is_short = True;
    
    // Mint synthetic tokens to pool (not to user)
    mint_synth_tokens_to_pool(asset_id, short_amount);
    
    // Transfer USD value to user
    transfer_usd_to_user(usd_received);
    
    // Update debt accounting (short positions increase debt)
    CollateralVault* vault = get_collateral_vault_account(vault_id);
    vault->debt_amount += usd_received;
    
    PrintF("Short position opened\n");
    PrintF("Asset: %s\n", asset->asset_symbol);
    PrintF("Short amount: %d\n", short_amount);
    PrintF("USD received: %d\n", usd_received);
}

U0 close_short_position(U8* vault_id, U8* asset_id) {
    SynthPosition* position = get_synth_position(vault_id, asset_id);
    
    if (!position || !position->is_short) {
        PrintF("ERROR: No short position found\n");
        return;
    }
    
    SyntheticAsset* asset = get_synth_asset_account(asset_id);
    update_asset_price(asset_id);
    
    U64 current_value = (position->synth_amount * asset->current_price) / PRICE_PRECISION;
    U64 entry_value = (position->synth_amount * position->entry_price) / PRICE_PRECISION;
    
    // Calculate P&L
    I64 pnl = entry_value - current_value; // Profit if asset price decreased
    
    // User must provide synthetic tokens to close short
    if (!validate_user_balance(asset_id, position->synth_amount)) {
        PrintF("ERROR: Insufficient synthetic tokens to close short\n");
        return;
    }
    
    // Burn synthetic tokens from user
    burn_synth_tokens_from_user(asset_id, position->synth_amount, get_current_user());
    
    // Remove synthetic tokens from pool
    burn_synth_tokens_from_pool(asset_id, position->synth_amount);
    
    // Update vault debt
    CollateralVault* vault = get_collateral_vault_account(vault_id);
    vault->debt_amount = vault->debt_amount > entry_value ? vault->debt_amount - entry_value : 0;
    
    // Clear position
    position->synth_amount = 0;
    position->is_short = False;
    
    PrintF("Short position closed\n");
    PrintF("Asset: %s\n", asset->asset_symbol);
    PrintF("P&L: %s%d USD\n", pnl >= 0 ? "+" : "", pnl);
}
```

This comprehensive synthetic assets protocol provides sophisticated derivative instruments with proper collateralization, oracle integration, and risk management systems for creating tokenized exposure to external assets.
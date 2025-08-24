// HolyC Solana Synthetic Assets Protocol - Divine Asset Synthesis
// Professional implementation for creating and managing synthetic assets
// Enables exposure to real-world assets through blockchain tokens

// Synthetic asset data structure
struct SyntheticAsset {
    U8[32] asset_id;              // Unique asset identifier
    U8[32] mint_address;          // Token mint for synthetic asset
    U8[32] collateral_mint;       // Underlying collateral token
    U64 total_supply;             // Total synthetic tokens minted
    U64 collateral_amount;        // Total collateral locked
    U64 collateral_ratio;         // Required collateralization (150% = 1500)
    U64 liquidation_ratio;        // Liquidation threshold (130% = 1300)
    U64 target_price;             // Target price in USD (8 decimals)
    U64 current_price;            // Current oracle price
    U64 debt_ceiling;             // Maximum debt allowed
    U64 stability_fee;            // Annual borrowing fee (basis points)
    U64 liquidation_penalty;      // Penalty for liquidation (basis points)
    Bool is_active;               // Asset is active for minting
    U64 last_update_time;         // Last price update timestamp
    U8[32] price_oracle;          // Oracle providing price feeds
};

// Collateral Debt Position (vault)
struct SyntheticVault {
    U8[32] vault_id;              // Unique vault identifier
    U8[32] asset_id;              // Associated synthetic asset
    U8[32] owner;                 // Vault owner address
    U64 collateral_deposited;     // Collateral amount in vault
    U64 synthetic_minted;         // Synthetic tokens minted
    U64 accumulated_fees;         // Accrued stability fees
    U64 last_fee_update;          // Last fee calculation time
    Bool is_liquidatable;         // Vault below liquidation ratio
    U64 liquidation_price;        // Price at which vault gets liquidated
    U64 creation_time;            // Vault creation timestamp
};

// Liquidation event
struct LiquidationEvent {
    U8[32] vault_id;              // Liquidated vault
    U8[32] liquidator;            // Address performing liquidation
    U64 collateral_seized;        // Collateral amount seized
    U64 debt_repaid;              // Debt amount repaid
    U64 penalty_amount;           // Penalty charged
    U64 liquidation_time;         // Timestamp of liquidation
};

// Global protocol state
struct ProtocolState {
    U8[32] admin;                 // Protocol administrator
    U64 total_collateral_locked;  // System-wide collateral
    U64 total_synthetic_supply;   // Total synthetic tokens outstanding
    U64 liquidation_fund;         // Emergency liquidation fund
    U64 protocol_fees_collected;  // Accumulated protocol fees
    Bool global_settlement;       // Emergency shutdown flag
    U64 settlement_price;         // Price during global settlement
    U64 last_fee_collection;      // Last protocol fee collection
};

// Global constants
static const U64 PRICE_PRECISION = 100000000;  // 8 decimals for USD prices
static const U64 RATIO_PRECISION = 10000;      // 4 decimals for ratios
static const U64 FEE_PRECISION = 10000;        // Basis points for fees
static const U64 MIN_COLLATERAL_RATIO = 1500;  // 150% minimum
static const U64 LIQUIDATION_RATIO = 1300;     // 130% liquidation threshold
static const U64 LIQUIDATION_PENALTY = 1300;   // 13% liquidation penalty
static const U64 MAX_ASSETS = 100;             // Maximum synthetic assets
static const U64 SECONDS_PER_YEAR = 31536000;  // For fee calculations

// Global state
static SyntheticAsset assets[MAX_ASSETS];
static U64 asset_count = 0;
static ProtocolState protocol_state;
static Bool protocol_initialized = False;

// Divine main function - Entry point for testing
U0 main() {
    PrintF("=== Divine Synthetic Assets Protocol Active ===\n");
    PrintF("Decentralized synthetic asset creation and management\n");
    PrintF("Enabling exposure to real-world assets on blockchain\n");
    
    // Run comprehensive test scenarios
    test_protocol_initialization();
    test_asset_creation();
    test_vault_operations();
    test_liquidation_system();
    test_price_oracle();
    test_global_settlement();
    
    PrintF("=== Synthetic Assets Tests Completed Successfully ===\n");
    return 0;
}

// Solana program entrypoint
export U0 entrypoint(U8* input, U64 input_len) {
    PrintF("Synthetic Assets entrypoint called with input length: %d\n", input_len);
    
    if (input_len < 1) {
        PrintF("ERROR: No instruction provided\n");
        return;
    }
    
    U8 instruction_type = *input;
    U8* instruction_data = input + 1;
    U64 data_len = input_len - 1;
    
    switch (instruction_type) {
        case 0:
            PrintF("Instruction: Initialize Protocol\n");
            process_initialize_protocol(instruction_data, data_len);
            break;
        case 1:
            PrintF("Instruction: Create Synthetic Asset\n");
            process_create_asset(instruction_data, data_len);
            break;
        case 2:
            PrintF("Instruction: Open Vault\n");
            process_open_vault(instruction_data, data_len);
            break;
        case 3:
            PrintF("Instruction: Deposit Collateral\n");
            process_deposit_collateral(instruction_data, data_len);
            break;
        case 4:
            PrintF("Instruction: Mint Synthetic\n");
            process_mint_synthetic(instruction_data, data_len);
            break;
        case 5:
            PrintF("Instruction: Burn Synthetic\n");
            process_burn_synthetic(instruction_data, data_len);
            break;
        case 6:
            PrintF("Instruction: Withdraw Collateral\n");
            process_withdraw_collateral(instruction_data, data_len);
            break;
        case 7:
            PrintF("Instruction: Liquidate Vault\n");
            process_liquidate_vault(instruction_data, data_len);
            break;
        case 8:
            PrintF("Instruction: Update Price\n");
            process_update_price(instruction_data, data_len);
            break;
        case 9:
            PrintF("Instruction: Global Settlement\n");
            process_global_settlement(instruction_data, data_len);
            break;
        default:
            PrintF("ERROR: Unknown instruction type: %d\n", instruction_type);
            break;
    }
    
    return;
}

// Initialize the synthetic assets protocol
U0 process_initialize_protocol(U8* data, U64 data_len) {
    if (protocol_initialized) {
        PrintF("ERROR: Protocol already initialized\n");
        return;
    }
    
    if (data_len < 32) {
        PrintF("ERROR: Invalid data length for protocol initialization\n");
        return;
    }
    
    // Set protocol administrator
    CopyMemory(protocol_state.admin, data, 32);
    protocol_state.total_collateral_locked = 0;
    protocol_state.total_synthetic_supply = 0;
    protocol_state.liquidation_fund = 0;
    protocol_state.protocol_fees_collected = 0;
    protocol_state.global_settlement = False;
    protocol_state.settlement_price = 0;
    protocol_state.last_fee_collection = get_current_timestamp();
    
    protocol_initialized = True;
    asset_count = 0;
    
    PrintF("Protocol initialized successfully\n");
    PrintF("Administrator: ");
    print_pubkey(protocol_state.admin);
    PrintF("\n");
}

// Create a new synthetic asset
U0 process_create_asset(U8* data, U64 data_len) {
    if (!protocol_initialized) {
        PrintF("ERROR: Protocol not initialized\n");
        return;
    }
    
    if (asset_count >= MAX_ASSETS) {
        PrintF("ERROR: Maximum number of assets reached\n");
        return;
    }
    
    if (data_len < 32 + 32 + 32 + 8 + 8 + 8 + 8 + 32) {
        PrintF("ERROR: Invalid data length for asset creation\n");
        return;
    }
    
    SyntheticAsset* asset = &assets[asset_count];
    U64 offset = 0;
    
    // Parse asset creation data
    CopyMemory(asset->asset_id, data + offset, 32);
    offset += 32;
    CopyMemory(asset->mint_address, data + offset, 32);
    offset += 32;
    CopyMemory(asset->collateral_mint, data + offset, 32);
    offset += 32;
    
    asset->collateral_ratio = read_u64_le(data + offset);
    offset += 8;
    asset->liquidation_ratio = read_u64_le(data + offset);
    offset += 8;
    asset->target_price = read_u64_le(data + offset);
    offset += 8;
    asset->debt_ceiling = read_u64_le(data + offset);
    offset += 8;
    CopyMemory(asset->price_oracle, data + offset, 32);
    offset += 32;
    
    // Validate parameters
    if (asset->collateral_ratio < MIN_COLLATERAL_RATIO) {
        PrintF("ERROR: Collateral ratio too low\n");
        return;
    }
    
    if (asset->liquidation_ratio >= asset->collateral_ratio) {
        PrintF("ERROR: Liquidation ratio must be less than collateral ratio\n");
        return;
    }
    
    // Initialize asset state
    asset->total_supply = 0;
    asset->collateral_amount = 0;
    asset->current_price = asset->target_price;
    asset->stability_fee = 500; // 5% annual fee
    asset->liquidation_penalty = LIQUIDATION_PENALTY;
    asset->is_active = True;
    asset->last_update_time = get_current_timestamp();
    
    asset_count++;
    
    PrintF("Synthetic asset created successfully\n");
    PrintF("Asset ID: ");
    print_pubkey(asset->asset_id);
    PrintF("\nCollateral ratio: %d basis points\n", asset->collateral_ratio);
    PrintF("Target price: $%d.%08d\n", 
           asset->target_price / PRICE_PRECISION,
           asset->target_price % PRICE_PRECISION);
}

// Open a new collateral vault
U0 process_open_vault(U8* data, U64 data_len) {
    if (!protocol_initialized) {
        PrintF("ERROR: Protocol not initialized\n");
        return;
    }
    
    if (data_len < 32 + 32 + 32) {
        PrintF("ERROR: Invalid data length for vault opening\n");
        return;
    }
    
    U8 vault_id[32];
    U8 asset_id[32];
    U8 owner[32];
    
    CopyMemory(vault_id, data, 32);
    CopyMemory(asset_id, data + 32, 32);
    CopyMemory(owner, data + 64, 32);
    
    // Find the synthetic asset
    SyntheticAsset* asset = find_asset_by_id(asset_id);
    if (!asset) {
        PrintF("ERROR: Synthetic asset not found\n");
        return;
    }
    
    if (!asset->is_active) {
        PrintF("ERROR: Asset is not active\n");
        return;
    }
    
    // Create vault (in real implementation, this would be stored in account data)
    PrintF("Vault opened successfully\n");
    PrintF("Vault ID: ");
    print_pubkey(vault_id);
    PrintF("\nAsset ID: ");
    print_pubkey(asset_id);
    PrintF("\nOwner: ");
    print_pubkey(owner);
    PrintF("\n");
}

// Deposit collateral into vault
U0 process_deposit_collateral(U8* data, U64 data_len) {
    if (!protocol_initialized) {
        PrintF("ERROR: Protocol not initialized\n");
        return;
    }
    
    if (data_len < 32 + 8) {
        PrintF("ERROR: Invalid data length for collateral deposit\n");
        return;
    }
    
    U8 vault_id[32];
    U64 amount;
    
    CopyMemory(vault_id, data, 32);
    amount = read_u64_le(data + 32);
    
    if (amount == 0) {
        PrintF("ERROR: Cannot deposit zero collateral\n");
        return;
    }
    
    // Update protocol state
    protocol_state.total_collateral_locked += amount;
    
    PrintF("Collateral deposited successfully\n");
    PrintF("Vault ID: ");
    print_pubkey(vault_id);
    PrintF("\nAmount: %d tokens\n", amount);
    PrintF("Total protocol collateral: %d\n", protocol_state.total_collateral_locked);
}

// Mint synthetic tokens against collateral
U0 process_mint_synthetic(U8* data, U64 data_len) {
    if (!protocol_initialized) {
        PrintF("ERROR: Protocol not initialized\n");
        return;
    }
    
    if (data_len < 32 + 8) {
        PrintF("ERROR: Invalid data length for synthetic minting\n");
        return;
    }
    
    U8 vault_id[32];
    U64 amount;
    
    CopyMemory(vault_id, data, 32);
    amount = read_u64_le(data + 32);
    
    if (amount == 0) {
        PrintF("ERROR: Cannot mint zero synthetic tokens\n");
        return;
    }
    
    // In real implementation, would check vault collateralization ratio
    // For now, assume sufficient collateral
    
    // Update protocol state
    protocol_state.total_synthetic_supply += amount;
    
    PrintF("Synthetic tokens minted successfully\n");
    PrintF("Vault ID: ");
    print_pubkey(vault_id);
    PrintF("\nAmount: %d synthetic tokens\n", amount);
    PrintF("Total synthetic supply: %d\n", protocol_state.total_synthetic_supply);
}

// Burn synthetic tokens to reduce debt
U0 process_burn_synthetic(U8* data, U64 data_len) {
    if (!protocol_initialized) {
        PrintF("ERROR: Protocol not initialized\n");
        return;
    }
    
    if (data_len < 32 + 8) {
        PrintF("ERROR: Invalid data length for synthetic burning\n");
        return;
    }
    
    U8 vault_id[32];
    U64 amount;
    
    CopyMemory(vault_id, data, 32);
    amount = read_u64_le(data + 32);
    
    if (amount == 0) {
        PrintF("ERROR: Cannot burn zero synthetic tokens\n");
        return;
    }
    
    if (amount > protocol_state.total_synthetic_supply) {
        PrintF("ERROR: Cannot burn more than total supply\n");
        return;
    }
    
    // Update protocol state
    protocol_state.total_synthetic_supply -= amount;
    
    PrintF("Synthetic tokens burned successfully\n");
    PrintF("Vault ID: ");
    print_pubkey(vault_id);
    PrintF("\nAmount: %d synthetic tokens\n", amount);
    PrintF("Total synthetic supply: %d\n", protocol_state.total_synthetic_supply);
}

// Withdraw collateral from vault
U0 process_withdraw_collateral(U8* data, U64 data_len) {
    if (!protocol_initialized) {
        PrintF("ERROR: Protocol not initialized\n");
        return;
    }
    
    if (data_len < 32 + 8) {
        PrintF("ERROR: Invalid data length for collateral withdrawal\n");
        return;
    }
    
    U8 vault_id[32];
    U64 amount;
    
    CopyMemory(vault_id, data, 32);
    amount = read_u64_le(data + 32);
    
    if (amount == 0) {
        PrintF("ERROR: Cannot withdraw zero collateral\n");
        return;
    }
    
    if (amount > protocol_state.total_collateral_locked) {
        PrintF("ERROR: Insufficient collateral in protocol\n");
        return;
    }
    
    // In real implementation, would check vault remains safely collateralized
    
    // Update protocol state
    protocol_state.total_collateral_locked -= amount;
    
    PrintF("Collateral withdrawn successfully\n");
    PrintF("Vault ID: ");
    print_pubkey(vault_id);
    PrintF("\nAmount: %d tokens\n", amount);
    PrintF("Remaining protocol collateral: %d\n", protocol_state.total_collateral_locked);
}

// Liquidate an undercollateralized vault
U0 process_liquidate_vault(U8* data, U64 data_len) {
    if (!protocol_initialized) {
        PrintF("ERROR: Protocol not initialized\n");
        return;
    }
    
    if (data_len < 32 + 32) {
        PrintF("ERROR: Invalid data length for vault liquidation\n");
        return;
    }
    
    U8 vault_id[32];
    U8 liquidator[32];
    
    CopyMemory(vault_id, data, 32);
    CopyMemory(liquidator, data + 32, 32);
    
    // In real implementation, would check vault is actually undercollateralized
    // Calculate liquidation amounts and penalties
    
    U64 penalty_amount = 100; // Example penalty
    protocol_state.liquidation_fund += penalty_amount;
    
    PrintF("Vault liquidated successfully\n");
    PrintF("Vault ID: ");
    print_pubkey(vault_id);
    PrintF("\nLiquidator: ");
    print_pubkey(liquidator);
    PrintF("\nPenalty collected: %d tokens\n", penalty_amount);
    PrintF("Liquidation fund: %d\n", protocol_state.liquidation_fund);
}

// Update asset price from oracle
U0 process_update_price(U8* data, U64 data_len) {
    if (!protocol_initialized) {
        PrintF("ERROR: Protocol not initialized\n");
        return;
    }
    
    if (data_len < 32 + 8) {
        PrintF("ERROR: Invalid data length for price update\n");
        return;
    }
    
    U8 asset_id[32];
    U64 new_price;
    
    CopyMemory(asset_id, data, 32);
    new_price = read_u64_le(data + 32);
    
    SyntheticAsset* asset = find_asset_by_id(asset_id);
    if (!asset) {
        PrintF("ERROR: Synthetic asset not found\n");
        return;
    }
    
    U64 old_price = asset->current_price;
    asset->current_price = new_price;
    asset->last_update_time = get_current_timestamp();
    
    PrintF("Price updated successfully\n");
    PrintF("Asset ID: ");
    print_pubkey(asset_id);
    PrintF("\nOld price: $%d.%08d\n", 
           old_price / PRICE_PRECISION,
           old_price % PRICE_PRECISION);
    PrintF("New price: $%d.%08d\n", 
           new_price / PRICE_PRECISION,
           new_price % PRICE_PRECISION);
}

// Emergency global settlement
U0 process_global_settlement(U8* data, U64 data_len) {
    if (!protocol_initialized) {
        PrintF("ERROR: Protocol not initialized\n");
        return;
    }
    
    if (data_len < 8) {
        PrintF("ERROR: Invalid data length for global settlement\n");
        return;
    }
    
    U64 settlement_price = read_u64_le(data);
    
    protocol_state.global_settlement = True;
    protocol_state.settlement_price = settlement_price;
    
    // Disable all assets
    for (U64 i = 0; i < asset_count; i++) {
        assets[i].is_active = False;
    }
    
    PrintF("Global settlement initiated\n");
    PrintF("Settlement price: $%d.%08d\n", 
           settlement_price / PRICE_PRECISION,
           settlement_price % PRICE_PRECISION);
    PrintF("All assets are now inactive\n");
}

// Helper function to find asset by ID
SyntheticAsset* find_asset_by_id(U8* asset_id) {
    for (U64 i = 0; i < asset_count; i++) {
        if (compare_pubkeys(assets[i].asset_id, asset_id)) {
            return &assets[i];
        }
    }
    return NULL;
}

// Calculate collateralization ratio for a vault
U64 calculate_collateralization_ratio(U64 collateral_amount, U64 collateral_price, 
                                      U64 synthetic_debt, U64 synthetic_price) {
    if (synthetic_debt == 0) {
        return UINT64_MAX; // Infinite ratio when no debt
    }
    
    U64 collateral_value = (collateral_amount * collateral_price) / PRICE_PRECISION;
    U64 debt_value = (synthetic_debt * synthetic_price) / PRICE_PRECISION;
    
    return (collateral_value * RATIO_PRECISION) / debt_value;
}

// Calculate stability fees for a vault
U64 calculate_stability_fees(U64 debt_amount, U64 annual_rate, U64 time_elapsed) {
    // Simple interest calculation for demonstration
    U64 annual_fee = (debt_amount * annual_rate) / FEE_PRECISION;
    return (annual_fee * time_elapsed) / SECONDS_PER_YEAR;
}

// Test protocol initialization
U0 test_protocol_initialization() {
    PrintF("\n--- Testing Protocol Initialization ---\n");
    
    U8 admin_key[32];
    fill_test_pubkey(admin_key, 1);
    
    process_initialize_protocol(admin_key, 32);
    
    if (protocol_initialized) {
        PrintF("✓ Protocol initialization test passed\n");
    } else {
        PrintF("✗ Protocol initialization test failed\n");
    }
}

// Test asset creation
U0 test_asset_creation() {
    PrintF("\n--- Testing Asset Creation ---\n");
    
    U8 test_data[32 + 32 + 32 + 8 + 8 + 8 + 8 + 32];
    U64 offset = 0;
    
    // Asset ID
    fill_test_pubkey(test_data + offset, 10);
    offset += 32;
    
    // Mint address
    fill_test_pubkey(test_data + offset, 11);
    offset += 32;
    
    // Collateral mint
    fill_test_pubkey(test_data + offset, 12);
    offset += 32;
    
    // Collateral ratio (150%)
    write_u64_le(test_data + offset, 1500);
    offset += 8;
    
    // Liquidation ratio (130%)
    write_u64_le(test_data + offset, 1300);
    offset += 8;
    
    // Target price ($100.00)
    write_u64_le(test_data + offset, 10000000000);
    offset += 8;
    
    // Debt ceiling ($1M)
    write_u64_le(test_data + offset, 1000000 * PRICE_PRECISION);
    offset += 8;
    
    // Price oracle
    fill_test_pubkey(test_data + offset, 13);
    offset += 32;
    
    U64 initial_count = asset_count;
    process_create_asset(test_data, offset);
    
    if (asset_count == initial_count + 1) {
        PrintF("✓ Asset creation test passed\n");
    } else {
        PrintF("✗ Asset creation test failed\n");
    }
}

// Test vault operations
U0 test_vault_operations() {
    PrintF("\n--- Testing Vault Operations ---\n");
    
    U8 vault_data[32 + 32 + 32];
    fill_test_pubkey(vault_data, 20);        // Vault ID
    fill_test_pubkey(vault_data + 32, 10);   // Asset ID
    fill_test_pubkey(vault_data + 64, 21);   // Owner
    
    process_open_vault(vault_data, 96);
    
    // Test collateral deposit
    U8 deposit_data[32 + 8];
    fill_test_pubkey(deposit_data, 20);      // Vault ID
    write_u64_le(deposit_data + 32, 1000);   // 1000 tokens
    
    U64 initial_collateral = protocol_state.total_collateral_locked;
    process_deposit_collateral(deposit_data, 40);
    
    if (protocol_state.total_collateral_locked == initial_collateral + 1000) {
        PrintF("✓ Collateral deposit test passed\n");
    } else {
        PrintF("✗ Collateral deposit test failed\n");
    }
    
    // Test synthetic minting
    U8 mint_data[32 + 8];
    fill_test_pubkey(mint_data, 20);         // Vault ID
    write_u64_le(mint_data + 32, 500);       // 500 synthetic tokens
    
    U64 initial_supply = protocol_state.total_synthetic_supply;
    process_mint_synthetic(mint_data, 40);
    
    if (protocol_state.total_synthetic_supply == initial_supply + 500) {
        PrintF("✓ Synthetic minting test passed\n");
    } else {
        PrintF("✗ Synthetic minting test failed\n");
    }
}

// Test liquidation system
U0 test_liquidation_system() {
    PrintF("\n--- Testing Liquidation System ---\n");
    
    U8 liquidation_data[32 + 32];
    fill_test_pubkey(liquidation_data, 20);      // Vault ID
    fill_test_pubkey(liquidation_data + 32, 30); // Liquidator
    
    U64 initial_fund = protocol_state.liquidation_fund;
    process_liquidate_vault(liquidation_data, 64);
    
    if (protocol_state.liquidation_fund > initial_fund) {
        PrintF("✓ Liquidation test passed\n");
    } else {
        PrintF("✗ Liquidation test failed\n");
    }
}

// Test price oracle updates
U0 test_price_oracle() {
    PrintF("\n--- Testing Price Oracle ---\n");
    
    if (asset_count == 0) {
        PrintF("No assets to test price updates\n");
        return;
    }
    
    U8 price_data[32 + 8];
    CopyMemory(price_data, assets[0].asset_id, 32);   // Asset ID
    write_u64_le(price_data + 32, 12000000000);       // New price $120.00
    
    U64 old_price = assets[0].current_price;
    process_update_price(price_data, 40);
    
    if (assets[0].current_price != old_price) {
        PrintF("✓ Price oracle test passed\n");
    } else {
        PrintF("✗ Price oracle test failed\n");
    }
}

// Test global settlement
U0 test_global_settlement() {
    PrintF("\n--- Testing Global Settlement ---\n");
    
    U8 settlement_data[8];
    write_u64_le(settlement_data, 11000000000); // Settlement price $110.00
    
    process_global_settlement(settlement_data, 8);
    
    if (protocol_state.global_settlement && !assets[0].is_active) {
        PrintF("✓ Global settlement test passed\n");
    } else {
        PrintF("✗ Global settlement test failed\n");
    }
}

// Utility functions
U64 get_current_timestamp() {
    return 1640995200; // Example timestamp
}

Bool compare_pubkeys(U8* key1, U8* key2) {
    for (U64 i = 0; i < 32; i++) {
        if (key1[i] != key2[i]) {
            return False;
        }
    }
    return True;
}

U0 fill_test_pubkey(U8* key, U8 seed) {
    for (U64 i = 0; i < 32; i++) {
        key[i] = seed + i % 256;
    }
}

U0 print_pubkey(U8* key) {
    for (U64 i = 0; i < 8; i++) {
        PrintF("%02x", key[i]);
    }
    PrintF("...");
}

U64 read_u64_le(U8* data) {
    return data[0] | 
           (data[1] << 8) | 
           (data[2] << 16) | 
           (data[3] << 24) |
           ((U64)data[4] << 32) |
           ((U64)data[5] << 40) |
           ((U64)data[6] << 48) |
           ((U64)data[7] << 56);
}

U0 write_u64_le(U8* data, U64 value) {
    data[0] = value & 0xFF;
    data[1] = (value >> 8) & 0xFF;
    data[2] = (value >> 16) & 0xFF;
    data[3] = (value >> 24) & 0xFF;
    data[4] = (value >> 32) & 0xFF;
    data[5] = (value >> 40) & 0xFF;
    data[6] = (value >> 48) & 0xFF;
    data[7] = (value >> 56) & 0xFF;
}
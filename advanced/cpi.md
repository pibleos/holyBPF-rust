---
layout: doc
title: Cross-Program Invocation (CPI)
description: Learn to compose programs together using secure cross-program calls
---

# Advanced Topics

This section covers advanced concepts and techniques for developing sophisticated Solana programs using HolyC.

## Cross-Program Invocation (CPI)

### Understanding CPI

Cross-Program Invocation allows your program to call functions in other Solana programs, enabling composability and integration with the broader Solana ecosystem.

### Basic CPI Pattern

```c
// CPI instruction structure
struct CpiInstruction {
    U8[32] program_id;         // Target program to invoke
    U64 account_count;         // Number of accounts
    U8 accounts[][32];         // Account public keys
    U64 data_length;           // Instruction data length
    U8* instruction_data;      // Instruction data
};

// Execute CPI call
U0 invoke_external_program(
    U8* program_id,
    U8 accounts[][32],
    U64 account_count,
    U8* instruction_data,
    U64 data_length
) {
    PrintF("Invoking external program: %s\n", encode_base58(program_id));
    PrintF("Account count: %d\n", account_count);
    PrintF("Data length: %d\n", data_length);
    
    // In actual implementation, this would execute the CPI
    // sol_invoke() system call would be used here
    
    PrintF("CPI call completed\n");
}
```

### Token Program Integration

```c
// Call SPL Token program for transfers
U0 cpi_token_transfer(
    U8* token_program_id,
    U8* source_account,
    U8* destination_account,
    U8* authority,
    U64 amount
) {
    // Prepare instruction data for SPL Token transfer
    U8 transfer_instruction[9];
    transfer_instruction[0] = 3; // Transfer instruction discriminator
    *(U64*)(transfer_instruction + 1) = amount;
    
    // Prepare accounts array
    U8 accounts[3][32];
    copy_pubkey(accounts[0], source_account);      // Source token account
    copy_pubkey(accounts[1], destination_account); // Destination token account
    copy_pubkey(accounts[2], authority);           // Transfer authority
    
    // Execute CPI
    invoke_external_program(
        token_program_id,
        accounts,
        3,
        transfer_instruction,
        9
    );
    
    PrintF("Token transfer CPI executed: %d tokens\n", amount);
}
```

### Associated Token Account Creation

```c
// Create Associated Token Account via CPI
U0 cpi_create_ata(
    U8* ata_program_id,
    U8* funding_account,
    U8* wallet_address,
    U8* token_mint
) {
    PrintF("Creating ATA for wallet: %s\n", encode_base58(wallet_address));
    PrintF("Token mint: %s\n", encode_base58(token_mint));
    
    // ATA programs don't require instruction data for creation
    U8 accounts[7][32];
    copy_pubkey(accounts[0], funding_account); // Funding account
    copy_pubkey(accounts[1], wallet_address);  // Wallet address
    copy_pubkey(accounts[2], token_mint);      // Token mint
    // Additional system accounts would be included here
    
    invoke_external_program(
        ata_program_id,
        accounts,
        7,
        0, // No instruction data
        0
    );
    
    PrintF("ATA creation CPI completed\n");
}
```

## Program Derived Addresses (PDAs)

### PDA Generation

```c
// Generate PDA with multiple seeds
U0 find_program_address_with_seeds(
    U8* address_out,
    U8* bump_out,
    U8* program_id,
    U8** seeds,
    U64* seed_lengths,
    U64 seed_count
) {
    // Simplified PDA derivation
    // Real implementation would use SHA256 and curve validation
    
    U8 combined_hash = 0;
    
    // Combine all seeds
    for (U64 i = 0; i < seed_count; i++) {
        for (U64 j = 0; j < seed_lengths[i]; j++) {
            combined_hash ^= seeds[i][j];
        }
    }
    
    // Add program ID to hash
    for (U64 i = 0; i < 32; i++) {
        combined_hash ^= program_id[i];
    }
    
    // Generate deterministic address
    for (U64 i = 0; i < 32; i++) {
        address_out[i] = combined_hash + i;
    }
    
    *bump_out = 255; // Bump seed
    
    PrintF("Generated PDA with %d seeds\n", seed_count);
}

// Create market PDA
U0 get_market_pda(U8* market_address, U8* base_mint, U8* quote_mint) {
    U8* seeds[3];
    U64 seed_lengths[3];
    U8 market_seed[] = "market";
    
    seeds[0] = market_seed;
    seeds[1] = base_mint;
    seeds[2] = quote_mint;
    
    seed_lengths[0] = 6; // "market"
    seed_lengths[1] = 32; // base mint
    seed_lengths[2] = 32; // quote mint
    
    U8 bump;
    find_program_address_with_seeds(
        market_address,
        &bump,
        get_program_id(),
        seeds,
        seed_lengths,
        3
    );
    
    PrintF("Market PDA: %s\n", encode_base58(market_address));
}
```

### User Position PDAs

```c
// Generate user position PDA
U0 get_user_position_pda(U8* position_address, U8* market, U8* user) {
    U8* seeds[3];
    U64 seed_lengths[3];
    U8 position_seed[] = "user_position";
    
    seeds[0] = position_seed;
    seeds[1] = market;
    seeds[2] = user;
    
    seed_lengths[0] = 13; // "user_position"
    seed_lengths[1] = 32; // market
    seed_lengths[2] = 32; // user
    
    U8 bump;
    find_program_address_with_seeds(
        position_address,
        &bump,
        get_program_id(),
        seeds,
        seed_lengths,
        3
    );
}
```

## Security Best Practices

### Signer Validation

```c
// Comprehensive signer validation
Bool validate_signer_authority(U8* expected_signer, U8* provided_signer) {
    if (!validate_pubkey_not_zero(expected_signer)) {
        PrintF("ERROR: Invalid expected signer\n");
        return False;
    }
    
    if (!validate_pubkey_not_zero(provided_signer)) {
        PrintF("ERROR: Invalid provided signer\n");
        return False;
    }
    
    if (!compare_pubkeys(expected_signer, provided_signer)) {
        PrintF("ERROR: Signer mismatch\n");
        PrintF("Expected: %s\n", encode_base58(expected_signer));
        PrintF("Provided: %s\n", encode_base58(provided_signer));
        return False;
    }
    
    // Additional checks for signer privileges would go here
    return True;
}
```

### Account Ownership Validation

```c
// Validate account ownership
Bool validate_account_owner(U8* account, U8* expected_owner) {
    U8* actual_owner = get_account_owner(account);
    
    if (!actual_owner) {
        PrintF("ERROR: Could not determine account owner\n");
        return False;
    }
    
    if (!compare_pubkeys(actual_owner, expected_owner)) {
        PrintF("ERROR: Account owner mismatch\n");
        PrintF("Expected: %s\n", encode_base58(expected_owner));
        PrintF("Actual: %s\n", encode_base58(actual_owner));
        return False;
    }
    
    return True;
}
```

### Integer Overflow Protection

```c
// Safe arithmetic operations with overflow checks
struct SafeMathResult {
    Bool success;
    U64 value;
};

SafeMathResult safe_add_u64(U64 a, U64 b) {
    SafeMathResult result;
    
    if (a > U64_MAX - b) {
        PrintF("ERROR: Addition overflow: %d + %d\n", a, b);
        result.success = False;
        result.value = 0;
        return result;
    }
    
    result.success = True;
    result.value = a + b;
    return result;
}

SafeMathResult safe_multiply_u64(U64 a, U64 b) {
    SafeMathResult result;
    
    if (a == 0 || b == 0) {
        result.success = True;
        result.value = 0;
        return result;
    }
    
    if (a > U64_MAX / b) {
        PrintF("ERROR: Multiplication overflow: %d * %d\n", a, b);
        result.success = False;
        result.value = 0;
        return result;
    }
    
    result.success = True;
    result.value = a * b;
    return result;
}

// Safe percentage calculation
SafeMathResult safe_percentage(U64 amount, U64 percentage_bp) {
    // percentage_bp is in basis points (1/10000)
    if (percentage_bp > 10000) {
        PrintF("ERROR: Percentage exceeds 100%%\n");
        SafeMathResult result = {False, 0};
        return result;
    }
    
    return safe_multiply_u64(amount, percentage_bp);
}
```

## Performance Optimization

### Compute Unit Management

```c
// Estimate compute units for operations
U64 estimate_compute_units(U8 operation_type, U64 data_size) {
    switch (operation_type) {
        case 0: // Simple arithmetic
            return 100;
        case 1: // Array operations
            return 50 + (data_size / 8); // 50 base + 1 per 8 bytes
        case 2: // Cryptographic operations
            return 1000;
        case 3: // CPI calls
            return 2000;
        default:
            return 500; // Default estimate
    }
}

// Optimize loop operations
U0 optimized_array_processing(U8* data, U64 length) {
    const U64 BATCH_SIZE = 256; // Process in batches
    
    for (U64 i = 0; i < length; i += BATCH_SIZE) {
        U64 batch_end = min_u64(i + BATCH_SIZE, length);
        
        // Process batch
        process_data_batch(data + i, batch_end - i);
        
        // Optional: yield control periodically for large datasets
        if (i % (BATCH_SIZE * 10) == 0) {
            PrintF("Processed %d/%d bytes\n", i, length);
        }
    }
}
```

### Memory Layout Optimization

```c
// Optimized struct layout for cache efficiency
struct OptimizedAccount {
    // Group frequently accessed fields together
    U8 is_initialized;     // 1 byte
    U8 account_type;       // 1 byte
    U8 reserved[6];        // Pad to 8-byte boundary
    
    U64 amount;            // 8 bytes, aligned
    U64 last_update_slot;  // 8 bytes, aligned
    
    U8[32] owner;          // 32 bytes
    U8[32] mint;           // 32 bytes
    
    // Less frequently accessed fields at the end
    U64 delegated_amount;  // 8 bytes
    U8[32] delegate;       // 32 bytes
};

// Batch account updates to minimize writes
U0 batch_account_updates(OptimizedAccount* accounts, U64 count) {
    // Collect all changes first
    for (U64 i = 0; i < count; i++) {
        calculate_account_changes(&accounts[i]);
    }
    
    // Apply all changes in a single pass
    for (U64 i = 0; i < count; i++) {
        apply_account_changes(&accounts[i]);
    }
    
    PrintF("Batch updated %d accounts\n", count);
}
```

### Data Structure Optimization

```c
// Use bit fields for flags to save space
struct CompactFlags {
    U8 flags; // 8 boolean flags in 1 byte
};

Bool get_flag(CompactFlags* flags, U8 flag_index) {
    if (flag_index >= 8) return False;
    return (flags->flags & (1 << flag_index)) != 0;
}

U0 set_flag(CompactFlags* flags, U8 flag_index, Bool value) {
    if (flag_index >= 8) return;
    
    if (value) {
        flags->flags |= (1 << flag_index);
    } else {
        flags->flags &= ~(1 << flag_index);
    }
}

// Pack multiple small values into single integers
struct PackedData {
    U64 packed; // Contains multiple values
};

U0 pack_values(PackedData* data, U16 val1, U16 val2, U32 val3) {
    data->packed = ((U64)val1 << 48) | ((U64)val2 << 32) | val3;
}

U0 unpack_values(PackedData* data, U16* val1, U16* val2, U32* val3) {
    *val1 = (data->packed >> 48) & 0xFFFF;
    *val2 = (data->packed >> 32) & 0xFFFF;
    *val3 = data->packed & 0xFFFFFFFF;
}
```

## Error Recovery and Rollback

### Transaction State Management

```c
// Transaction state for rollback capability
struct TransactionState {
    Bool in_transaction;
    U64 checkpoint_count;
    U8 checkpoint_data[10][1024]; // Store up to 10 checkpoints
};

static TransactionState tx_state = {False, 0};

U0 begin_transaction() {
    if (tx_state.in_transaction) {
        PrintF("ERROR: Already in transaction\n");
        return;
    }
    
    tx_state.in_transaction = True;
    tx_state.checkpoint_count = 0;
    
    PrintF("Transaction started\n");
}

U0 create_checkpoint(U8* data, U64 size) {
    if (!tx_state.in_transaction) {
        PrintF("ERROR: No active transaction\n");
        return;
    }
    
    if (tx_state.checkpoint_count >= 10) {
        PrintF("ERROR: Maximum checkpoints reached\n");
        return;
    }
    
    if (size > 1024) {
        PrintF("ERROR: Checkpoint data too large\n");
        return;
    }
    
    // Store checkpoint
    copy_array(tx_state.checkpoint_data[tx_state.checkpoint_count], data, size);
    tx_state.checkpoint_count++;
    
    PrintF("Checkpoint %d created\n", tx_state.checkpoint_count - 1);
}

U0 rollback_to_checkpoint(U64 checkpoint_index, U8* data_out) {
    if (!tx_state.in_transaction) {
        PrintF("ERROR: No active transaction\n");
        return;
    }
    
    if (checkpoint_index >= tx_state.checkpoint_count) {
        PrintF("ERROR: Invalid checkpoint index\n");
        return;
    }
    
    // Restore data from checkpoint
    copy_array(data_out, tx_state.checkpoint_data[checkpoint_index], 1024);
    
    // Remove later checkpoints
    tx_state.checkpoint_count = checkpoint_index + 1;
    
    PrintF("Rolled back to checkpoint %d\n", checkpoint_index);
}

U0 commit_transaction() {
    if (!tx_state.in_transaction) {
        PrintF("ERROR: No active transaction\n");
        return;
    }
    
    tx_state.in_transaction = False;
    tx_state.checkpoint_count = 0;
    
    PrintF("Transaction committed\n");
}
```

### Graceful Error Recovery

```c
// Attempt operation with fallback
Bool try_operation_with_fallback(U8* primary_data, U8* fallback_data) {
    // Try primary operation
    if (attempt_primary_operation(primary_data)) {
        PrintF("Primary operation succeeded\n");
        return True;
    }
    
    PrintF("Primary operation failed, trying fallback\n");
    
    // Try fallback operation
    if (attempt_fallback_operation(fallback_data)) {
        PrintF("Fallback operation succeeded\n");
        return True;
    }
    
    PrintF("Both primary and fallback operations failed\n");
    return False;
}
```

These advanced topics provide the foundation for building production-ready, secure, and performant Solana programs using HolyC. Proper understanding and implementation of these concepts is essential for enterprise-grade DeFi applications.
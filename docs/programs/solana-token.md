# Solana Token Operations in HolyC

This guide covers comprehensive token operations on Solana using HolyC. It demonstrates minting, transferring, burning, and managing SPL tokens with proper validation and security measures.

## Overview

Solana token operations provide the foundation for most DeFi applications. This guide covers creating token mints, managing supply, implementing transfers, and handling advanced token features like freeze authority and metadata.

### Key Concepts

**Token Mint**: The master account that defines a token and controls its supply.

**Token Account**: Individual accounts that hold tokens for specific users.

**Transfer Authority**: Permission system for moving tokens between accounts.

**Freeze Authority**: Ability to freeze token accounts and prevent transfers.

**Mint Authority**: Permission to create new tokens and increase supply.

**Associated Token Account**: Deterministic token account addresses derived from user wallet.

## Token Architecture

### Account Structure

```c
// Token mint configuration
struct TokenMint {
    U8[32] mint_address;          // Mint account address
    U8[32] mint_authority;        // Authority that can mint tokens
    U8[32] freeze_authority;      // Authority that can freeze accounts
    U64 total_supply;             // Total tokens in circulation
    U8 decimals;                  // Number of decimal places
    Bool is_initialized;          // Whether mint is initialized
    Bool is_frozen;               // Whether all accounts are frozen
    U8[64] name;                  // Token name
    U8[8] symbol;                 // Token symbol
};

// Individual token account
struct TokenAccount {
    U8[32] account_address;       // Token account address
    U8[32] owner;                 // Account owner
    U8[32] mint;                  // Token mint this account holds
    U64 amount;                   // Token balance
    U8[32] delegate;              // Delegated transfer authority
    U64 delegated_amount;         // Amount delegated
    Bool is_initialized;          // Whether account is initialized
    Bool is_frozen;               // Whether account is frozen
    Bool is_native;               // Whether this is a native SOL account
};

// Token transfer record
struct TokenTransfer {
    U8[32] transfer_id;           // Unique transfer identifier
    U8[32] from_account;          // Source token account
    U8[32] to_account;            // Destination token account
    U8[32] authority;             // Transfer authority (owner or delegate)
    U64 amount;                   // Amount transferred
    U64 timestamp;                // Transfer timestamp
    U8[256] memo;                 // Optional transfer memo
};
```

## Implementation Guide

### Token Mint Creation

```c
U0 create_token_mint(
    U8* mint_authority,
    U8* freeze_authority,
    U8 decimals,
    U8* token_name,
    U8* token_symbol
) {
    if (decimals > 9) {
        PrintF("ERROR: Maximum 9 decimal places allowed\n");
        return;
    }
    
    if (string_length(token_name) == 0 || string_length(token_name) > 64) {
        PrintF("ERROR: Invalid token name length\n");
        return;
    }
    
    if (string_length(token_symbol) == 0 || string_length(token_symbol) > 8) {
        PrintF("ERROR: Invalid token symbol length\n");
        return;
    }
    
    // Validate authorities
    if (!validate_pubkey_not_zero(mint_authority)) {
        PrintF("ERROR: Invalid mint authority\n");
        return;
    }
    
    // Generate new mint address
    U8[32] mint_address;
    generate_mint_address(mint_address);
    
    // Check if mint already exists
    if (mint_exists(mint_address)) {
        PrintF("ERROR: Mint already exists\n");
        return;
    }
    
    // Create token mint
    TokenMint* mint = get_token_mint_account(mint_address);
    copy_pubkey(mint->mint_address, mint_address);
    copy_pubkey(mint->mint_authority, mint_authority);
    
    if (freeze_authority) {
        copy_pubkey(mint->freeze_authority, freeze_authority);
    } else {
        // Set freeze authority to zero (no freeze capability)
        for (U8 i = 0; i < 32; i++) {
            mint->freeze_authority[i] = 0;
        }
    }
    
    mint->total_supply = 0;
    mint->decimals = decimals;
    mint->is_initialized = True;
    mint->is_frozen = False;
    copy_string(mint->name, token_name, 64);
    copy_string(mint->symbol, token_symbol, 8);
    
    PrintF("Token mint created successfully\n");
    PrintF("Mint address: %s\n", encode_base58(mint_address));
    PrintF("Name: %s\n", token_name);
    PrintF("Symbol: %s\n", token_symbol);
    PrintF("Decimals: %d\n", decimals);
    PrintF("Mint authority: %s\n", encode_base58(mint_authority));
    
    emit_mint_created_event(mint_address, get_current_user(), token_name, token_symbol);
}
```

### Token Account Management

```c
U0 create_token_account(U8* mint_address, U8* owner) {
    TokenMint* mint = get_token_mint_account(mint_address);
    
    if (!mint || !mint->is_initialized) {
        PrintF("ERROR: Token mint not found or not initialized\n");
        return;
    }
    
    if (!validate_pubkey_not_zero(owner)) {
        PrintF("ERROR: Invalid owner address\n");
        return;
    }
    
    // Generate associated token account address
    U8[32] token_account_address;
    generate_associated_token_address(token_account_address, owner, mint_address);
    
    // Check if account already exists
    if (token_account_exists(token_account_address)) {
        PrintF("ERROR: Token account already exists\n");
        return;
    }
    
    // Create token account
    TokenAccount* account = get_token_account(token_account_address);
    copy_pubkey(account->account_address, token_account_address);
    copy_pubkey(account->owner, owner);
    copy_pubkey(account->mint, mint_address);
    
    account->amount = 0;
    // Initialize delegate to zero
    for (U8 i = 0; i < 32; i++) {
        account->delegate[i] = 0;
    }
    account->delegated_amount = 0;
    account->is_initialized = True;
    account->is_frozen = False;
    account->is_native = False;
    
    PrintF("Token account created successfully\n");
    PrintF("Account address: %s\n", encode_base58(token_account_address));
    PrintF("Owner: %s\n", encode_base58(owner));
    PrintF("Mint: %s\n", encode_base58(mint_address));
    
    emit_account_created_event(token_account_address, owner, mint_address);
}

U0 mint_tokens(U8* mint_address, U8* destination_account, U64 amount) {
    TokenMint* mint = get_token_mint_account(mint_address);
    TokenAccount* dest_account = get_token_account(destination_account);
    
    if (!mint || !mint->is_initialized) {
        PrintF("ERROR: Token mint not found\n");
        return;
    }
    
    if (!dest_account || !dest_account->is_initialized) {
        PrintF("ERROR: Destination account not found\n");
        return;
    }
    
    // Verify mint authority
    if (!compare_pubkeys(mint->mint_authority, get_current_user())) {
        PrintF("ERROR: Not authorized to mint tokens\n");
        return;
    }
    
    // Verify destination account matches mint
    if (!compare_pubkeys(dest_account->mint, mint_address)) {
        PrintF("ERROR: Account mint mismatch\n");
        return;
    }
    
    if (amount == 0) {
        PrintF("ERROR: Mint amount must be positive\n");
        return;
    }
    
    // Check for overflow
    if (dest_account->amount > U64_MAX - amount) {
        PrintF("ERROR: Amount would cause overflow\n");
        return;
    }
    
    if (mint->total_supply > U64_MAX - amount) {
        PrintF("ERROR: Total supply would overflow\n");
        return;
    }
    
    // Mint tokens
    dest_account->amount += amount;
    mint->total_supply += amount;
    
    PrintF("Tokens minted successfully\n");
    PrintF("Amount: %d\n", amount);
    PrintF("Destination: %s\n", encode_base58(destination_account));
    PrintF("New balance: %d\n", dest_account->amount);
    PrintF("New total supply: %d\n", mint->total_supply);
    
    emit_tokens_minted_event(mint_address, destination_account, amount);
}
```

### Token Transfers

```c
U0 transfer_tokens(
    U8* from_account,
    U8* to_account,
    U64 amount,
    U8* memo
) {
    TokenAccount* from = get_token_account(from_account);
    TokenAccount* to = get_token_account(to_account);
    
    if (!from || !from->is_initialized) {
        PrintF("ERROR: Source account not found\n");
        return;
    }
    
    if (!to || !to->is_initialized) {
        PrintF("ERROR: Destination account not found\n");
        return;
    }
    
    // Verify accounts are for the same mint
    if (!compare_pubkeys(from->mint, to->mint)) {
        PrintF("ERROR: Account mint mismatch\n");
        return;
    }
    
    // Check if accounts are frozen
    if (from->is_frozen || to->is_frozen) {
        PrintF("ERROR: Account is frozen\n");
        return;
    }
    
    // Verify transfer authority
    Bool has_authority = False;
    
    if (compare_pubkeys(from->owner, get_current_user())) {
        has_authority = True;
    } else {
        // Check if user is a delegate
        if (!is_zero_pubkey(from->delegate) && 
            compare_pubkeys(from->delegate, get_current_user()) &&
            amount <= from->delegated_amount) {
            has_authority = True;
        }
    }
    
    if (!has_authority) {
        PrintF("ERROR: Not authorized to transfer from this account\n");
        return;
    }
    
    if (amount == 0) {
        PrintF("ERROR: Transfer amount must be positive\n");
        return;
    }
    
    if (from->amount < amount) {
        PrintF("ERROR: Insufficient balance\n");
        PrintF("Available: %d, Requested: %d\n", from->amount, amount);
        return;
    }
    
    // Check for overflow in destination
    if (to->amount > U64_MAX - amount) {
        PrintF("ERROR: Transfer would cause overflow in destination\n");
        return;
    }
    
    // Execute transfer
    from->amount -= amount;
    to->amount += amount;
    
    // Update delegation if applicable
    if (!compare_pubkeys(from->owner, get_current_user())) {
        from->delegated_amount -= amount;
    }
    
    // Record transfer
    record_token_transfer(from_account, to_account, get_current_user(), amount, memo);
    
    PrintF("Tokens transferred successfully\n");
    PrintF("From: %s\n", encode_base58(from_account));
    PrintF("To: %s\n", encode_base58(to_account));
    PrintF("Amount: %d\n", amount);
    PrintF("From balance: %d\n", from->amount);
    PrintF("To balance: %d\n", to->amount);
    
    emit_transfer_event(from_account, to_account, get_current_user(), amount);
}

U0 burn_tokens(U8* token_account, U64 amount) {
    TokenAccount* account = get_token_account(token_account);
    TokenMint* mint = get_token_mint_account(account->mint);
    
    if (!account || !account->is_initialized) {
        PrintF("ERROR: Token account not found\n");
        return;
    }
    
    if (!mint || !mint->is_initialized) {
        PrintF("ERROR: Token mint not found\n");
        return;
    }
    
    // Verify burn authority (account owner)
    if (!compare_pubkeys(account->owner, get_current_user())) {
        PrintF("ERROR: Not authorized to burn from this account\n");
        return;
    }
    
    if (amount == 0) {
        PrintF("ERROR: Burn amount must be positive\n");
        return;
    }
    
    if (account->amount < amount) {
        PrintF("ERROR: Insufficient balance to burn\n");
        return;
    }
    
    // Burn tokens
    account->amount -= amount;
    mint->total_supply -= amount;
    
    PrintF("Tokens burned successfully\n");
    PrintF("Amount: %d\n", amount);
    PrintF("New balance: %d\n", account->amount);
    PrintF("New total supply: %d\n", mint->total_supply);
    
    emit_tokens_burned_event(account->mint, token_account, amount);
}
```

### Advanced Token Features

```c
U0 approve_delegate(U8* token_account, U8* delegate, U64 amount) {
    TokenAccount* account = get_token_account(token_account);
    
    if (!account || !account->is_initialized) {
        PrintF("ERROR: Token account not found\n");
        return;
    }
    
    // Only account owner can approve delegates
    if (!compare_pubkeys(account->owner, get_current_user())) {
        PrintF("ERROR: Only account owner can approve delegates\n");
        return;
    }
    
    if (!validate_pubkey_not_zero(delegate)) {
        PrintF("ERROR: Invalid delegate address\n");
        return;
    }
    
    if (amount > account->amount) {
        PrintF("ERROR: Cannot delegate more than account balance\n");
        return;
    }
    
    // Set delegate
    copy_pubkey(account->delegate, delegate);
    account->delegated_amount = amount;
    
    PrintF("Delegate approved successfully\n");
    PrintF("Delegate: %s\n", encode_base58(delegate));
    PrintF("Amount: %d\n", amount);
    
    emit_delegate_approved_event(token_account, delegate, amount);
}

U0 revoke_delegate(U8* token_account) {
    TokenAccount* account = get_token_account(token_account);
    
    if (!account || !account->is_initialized) {
        PrintF("ERROR: Token account not found\n");
        return;
    }
    
    // Only account owner can revoke delegates
    if (!compare_pubkeys(account->owner, get_current_user())) {
        PrintF("ERROR: Only account owner can revoke delegates\n");
        return;
    }
    
    // Clear delegate
    for (U8 i = 0; i < 32; i++) {
        account->delegate[i] = 0;
    }
    account->delegated_amount = 0;
    
    PrintF("Delegate revoked successfully\n");
    
    emit_delegate_revoked_event(token_account);
}

U0 freeze_token_account(U8* token_account) {
    TokenAccount* account = get_token_account(token_account);
    TokenMint* mint = get_token_mint_account(account->mint);
    
    if (!account || !account->is_initialized) {
        PrintF("ERROR: Token account not found\n");
        return;
    }
    
    if (!mint || !mint->is_initialized) {
        PrintF("ERROR: Token mint not found\n");
        return;
    }
    
    // Verify freeze authority
    if (is_zero_pubkey(mint->freeze_authority)) {
        PrintF("ERROR: No freeze authority set for this mint\n");
        return;
    }
    
    if (!compare_pubkeys(mint->freeze_authority, get_current_user())) {
        PrintF("ERROR: Not authorized to freeze accounts\n");
        return;
    }
    
    if (account->is_frozen) {
        PrintF("Account already frozen\n");
        return;
    }
    
    // Freeze account
    account->is_frozen = True;
    
    PrintF("Token account frozen successfully\n");
    PrintF("Account: %s\n", encode_base58(token_account));
    
    emit_account_frozen_event(token_account);
}

U0 thaw_token_account(U8* token_account) {
    TokenAccount* account = get_token_account(token_account);
    TokenMint* mint = get_token_mint_account(account->mint);
    
    if (!account || !account->is_initialized) {
        PrintF("ERROR: Token account not found\n");
        return;
    }
    
    if (!mint || !mint->is_initialized) {
        PrintF("ERROR: Token mint not found\n");
        return;
    }
    
    // Verify freeze authority
    if (!compare_pubkeys(mint->freeze_authority, get_current_user())) {
        PrintF("ERROR: Not authorized to thaw accounts\n");
        return;
    }
    
    if (!account->is_frozen) {
        PrintF("Account not frozen\n");
        return;
    }
    
    // Thaw account
    account->is_frozen = False;
    
    PrintF("Token account thawed successfully\n");
    PrintF("Account: %s\n", encode_base58(token_account));
    
    emit_account_thawed_event(token_account);
}
```

### Utility Functions

```c
U0 get_token_balance(U8* token_account, U64* balance) {
    TokenAccount* account = get_token_account(token_account);
    
    if (!account || !account->is_initialized) {
        *balance = 0;
        PrintF("Token account not found\n");
        return;
    }
    
    *balance = account->amount;
    PrintF("Token balance: %d\n", *balance);
}

U0 get_token_supply(U8* mint_address, U64* supply) {
    TokenMint* mint = get_token_mint_account(mint_address);
    
    if (!mint || !mint->is_initialized) {
        *supply = 0;
        PrintF("Token mint not found\n");
        return;
    }
    
    *supply = mint->total_supply;
    PrintF("Total supply: %d\n", *supply);
}

Bool is_zero_pubkey(U8* pubkey) {
    for (U8 i = 0; i < 32; i++) {
        if (pubkey[i] != 0) {
            return False;
        }
    }
    return True;
}

U0 record_token_transfer(
    U8* from_account,
    U8* to_account,
    U8* authority,
    U64 amount,
    U8* memo
) {
    // Generate transfer ID
    U8[32] transfer_id;
    generate_transfer_id(transfer_id, from_account, to_account, get_current_timestamp());
    
    // Create transfer record
    TokenTransfer* transfer = get_token_transfer_account(transfer_id);
    copy_pubkey(transfer->transfer_id, transfer_id);
    copy_pubkey(transfer->from_account, from_account);
    copy_pubkey(transfer->to_account, to_account);
    copy_pubkey(transfer->authority, authority);
    
    transfer->amount = amount;
    transfer->timestamp = get_current_timestamp();
    
    if (memo && string_length(memo) > 0) {
        copy_string(transfer->memo, memo, 256);
    }
}
```

This comprehensive token operations guide provides the foundation for implementing SPL token functionality with proper security, validation, and advanced features like delegation and freeze capabilities.
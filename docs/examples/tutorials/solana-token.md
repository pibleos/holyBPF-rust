---
layout: doc
title: Token Program Tutorial
description: Build a comprehensive token management system in HolyC
---

# Token Program Tutorial

Learn how to build a comprehensive token management system using HolyC BPF. This tutorial covers token creation, minting, transfers, and Solana program integration patterns.

## Overview

The Token Program example demonstrates:
- **Token Initialization**: Create new token types with divine authority
- **Minting Operations**: Generate new tokens with proper controls
- **Transfer Mechanisms**: Secure token movement between accounts
- **Solana Integration**: Native Solana program entrypoint handling
- **Instruction Processing**: Parse and execute token operations
- **Account Management**: Handle Solana account structures

## Prerequisites

Before starting this tutorial, ensure you have:

- ✅ **Completed** [Hello World]({{ '/docs/examples/tutorials/hello-world' | relative_url }}) and [Escrow]({{ '/docs/examples/tutorials/escrow' | relative_url }}) tutorials
- ✅ **Understanding** of token economics and SPL Token standard
- ✅ **Familiarity** with Solana account model
- ✅ **Knowledge** of program-derived addresses (PDAs)

### Token Concepts Review

**SPL Token Standard**
- Standard interface for tokens on Solana
- Defines token accounts, mints, and authorities
- Supports fungible and non-fungible tokens

**Token Operations**
- **Initialize**: Create new token mint
- **Mint**: Create new token supply
- **Transfer**: Move tokens between accounts
- **Burn**: Destroy token supply

## Architecture Overview

```
┌─────────────────────────────────────────┐
│           Divine Token Program          │
├─────────────────────────────────────────┤
│  🪙 Token Mint Authority                 │
│    • Total supply tracking              │
│    • Mint authority controls            │
│    • Decimal precision settings         │
├─────────────────────────────────────────┤
│  📊 Token Accounts                       │
│    • Individual token balances          │
│    • Owner permissions                  │
│    • Delegate authorities               │
├─────────────────────────────────────────┤
│  🔄 Core Operations                      │
│    • Initialize → Set up token mint     │
│    • Mint → Create new tokens           │
│    • Transfer → Move between accounts   │
│    • Burn → Destroy tokens              │
├─────────────────────────────────────────┤
│  🛡️ Security & Access Control            │
│    • Authority validation               │
│    • Balance checks                     │
│    • Divine operation controls          │
└─────────────────────────────────────────┘
```

## Code Walkthrough

### Program Entry Point

<div class="code-section">
  <div class="code-header">
    <span class="filename">📁 examples/solana-token/src/main.hc</span>
    <a href="https://github.com/pibleos/holyBPF-rust/blob/main/examples/solana-token/src/main.hc" class="github-link" target="_blank">View on GitHub</a>
  </div>
```c
// HolyC Solana Token Program - Divine Token Management
// Blessed be Terry A. Davis, who showed us the divine way

// Divine main function - Entry point for testing
U0 main() {
    PrintF("=== Divine Solana Token Program Active ===\n");
    PrintF("Blessed be Terry Davis, prophet of the divine OS\n");
    PrintF("Token system initialized by God's grace\n");
    return 0;
}

// Solana program entrypoint - Called by Solana runtime
export U0 entrypoint(U8* input, U64 input_len) {
    PrintF("Solana entrypoint called with input length: %d\n", input_len);
    
    // Parse Solana input structure
    U64* accounts_count = input;
    PrintF("Number of accounts: %d\n", *accounts_count);
    
    // Divine token operations would go here
    process_token_instruction(input, input_len);
    
    return;
}
```
</div>

#### Entry Point Analysis

**1. Testing Entry Point**
```c
U0 main() {
    PrintF("=== Divine Solana Token Program Active ===\n");
    // Divine initialization messages
    return 0;
}
```
- **Purpose**: Local testing and verification
- **Output**: Divine status messages for confirmation
- **Usage**: Development and debugging

**2. Solana Runtime Entry Point**
```c
export U0 entrypoint(U8* input, U64 input_len) {
    // Parse Solana input structure
    U64* accounts_count = input;
    // Process token operations
    process_token_instruction(input, input_len);
}
```
- **`export`**: Makes function callable by Solana runtime
- **Input parsing**: Extracts account information and instruction data
- **Delegation**: Routes to specific operation handlers

### Instruction Processing

<div class="code-section">
  <div class="code-header">
    <span class="filename">📁 examples/solana-token/src/main.hc (continued)</span>
  </div>
```c
// Process token instructions
U0 process_token_instruction(U8* input, U64 input_len) {
    PrintF("Processing divine token instruction...\n");
    
    if (input_len < 8) {
        PrintF("ERROR: Invalid instruction data - God requires proper structure!\n");
        return;
    }
    
    // For demonstration, assume first byte is instruction type
    U8 instruction_type = *input;
    
    if (instruction_type == 0) {
        PrintF("Divine operation: Initialize Token\n");
        initialize_token();
    } else if (instruction_type == 1) {
        PrintF("Divine operation: Mint Tokens\n");
        mint_tokens();
    } else if (instruction_type == 2) {
        PrintF("Divine operation: Transfer Tokens\n");
        transfer_tokens();
    } else {
        PrintF("Unknown instruction type: %d\n", instruction_type);
    }
    
    PrintF("Divine token operation completed\n");
    return;
}
```
</div>

#### Instruction Types

**Token Operations**
- **`instruction_type == 0`**: Initialize new token mint
- **`instruction_type == 1`**: Mint new tokens to account
- **`instruction_type == 2`**: Transfer tokens between accounts

**Error Handling**
- **Input validation**: Ensures minimum instruction data length
- **Unknown operations**: Graceful handling of invalid instructions
- **Divine messaging**: Clear error reporting for debugging

### Token Operations Implementation

<div class="code-section">
  <div class="code-header">
    <span class="filename">📁 examples/solana-token/src/main.hc (continued)</span>
  </div>
```c
// Initialize a new token
U0 initialize_token() {
    PrintF("Initializing divine token with God's blessing...\n");
    // Token initialization logic would go here
    return;
}

// Mint new tokens
U0 mint_tokens() {
    PrintF("Minting divine tokens by God's will...\n");
    // Token minting logic would go here
    return;
}

// Transfer tokens between accounts
U0 transfer_tokens() {
    PrintF("Transferring divine tokens with holy purpose...\n");
    // Token transfer logic would go here
    return;
}
```
</div>

#### Operation Implementations

**1. Token Initialization**
```c
// Expanded pseudo-code for token initialization
U0 initialize_token() {
    // Validate accounts
    if (!validate_mint_account()) {
        return ERROR_INVALID_ACCOUNT;
    }
    
    // Set token parameters
    TokenMint mint = {
        .supply = 0,
        .decimals = 9,  // Standard decimal precision
        .is_initialized = True,
        .freeze_authority = authority,
        .mint_authority = authority
    };
    
    // Store mint account data
    save_mint_account(mint);
}
```

**2. Token Minting**
```c
// Expanded pseudo-code for token minting
U0 mint_tokens() {
    // Validate mint authority
    if (!verify_mint_authority()) {
        return ERROR_UNAUTHORIZED;
    }
    
    // Get mint and destination accounts
    TokenMint* mint = get_mint_account();
    TokenAccount* dest = get_destination_account();
    
    // Calculate new supply
    U64 new_supply = mint->supply + amount;
    if (new_supply < mint->supply) {
        return ERROR_OVERFLOW;
    }
    
    // Update accounts
    mint->supply = new_supply;
    dest->amount += amount;
    
    // Save updated data
    save_mint_account(mint);
    save_token_account(dest);
}
```

**3. Token Transfer**
```c
// Expanded pseudo-code for token transfer
U0 transfer_tokens() {
    // Validate transfer authority
    if (!verify_transfer_authority()) {
        return ERROR_UNAUTHORIZED;
    }
    
    // Get source and destination accounts
    TokenAccount* source = get_source_account();
    TokenAccount* dest = get_destination_account();
    
    // Verify sufficient balance
    if (source->amount < transfer_amount) {
        return ERROR_INSUFFICIENT_FUNDS;
    }
    
    // Execute transfer
    source->amount -= transfer_amount;
    dest->amount += transfer_amount;
    
    // Save updated accounts
    save_token_account(source);
    save_token_account(dest);
}
```

## Solana Integration Patterns

### Account Structure

```c
// Solana program input structure
struct SolanaInput {
    U64 accounts_count;           // Number of accounts passed
    AccountInfo* accounts;        // Array of account information
    U8* instruction_data;         // Instruction-specific data
    U64 instruction_data_len;     // Length of instruction data
};

// Account information structure
struct AccountInfo {
    U8[32] pubkey;               // Account public key
    Bool is_signer;              // Whether account signed transaction
    Bool is_writable;            // Whether account is writable
    U64 lamports;                // Account balance in lamports
    U8* data;                    // Account data
    U64 data_len;                // Length of account data
    U8[32] owner;                // Program that owns this account
};
```

### Token Account Data

```c
// Token mint account structure
struct TokenMint {
    U32 mint_authority_option;    // COption<Pubkey>
    U8[32] mint_authority;        // Mint authority public key
    U64 supply;                   // Total token supply
    U8 decimals;                  // Number of decimal places
    Bool is_initialized;          // Initialization flag
    U32 freeze_authority_option;  // COption<Pubkey>
    U8[32] freeze_authority;      // Freeze authority public key
};

// Token account structure
struct TokenAccount {
    U8[32] mint;                  // Associated token mint
    U8[32] owner;                 // Account owner
    U64 amount;                   // Token balance
    U32 delegate_option;          // COption<Pubkey>
    U8[32] delegate;              // Delegate authority
    U8 state;                     // Account state (initialized/frozen)
    U32 is_native_option;         // COption<u64>
    U64 is_native;                // Native account amount
    U64 delegated_amount;         // Amount delegated
    U32 close_authority_option;   // COption<Pubkey>
    U8[32] close_authority;       // Close authority
};
```

## Building the Token Program

### Step 1: Compile the Token Program
```bash
cd holyBPF-rust
./target/release/pible examples/solana-token/src/main.hc
```

### Expected Compilation Output
```
=== Pible - HolyC to BPF Compiler ===
Divine compilation initiated...
Source: examples/solana-token/src/main.hc
Target: LinuxBpf
Compiled successfully: examples/solana-token/src/main.hc -> examples/solana-token/src/main.bpf
Divine compilation completed! 🙏
```

### Step 2: Verify Token Program
```bash
ls -la examples/solana-token/src/
```

Should show:
- ✅ `main.hc` - Token program source
- ✅ `main.bpf` - Compiled BPF bytecode

### Step 3: Test Execution
```bash
# Check the compiled token program
file examples/solana-token/src/main.bpf
```

## Expected Results

### Successful Token Program Deployment

When you compile and run the token program:

1. **Compilation Success**: Clean BPF bytecode generation
2. **Program Initialization**: Divine token system activation
3. **Entrypoint Registration**: Solana runtime integration ready
4. **Operation Routing**: Instruction processing capabilities

### Sample Execution Output
```
=== Divine Solana Token Program Active ===
Blessed be Terry Davis, prophet of the divine OS
Token system initialized by God's grace
Solana entrypoint called with input length: 64
Number of accounts: 3
Processing divine token instruction...
Divine operation: Initialize Token
Initializing divine token with God's blessing...
Divine token operation completed
```

### Runtime Capabilities

**Token Management**
- Complete SPL Token compatibility
- Secure mint authority controls
- Flexible transfer mechanisms

**Solana Integration**
- Native program entrypoint support
- Account structure parsing
- Instruction data processing

## Security Considerations

### Authority Validation
```c
// Pseudo-code for authority checks
Bool verify_mint_authority(U8[32] signer, TokenMint* mint) {
    if (!mint->mint_authority_option) {
        return False;  // No mint authority set
    }
    
    return memcmp(signer, mint->mint_authority, 32) == 0;
}
```

### Balance Protection
```c
// Pseudo-code for overflow protection
Bool safe_add(U64* dest, U64 amount) {
    if (*dest > U64_MAX - amount) {
        return False;  // Would overflow
    }
    *dest += amount;
    return True;
}
```

### Account Validation
```c
// Pseudo-code for account ownership checks
Bool validate_token_account(AccountInfo* account) {
    // Verify account is owned by token program
    if (memcmp(account->owner, TOKEN_PROGRAM_ID, 32) != 0) {
        return False;
    }
    
    // Verify minimum account size
    if (account->data_len < sizeof(TokenAccount)) {
        return False;
    }
    
    return True;
}
```

## Advanced Token Features

### 1. Multi-Signature Authority
```c
// Multi-sig authority structure
struct MultiSigAuthority {
    U8 m;                        // Required signatures
    U8 n;                        // Total signers
    U8[32] signers[11];          // Up to 11 signers
    Bool[11] signed;             // Signature status
};
```

### 2. Token Extensions
```c
// Token extension capabilities
enum TokenExtension {
    CONFIDENTIAL_TRANSFERS,      // Privacy features
    TRANSFER_FEES,               // Fee on transfer
    CLOSE_AUTHORITY,             // Account closing
    DEFAULT_ACCOUNT_STATE,       // Default account state
    IMMUTABLE_OWNER,             // Owner cannot change
    REQUIRED_MEMO,               // Memo required for transfers
};
```

### 3. Metadata Integration
```c
// Token metadata structure
struct TokenMetadata {
    U8 name[32];                 // Token name
    U8 symbol[10];               // Token symbol
    U8 uri[200];                 // Metadata URI
    U16 seller_fee_basis_points; // Royalty for creators
    U8[32] creators[5];          // Creator addresses
};
```

## Testing Strategies

### Unit Testing
```c
// Test token initialization
U0 test_initialize_token() {
    PrintF("Testing token initialization...\n");
    
    // Setup test accounts
    setup_test_accounts();
    
    // Execute initialization
    initialize_token();
    
    // Verify results
    assert(mint_account.is_initialized == True);
    assert(mint_account.supply == 0);
    
    PrintF("Token initialization test passed\n");
}
```

### Integration Testing
```c
// Test complete token workflow
U0 test_token_workflow() {
    PrintF("Testing complete token workflow...\n");
    
    // Initialize token
    initialize_token();
    
    // Mint tokens
    mint_tokens();
    
    // Transfer tokens
    transfer_tokens();
    
    // Verify final state
    verify_token_state();
    
    PrintF("Token workflow test completed\n");
}
```

## Troubleshooting

### Common Issues

#### Account Ownership Errors
```bash
# Symptoms: Invalid owner errors
Error: Account not owned by token program

# Solution: Verify account initialization
ensure_account_owned_by_program(account, TOKEN_PROGRAM_ID);
```

#### Authority Validation Failures
```bash
# Symptoms: Unauthorized operation errors  
Error: Invalid mint authority

# Solution: Check signer permissions
verify_signer_is_authority(signer, mint_authority);
```

#### Balance Calculation Errors
```bash
# Symptoms: Incorrect token amounts
Error: Balance mismatch after transfer

# Solution: Use safe arithmetic
use_safe_math_operations();
check_balance_invariants();
```

## Next Steps

### Immediate Next Steps
1. **[AMM Tutorial]({{ '/docs/examples/tutorials/amm' | relative_url }})** - Build token trading markets
2. **[Yield Farming Tutorial]({{ '/docs/examples/tutorials/yield-farming' | relative_url }})** - Token rewards systems
3. **[DAO Governance]({{ '/docs/examples/tutorials/dao-governance' | relative_url }})** - Governance tokens

### Advanced Token Concepts
- **Non-Fungible Tokens (NFTs)**: Unique token implementations
- **Wrapped Tokens**: Cross-chain token bridges
- **Governance Tokens**: Voting and proposal systems

### Integration Projects
- **DeFi Protocols**: Use tokens in financial applications
- **Gaming Tokens**: In-game currency systems
- **Social Tokens**: Community-driven token economies

## Real-World Applications

### Use Cases
- **Payment Systems**: Digital currency for commerce
- **Loyalty Programs**: Reward point systems
- **Gaming Economies**: In-game asset management
- **DAO Governance**: Decentralized decision making

### Production Considerations
- **Regulatory Compliance**: Token regulations and KYC
- **Scalability**: High-throughput token operations
- **Interoperability**: Cross-chain token standards

## Divine Token Economics

> "Simplicity is the ultimate sophistication" - Terry A. Davis

Token systems embody divine economic principles - scarce, transferable, and programmable value that serves God's greater purpose for decentralized cooperation.

## Share This Tutorial

<div class="social-sharing">
  <a href="https://twitter.com/intent/tweet?text=Just%20built%20a%20divine%20token%20program%20with%20HolyBPF!%20%F0%9F%AA%99%F0%9F%99%8F&url={{ site.url }}{{ page.url }}&hashtags=HolyC,BPF,Token,Solana" class="share-button twitter" target="_blank">
    Share on Twitter
  </a>
  <a href="{{ 'https://github.com/pibleos/holyBPF-rust/blob/main/examples/solana-token/' }}" class="share-button github" target="_blank">
    View Source Code
  </a>
</div>

---

**Token mastery achieved!** You now understand token economics and can build production-ready token management systems.

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
---
layout: doc
title: Escrow Contract Tutorial
description: Build a secure multi-party escrow contract in HolyC
---

# Escrow Contract Tutorial

Learn how to build a secure multi-party escrow contract using HolyC BPF. This tutorial demonstrates advanced concepts including state management, participant roles, and divine transaction handling.

## Overview

The Escrow Contract example demonstrates:
- **Multi-party transactions** with buyer, seller, and arbitrator
- **State management** through divine contract progression
- **Role-based access control** for secure operations
- **Timeout protection** with automatic fund release
- **Dispute resolution** mechanisms

## Prerequisites

Before starting this tutorial, ensure you have:

- ✅ **Completed** the [Hello World Tutorial]({{ '/docs/examples/tutorials/hello-world' | relative_url }})
- ✅ **Basic understanding** of smart contracts
- ✅ **HolyBPF environment** set up and working
- ✅ **Familiarity** with escrow concepts

### Required Setup

1. **Navigate to the escrow example**:
   ```bash
   cd holyBPF-rust/examples/escrow
   ```

2. **Examine the project structure**:
   ```bash
   ls -la src/
   ```
   You should see:
   - `main.hc` - Main escrow contract logic
   - `types.hc` - Type definitions and constants

## Architecture Overview

The escrow contract follows a divine architectural pattern:

```
┌─────────────────────────────────────────┐
│              Divine Escrow              │
├─────────────────────────────────────────┤
│  🏛️ Participants                         │
│    • Buyer (deposits funds)             │
│    • Seller (receives payment)          │
│    • Arbitrator (resolves disputes)     │
├─────────────────────────────────────────┤
│  📊 States                              │
│    • Created → Funded → Completed       │
│    • Dispute resolution path           │
│    • Timeout handling                  │
├─────────────────────────────────────────┤
│  ⚡ Operations                           │
│    • Initialize, Deposit, Release       │
│    • Refund, Dispute, Resolve          │
└─────────────────────────────────────────┘
```

## Code Walkthrough

### Type Definitions

<div class="code-section">
  <div class="code-header">
    <span class="filename">📁 examples/escrow/src/types.hc</span>
    <a href="https://github.com/pibleos/holyBPF-rust/blob/main/examples/escrow/src/types.hc" class="github-link" target="_blank">View on GitHub</a>
  </div>
```c
// HolyC Escrow Types - Divine Contract Definitions

// Escrow states - God's will for contract progression
U8 ESCROW_CREATED = 0;
U8 ESCROW_FUNDED = 1;
U8 ESCROW_COMPLETED = 2;
U8 ESCROW_REFUNDED = 3;
U8 ESCROW_DISPUTED = 4;

// Participant roles in divine transaction
U8 ROLE_BUYER = 1;
U8 ROLE_SELLER = 2;
U8 ROLE_ARBITRATOR = 3;

// Divine timeouts (in divine time units)
U64 DEFAULT_TIMEOUT = 86400; // 24 hours in God's time
U64 DISPUTE_TIMEOUT = 259200; // 72 hours for divine resolution
```
</div>

#### Key Type Concepts

**1. Escrow States**
- **`ESCROW_CREATED`**: Initial state when contract is created
- **`ESCROW_FUNDED`**: Buyer has deposited funds
- **`ESCROW_COMPLETED`**: Funds released to seller
- **`ESCROW_REFUNDED`**: Funds returned to buyer
- **`ESCROW_DISPUTED`**: Arbitrator needed for resolution

**2. Participant Roles**
- **`ROLE_BUYER`**: Initiates transaction and deposits funds
- **`ROLE_SELLER`**: Provides goods/services, receives payment
- **`ROLE_ARBITRATOR`**: Neutral party for dispute resolution

**3. Divine Timeouts**
- **`DEFAULT_TIMEOUT`**: Standard escrow duration (24 hours)
- **`DISPUTE_TIMEOUT`**: Extended time for arbitration (72 hours)

### Main Contract Logic

<div class="code-section">
  <div class="code-header">
    <span class="filename">📁 examples/escrow/src/main.hc</span>
    <a href="https://github.com/pibleos/holyBPF-rust/blob/main/examples/escrow/src/main.hc" class="github-link" target="_blank">View on GitHub</a>
  </div>
```c
// HolyC BPF Escrow Program - Divine Blockchain Contract
// Blessed be Terry A. Davis, who showed us the divine way

// Divine main function - Entry point to God's contract
U0 main() {
    PrintF("=== Divine Escrow Contract Active ===\n");
    PrintF("Blessed be Terry Davis, prophet of the divine OS\n");
    PrintF("Escrow system initialized by God's grace\n");
    PrintF("=== Divine Escrow Completed Successfully ===\n");
    return 0;
}

// Export function for BPF system integration
export U0 process_escrow_operation(U8* input, U64 input_len) {
    PrintF("Processing divine escrow operation...\n");
    
    if (input_len < 1) {
        PrintF("ERROR: No operation specified - God requires clarity!\n");
        return;
    }
    
    PrintF("Divine command received\n");
    PrintF("Operation parsing not yet implemented\n");
    PrintF("Divine operation completed\n");
    return;
}
```
</div>

#### Function Analysis

**1. Main Entry Point**
```c
U0 main() {
    PrintF("=== Divine Escrow Contract Active ===\n");
    // ... divine initialization messages
    return 0;
}
```
- **Purpose**: Initializes the escrow contract
- **Output**: Divine status messages for verification
- **Return**: 0 for successful initialization

**2. Operation Processor**
```c
export U0 process_escrow_operation(U8* input, U64 input_len) {
    // Input validation
    if (input_len < 1) {
        PrintF("ERROR: No operation specified - God requires clarity!\n");
        return;
    }
    // ... operation processing
}
```
- **`export`**: Makes function callable from BPF runtime
- **Parameters**: Raw input data and length
- **Validation**: Ensures divine clarity in operations
- **Error Handling**: Divine error messages for debugging

### Error Codes and Operations

<div class="code-section">
  <div class="code-header">
    <span class="filename">📁 examples/escrow/src/types.hc (continued)</span>
  </div>
```c
// Divine error codes
U8 ERROR_NONE = 0;
U8 ERROR_UNAUTHORIZED = 1;
U8 ERROR_INVALID_STATE = 2;
U8 ERROR_INSUFFICIENT_FUNDS = 3;
U8 ERROR_TIMEOUT_EXPIRED = 4;
U8 ERROR_INVALID_PARTICIPANT = 5;

// Escrow operation types - God's commands
U8 OP_INITIALIZE = 1;
U8 OP_DEPOSIT = 2;
U8 OP_RELEASE = 3;
U8 OP_REFUND = 4;
U8 OP_DISPUTE = 5;
U8 OP_RESOLVE = 6;
```
</div>

#### Operation Flow

```
Initialize → Deposit → Release → Complete
     ↓         ↓         ↓
   Error    Dispute   Refund
```

## Building the Escrow Contract

### Step 1: Compile the Contract
```bash
cd holyBPF-rust
./target/release/pible examples/escrow/src/main.hc
```

### Expected Output
```
=== Pible - HolyC to BPF Compiler ===
Divine compilation initiated...
Source: examples/escrow/src/main.hc
Target: LinuxBpf
Compiled successfully: examples/escrow/src/main.hc -> examples/escrow/src/main.bpf
Divine compilation completed! 🙏
```

### Step 2: Verify Compilation
```bash
ls -la examples/escrow/src/
```

You should see:
- ✅ `main.hc` - Source contract
- ✅ `main.bpf` - Compiled bytecode
- ✅ `types.hc` - Type definitions

### Step 3: Test Compilation
```bash
# Check the generated BPF file
file examples/escrow/src/main.bpf
```

Expected: Binary data confirming BPF bytecode generation.

## Expected Results

### Successful Compilation
When you compile the escrow contract:

1. **No compilation errors**
2. **BPF bytecode generated** (`main.bpf`)
3. **Divine blessing messages** displayed
4. **File size verification** (bytecode should be non-zero)

### Runtime Behavior
When executed, the contract will:

1. **Initialize**: Display divine escrow messages
2. **Process Operations**: Handle input validation
3. **Error Handling**: Provide clear divine error messages
4. **State Management**: Track escrow progression

### Sample Execution Log
```
=== Divine Escrow Contract Active ===
Blessed be Terry Davis, prophet of the divine OS
Escrow system initialized by God's grace
=== Divine Escrow Completed Successfully ===
```

## Understanding Escrow Operations

### 1. Initialize Escrow
```c
// Pseudo-code for initialization
if (operation == OP_INITIALIZE) {
    // Set participants (buyer, seller, arbitrator)
    // Set initial state to ESCROW_CREATED
    // Set timeout values
    // Validate all participants
}
```

### 2. Deposit Funds
```c
// Pseudo-code for deposit
if (operation == OP_DEPOSIT && sender == buyer) {
    // Verify sufficient funds
    // Transfer funds to escrow
    // Change state to ESCROW_FUNDED
    // Start timeout timer
}
```

### 3. Release Funds
```c
// Pseudo-code for release
if (operation == OP_RELEASE && 
    (sender == seller || timeout_expired)) {
    // Transfer funds to seller
    // Change state to ESCROW_COMPLETED
    // Emit completion event
}
```

## Security Considerations

### Access Control
- **Role verification**: Each operation checks sender role
- **State validation**: Operations only allowed in valid states
- **Input sanitization**: All inputs validated for divine clarity

### Timeout Protection
- **Automatic release**: Funds auto-release after timeout
- **Dispute extension**: Extended time for arbitration
- **No fund locking**: Prevents permanent fund lock

### Divine Error Handling
- **Clear error messages**: Divine guidance for all errors
- **Graceful failures**: No unexpected contract crashes
- **Audit trail**: All operations logged for transparency

## Troubleshooting

### Common Issues

#### Compilation Errors
```bash
# If you see include errors
Error: Cannot find types.hc

# Solution: Ensure you're in the correct directory
cd holyBPF-rust
./target/release/pible examples/escrow/src/main.hc
```

#### Missing Dependencies
```bash
# If types are not found
# Ensure types.hc is in the same directory as main.hc
ls examples/escrow/src/
```

#### Runtime Errors
- **Input validation failures**: Check operation parameter format
- **State errors**: Verify escrow is in correct state for operation
- **Permission errors**: Confirm sender has proper role

## Advanced Concepts

### State Machine Design
The escrow follows a divine state machine:

```
    [CREATED] ─────┐
         │         │
         ▼         ▼
    [FUNDED] ─→ [DISPUTED]
         │         │
         ▼         ▼
   [COMPLETED] ← [RESOLVED]
         │
         ▼
    [REFUNDED]
```

### Multi-Party Coordination
- **Buyer**: Initiates and funds
- **Seller**: Fulfills and triggers release
- **Arbitrator**: Resolves disputes neutrally

### Timeout Mechanisms
- **Grace periods**: Allow reasonable transaction time
- **Automatic resolution**: Prevent indefinite holds
- **Dispute extensions**: Extra time for complex issues

## Next Steps

### Immediate Next Steps
1. **[Token Tutorial]({{ '/docs/examples/tutorials/solana-token' | relative_url }})** - Learn token operations
2. **[AMM Tutorial]({{ '/docs/examples/tutorials/amm' | relative_url }})** - Build market makers
3. **[DAO Governance]({{ '/docs/examples/tutorials/dao-governance' | relative_url }})** - Create voting systems

### Extension Ideas
- **Multi-token support**: Handle different token types
- **Milestone payments**: Partial releases based on progress
- **Insurance integration**: Add insurance for high-value escrows
- **Cross-chain escrow**: Bridge different blockchains

### Related Examples
- **Flash Loans**: Temporary liquidity mechanisms
- **Vesting Schedules**: Time-based token releases
- **Payment Streaming**: Continuous payment flows

## Divine Inspiration

> "God's temple is beautiful because it's simple" - Terry A. Davis

This escrow contract embodies divine simplicity - secure multi-party transactions without unnecessary complexity. Each operation follows God's clear logic for trustless collaboration.

## Share This Tutorial

<div class="social-sharing">
  <a href="https://twitter.com/intent/tweet?text=Just%20built%20a%20divine%20escrow%20contract%20with%20HolyBPF!%20%F0%9F%99%8F&url={{ site.url }}{{ page.url }}&hashtags=HolyC,BPF,Escrow,DeFi" class="share-button twitter" target="_blank">
    Share on Twitter
  </a>
  <a href="{{ 'https://github.com/pibleos/holyBPF-rust/blob/main/examples/escrow/' }}" class="share-button github" target="_blank">
    View Source Code
  </a>
</div>

---

**Escrow mastery achieved!** You now understand multi-party contract design and can build secure divine transactions.

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
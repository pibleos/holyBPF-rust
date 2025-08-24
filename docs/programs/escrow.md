# Escrow Program in HolyC

This guide covers the implementation of a secure escrow program on Solana using HolyC. The escrow facilitates trustless exchanges between parties by holding funds until predefined conditions are met.

## Overview

An escrow program acts as a neutral third party that holds assets during a transaction between two or more parties. The program ensures that assets are only released when all conditions are satisfied, providing security and trust in peer-to-peer transactions.

### Key Concepts

**Escrow Account**: Temporary account holding assets until transaction completion.

**Maker**: Party initiating the escrow and depositing assets.

**Taker**: Party accepting the escrow terms and providing counter-assets.

**Exchange Conditions**: Predefined requirements that must be met for asset release.

**Timeout Mechanism**: Automatic refund if conditions aren't met within timeframe.

**Atomic Execution**: All-or-nothing transaction completion.

## Escrow Architecture

### Core Components

1. **Escrow Creation**: Initialize escrow with terms and conditions
2. **Asset Deposit**: Secure holding of maker's assets
3. **Exchange Execution**: Atomic swap when conditions are met
4. **Timeout Handling**: Automatic refunds for expired escrows
5. **Dispute Resolution**: Mechanisms for handling conflicts
6. **Fee Management**: Platform fee collection and distribution

### Account Structure

```c
// Escrow account state
struct EscrowAccount {
    U8[32] escrow_id;             // Unique escrow identifier
    U8[32] maker;                 // Escrow initiator address
    U8[32] taker;                 // Expected recipient (0 if open)
    U8[32] maker_token_mint;      // Token maker is offering
    U8[32] taker_token_mint;      // Token maker wants
    U64 maker_amount;             // Amount maker is offering
    U64 taker_amount;             // Amount maker expects
    U64 creation_timestamp;       // When escrow was created
    U64 expiry_timestamp;         // When escrow expires
    U8 status;                    // 0=Active, 1=Completed, 2=Cancelled, 3=Expired
    Bool allow_partial_fill;      // Whether partial fills allowed
    U64 filled_amount;            // Amount already filled
    U64 escrow_fee;               // Platform fee amount
    U8[256] terms_hash;           // Hash of escrow terms
    Bool requires_approval;       // Whether maker must approve taker
    U64 dispute_deadline;         // Deadline for raising disputes
};

// Escrow terms and conditions
struct EscrowTerms {
    U8[512] description;          // Human-readable terms
    U64 min_fill_amount;          // Minimum partial fill
    U64 max_fill_amount;          // Maximum partial fill
    Bool allow_early_completion;  // Can complete before expiry
    Bool require_kyc;             // Whether KYC is required
    U8 dispute_resolution_method; // 0=Auto, 1=Arbitration, 2=DAO
    U64 maker_rating_required;    // Minimum maker reputation
    U64 taker_rating_required;    // Minimum taker reputation
    U8[32] arbitrator;            // Designated arbitrator (if applicable)
};

// Escrow transaction record
struct EscrowTransaction {
    U8[32] transaction_id;        // Unique transaction identifier
    U8[32] escrow_id;             // Parent escrow
    U8[32] taker;                 // Who filled this portion
    U64 fill_amount;              // Amount filled in this transaction
    U64 exchange_rate;            // Rate used for exchange
    U64 timestamp;                // When transaction occurred
    U64 maker_fee;                // Fee paid by maker
    U64 taker_fee;                // Fee paid by taker
    U8 transaction_type;          // 0=PartialFill, 1=CompleteFill, 2=Refund
};

// Dispute record
struct EscrowDispute {
    U8[32] dispute_id;            // Unique dispute identifier
    U8[32] escrow_id;             // Disputed escrow
    U8[32] disputant;             // Who raised the dispute
    U8[32] respondent;            // Other party in dispute
    U8 dispute_type;              // 0=NonDelivery, 1=WrongAmount, 2=Quality, 3=Other
    U8[1024] dispute_reason;      // Detailed dispute explanation
    U8[256] evidence_hash;        // Hash of supporting evidence
    U64 dispute_timestamp;        // When dispute was raised
    U64 resolution_deadline;      // Deadline for resolution
    U8 status;                    // 0=Open, 1=Resolved, 2=Escalated
    U8[32] resolver;              // Who resolved the dispute
    U8 resolution;                // 0=FavorMaker, 1=FavorTaker, 2=Split
};
```

## Implementation Guide

### Escrow Creation

Initialize new escrow with terms and conditions:

```c
U0 create_escrow(
    U8* taker_address,
    U8* maker_token_mint,
    U8* taker_token_mint,
    U64 maker_amount,
    U64 taker_amount,
    U64 expiry_duration,
    Bool allow_partial_fill,
    EscrowTerms* terms
) {
    if (maker_amount == 0 || taker_amount == 0) {
        PrintF("ERROR: Amounts must be positive\n");
        return;
    }
    
    if (expiry_duration < 3600 || expiry_duration > 2592000) { // 1 hour to 30 days
        PrintF("ERROR: Invalid expiry duration (1 hour to 30 days)\n");
        return;
    }
    
    // Validate token mints are different
    if (compare_pubkeys(maker_token_mint, taker_token_mint)) {
        PrintF("ERROR: Cannot trade same token with itself\n");
        return;
    }
    
    // Validate user has sufficient balance
    if (!validate_user_balance(maker_token_mint, maker_amount)) {
        PrintF("ERROR: Insufficient balance to create escrow\n");
        return;
    }
    
    // Calculate platform fee
    U64 escrow_fee = (maker_amount * get_escrow_fee_rate()) / 10000;
    
    // Validate user can pay fee
    if (escrow_fee > 0 && !validate_user_balance(maker_token_mint, escrow_fee)) {
        PrintF("ERROR: Insufficient balance for escrow fee\n");
        return;
    }
    
    // Generate escrow ID
    U8[32] escrow_id;
    generate_escrow_id(escrow_id, get_current_user(), get_current_timestamp());
    
    // Check if escrow already exists
    if (escrow_exists(escrow_id)) {
        PrintF("ERROR: Escrow ID collision\n");
        return;
    }
    
    // Create escrow account
    EscrowAccount* escrow = get_escrow_account(escrow_id);
    copy_pubkey(escrow->escrow_id, escrow_id);
    copy_pubkey(escrow->maker, get_current_user());
    
    if (taker_address) {
        copy_pubkey(escrow->taker, taker_address);
    } else {
        // Zero address means open escrow
        for (U8 i = 0; i < 32; i++) {
            escrow->taker[i] = 0;
        }
    }
    
    copy_pubkey(escrow->maker_token_mint, maker_token_mint);
    copy_pubkey(escrow->taker_token_mint, taker_token_mint);
    escrow->maker_amount = maker_amount;
    escrow->taker_amount = taker_amount;
    escrow->creation_timestamp = get_current_timestamp();
    escrow->expiry_timestamp = get_current_timestamp() + expiry_duration;
    escrow->status = 0; // Active
    escrow->allow_partial_fill = allow_partial_fill;
    escrow->filled_amount = 0;
    escrow->escrow_fee = escrow_fee;
    escrow->requires_approval = taker_address != 0; // Private escrows require approval
    escrow->dispute_deadline = escrow->expiry_timestamp + 86400; // 24 hours after expiry
    
    // Hash the terms
    hash_escrow_terms(escrow->terms_hash, terms);
    
    // Store terms separately
    store_escrow_terms(escrow_id, terms);
    
    // Transfer maker's tokens to escrow
    transfer_tokens_to_escrow(maker_token_mint, escrow_id, maker_amount + escrow_fee);
    
    PrintF("Escrow created successfully\n");
    PrintF("Escrow ID: %s\n", encode_base58(escrow_id));
    PrintF("Offering: %d tokens\n", maker_amount);
    PrintF("Expecting: %d tokens\n", taker_amount);
    PrintF("Expires: %d\n", escrow->expiry_timestamp);
    PrintF("Type: %s\n", taker_address ? "Private" : "Public");
    
    emit_escrow_created_event(escrow_id, get_current_user(), maker_amount, taker_amount);
}
```

### Escrow Execution

Handle taking and filling escrow orders:

```c
U0 take_escrow(U8* escrow_id, U64 fill_amount) {
    EscrowAccount* escrow = get_escrow_account(escrow_id);
    
    if (!escrow || escrow->status != 0) {
        PrintF("ERROR: Escrow not available\n");
        return;
    }
    
    // Check expiry
    if (get_current_timestamp() > escrow->expiry_timestamp) {
        PrintF("ERROR: Escrow has expired\n");
        expire_escrow(escrow_id);
        return;
    }
    
    // Check if taker is authorized
    Bool is_open_escrow = True;
    for (U8 i = 0; i < 32; i++) {
        if (escrow->taker[i] != 0) {
            is_open_escrow = False;
            break;
        }
    }
    
    if (!is_open_escrow && !compare_pubkeys(escrow->taker, get_current_user())) {
        PrintF("ERROR: Not authorized to take this escrow\n");
        return;
    }
    
    // Cannot take own escrow
    if (compare_pubkeys(escrow->maker, get_current_user())) {
        PrintF("ERROR: Cannot take your own escrow\n");
        return;
    }
    
    // Validate fill amount
    if (fill_amount == 0) {
        PrintF("ERROR: Fill amount must be positive\n");
        return;
    }
    
    U64 remaining_amount = escrow->maker_amount - escrow->filled_amount;
    if (fill_amount > remaining_amount) {
        PrintF("ERROR: Fill amount exceeds remaining amount\n");
        PrintF("Remaining: %d, Requested: %d\n", remaining_amount, fill_amount);
        return;
    }
    
    // Check partial fill rules
    if (!escrow->allow_partial_fill && fill_amount != remaining_amount) {
        PrintF("ERROR: Partial fills not allowed for this escrow\n");
        return;
    }
    
    // Calculate required taker amount based on exchange rate
    U64 required_taker_amount = (fill_amount * escrow->taker_amount) / escrow->maker_amount;
    
    if (required_taker_amount == 0) {
        PrintF("ERROR: Fill amount too small\n");
        return;
    }
    
    // Validate taker has sufficient balance
    if (!validate_user_balance(escrow->taker_token_mint, required_taker_amount)) {
        PrintF("ERROR: Insufficient balance to fill escrow\n");
        return;
    }
    
    // Calculate taker fee
    U64 taker_fee = (required_taker_amount * get_taker_fee_rate()) / 10000;
    
    // Execute the exchange
    
    // 1. Transfer taker tokens to escrow
    transfer_tokens_to_escrow(escrow->taker_token_mint, escrow_id, required_taker_amount + taker_fee);
    
    // 2. Transfer maker tokens to taker
    transfer_tokens_from_escrow(escrow->maker_token_mint, escrow_id, get_current_user(), fill_amount);
    
    // 3. Transfer taker tokens to maker
    transfer_tokens_from_escrow(escrow->taker_token_mint, escrow_id, escrow->maker, required_taker_amount);
    
    // 4. Collect fees
    collect_escrow_fees(escrow_id, escrow->escrow_fee, taker_fee);
    
    // Update escrow state
    escrow->filled_amount += fill_amount;
    
    // Check if escrow is completely filled
    if (escrow->filled_amount >= escrow->maker_amount) {
        escrow->status = 1; // Completed
        PrintF("Escrow completed successfully\n");
    } else {
        PrintF("Escrow partially filled\n");
        PrintF("Filled: %d/%d\n", escrow->filled_amount, escrow->maker_amount);
    }
    
    // Record transaction
    record_escrow_transaction(
        escrow_id,
        get_current_user(),
        fill_amount,
        required_taker_amount,
        escrow->filled_amount >= escrow->maker_amount ? 1 : 0 // Complete or partial
    );
    
    PrintF("Exchange executed successfully\n");
    PrintF("Maker tokens received: %d\n", fill_amount);
    PrintF("Taker tokens provided: %d\n", required_taker_amount);
    
    emit_escrow_filled_event(escrow_id, get_current_user(), fill_amount, required_taker_amount);
}

U0 cancel_escrow(U8* escrow_id) {
    EscrowAccount* escrow = get_escrow_account(escrow_id);
    
    if (!escrow || escrow->status != 0) {
        PrintF("ERROR: Escrow not available for cancellation\n");
        return;
    }
    
    // Only maker can cancel
    if (!compare_pubkeys(escrow->maker, get_current_user())) {
        PrintF("ERROR: Only escrow maker can cancel\n");
        return;
    }
    
    // Cannot cancel if partially filled (depending on terms)
    if (escrow->filled_amount > 0) {
        EscrowTerms* terms = get_escrow_terms(escrow_id);
        if (!terms->allow_early_completion) {
            PrintF("ERROR: Cannot cancel partially filled escrow\n");
            return;
        }
    }
    
    // Return remaining tokens to maker
    U64 remaining_amount = escrow->maker_amount - escrow->filled_amount;
    if (remaining_amount > 0) {
        transfer_tokens_from_escrow(escrow->maker_token_mint, escrow_id, escrow->maker, remaining_amount);
    }
    
    // Return escrow fee if no fills occurred
    if (escrow->filled_amount == 0) {
        transfer_tokens_from_escrow(escrow->maker_token_mint, escrow_id, escrow->maker, escrow->escrow_fee);
    }
    
    // Update escrow status
    escrow->status = 2; // Cancelled
    
    PrintF("Escrow cancelled successfully\n");
    PrintF("Returned amount: %d\n", remaining_amount);
    
    emit_escrow_cancelled_event(escrow_id, escrow->maker);
}
```

### Timeout and Expiry Handling

Manage expired escrows and automatic refunds:

```c
U0 expire_escrow(U8* escrow_id) {
    EscrowAccount* escrow = get_escrow_account(escrow_id);
    
    if (!escrow || escrow->status != 0) {
        PrintF("ERROR: Escrow not active\n");
        return;
    }
    
    // Check if escrow has actually expired
    if (get_current_timestamp() <= escrow->expiry_timestamp) {
        PrintF("ERROR: Escrow has not expired yet\n");
        return;
    }
    
    // Return remaining tokens to maker
    U64 remaining_amount = escrow->maker_amount - escrow->filled_amount;
    
    if (remaining_amount > 0) {
        transfer_tokens_from_escrow(escrow->maker_token_mint, escrow_id, escrow->maker, remaining_amount);
    }
    
    // Return escrow fee proportionally
    if (escrow->filled_amount < escrow->maker_amount) {
        U64 fee_refund = (escrow->escrow_fee * remaining_amount) / escrow->maker_amount;
        if (fee_refund > 0) {
            transfer_tokens_from_escrow(escrow->maker_token_mint, escrow_id, escrow->maker, fee_refund);
        }
    }
    
    // Update escrow status
    escrow->status = 3; // Expired
    
    PrintF("Escrow expired and refunded\n");
    PrintF("Refunded amount: %d\n", remaining_amount);
    PrintF("Filled before expiry: %d/%d\n", escrow->filled_amount, escrow->maker_amount);
    
    emit_escrow_expired_event(escrow_id, remaining_amount);
}

U0 claim_expired_refund(U8* escrow_id) {
    EscrowAccount* escrow = get_escrow_account(escrow_id);
    
    if (!escrow) {
        PrintF("ERROR: Escrow not found\n");
        return;
    }
    
    // Must be maker to claim refund
    if (!compare_pubkeys(escrow->maker, get_current_user())) {
        PrintF("ERROR: Only maker can claim refund\n");
        return;
    }
    
    // Check if escrow is expired
    if (escrow->status == 0 && get_current_timestamp() > escrow->expiry_timestamp) {
        // Auto-expire the escrow
        expire_escrow(escrow_id);
    } else if (escrow->status != 3) {
        PrintF("ERROR: Escrow is not expired\n");
        return;
    }
    
    PrintF("Refund already processed during expiry\n");
}
```

### Dispute Resolution

Handle disputes and conflict resolution:

```c
U0 raise_dispute(
    U8* escrow_id,
    U8 dispute_type,
    U8* dispute_reason,
    U8* evidence_hash
) {
    EscrowAccount* escrow = get_escrow_account(escrow_id);
    
    if (!escrow) {
        PrintF("ERROR: Escrow not found\n");
        return;
    }
    
    // Check if disputer is involved in escrow
    if (!compare_pubkeys(escrow->maker, get_current_user()) && 
        !is_escrow_participant(escrow_id, get_current_user())) {
        PrintF("ERROR: Only escrow participants can raise disputes\n");
        return;
    }
    
    // Check dispute deadline
    if (get_current_timestamp() > escrow->dispute_deadline) {
        PrintF("ERROR: Dispute deadline has passed\n");
        return;
    }
    
    // Validate dispute type
    if (dispute_type > 3) {
        PrintF("ERROR: Invalid dispute type\n");
        return;
    }
    
    // Generate dispute ID
    U8[32] dispute_id;
    generate_dispute_id(dispute_id, escrow_id, get_current_user(), get_current_timestamp());
    
    // Create dispute record
    EscrowDispute* dispute = get_escrow_dispute_account(dispute_id);
    copy_pubkey(dispute->dispute_id, dispute_id);
    copy_pubkey(dispute->escrow_id, escrow_id);
    copy_pubkey(dispute->disputant, get_current_user());
    
    // Determine respondent
    if (compare_pubkeys(escrow->maker, get_current_user())) {
        copy_pubkey(dispute->respondent, get_primary_taker(escrow_id));
    } else {
        copy_pubkey(dispute->respondent, escrow->maker);
    }
    
    dispute->dispute_type = dispute_type;
    copy_string(dispute->dispute_reason, dispute_reason, 1024);
    copy_data(dispute->evidence_hash, evidence_hash, 256);
    dispute->dispute_timestamp = get_current_timestamp();
    dispute->resolution_deadline = get_current_timestamp() + 604800; // 7 days
    dispute->status = 0; // Open
    
    // Freeze escrow during dispute
    if (escrow->status == 0) {
        escrow->status = 4; // Disputed (new status)
    }
    
    PrintF("Dispute raised successfully\n");
    PrintF("Dispute ID: %s\n", encode_base58(dispute_id));
    PrintF("Type: %s\n", get_dispute_type_name(dispute_type));
    PrintF("Resolution deadline: %d\n", dispute->resolution_deadline);
    
    emit_dispute_raised_event(dispute_id, escrow_id, get_current_user(), dispute_type);
}

U0 resolve_dispute(U8* dispute_id, U8 resolution) {
    EscrowDispute* dispute = get_escrow_dispute_account(dispute_id);
    
    if (!dispute || dispute->status != 0) {
        PrintF("ERROR: Dispute not available for resolution\n");
        return;
    }
    
    // Check authorization (arbitrator, admin, or DAO)
    EscrowTerms* terms = get_escrow_terms(dispute->escrow_id);
    if (!is_authorized_resolver(get_current_user(), terms)) {
        PrintF("ERROR: Not authorized to resolve disputes\n");
        return;
    }
    
    if (resolution > 2) {
        PrintF("ERROR: Invalid resolution (0=FavorMaker, 1=FavorTaker, 2=Split)\n");
        return;
    }
    
    // Execute resolution
    EscrowAccount* escrow = get_escrow_account(dispute->escrow_id);
    
    switch (resolution) {
        case 0: // Favor maker
            refund_to_maker(dispute->escrow_id);
            break;
            
        case 1: // Favor taker
            release_to_taker(dispute->escrow_id);
            break;
            
        case 2: // Split
            split_escrow_funds(dispute->escrow_id);
            break;
    }
    
    // Update dispute record
    dispute->status = 1; // Resolved
    dispute->resolution = resolution;
    copy_pubkey(dispute->resolver, get_current_user());
    
    // Update escrow status
    escrow->status = 1; // Completed (through dispute resolution)
    
    PrintF("Dispute resolved successfully\n");
    PrintF("Resolution: %s\n", get_resolution_name(resolution));
    
    emit_dispute_resolved_event(dispute_id, resolution, get_current_user());
}
```

## Advanced Features

### Multi-Party Escrow

Support for complex multi-party transactions:

```c
// Multi-party escrow structure
struct MultiPartyEscrow {
    U8[32] escrow_id;
    U8 party_count;
    U8[32] parties[8];            // Up to 8 parties
    U64 required_amounts[8];      // Required from each party
    U64 deposited_amounts[8];     // Actually deposited
    U8[32] token_mints[8];        // Token type for each party
    U8 approval_mask;             // Bitmask of who has approved
    U8 required_approvals;        // Number of approvals needed
};

U0 create_multi_party_escrow(
    U8 party_count,
    U8 parties[][32],
    U64* amounts,
    U8 token_mints[][32],
    U8 required_approvals
) {
    if (party_count < 2 || party_count > 8) {
        PrintF("ERROR: Invalid party count (2-8)\n");
        return;
    }
    
    if (required_approvals == 0 || required_approvals > party_count) {
        PrintF("ERROR: Invalid approval requirement\n");
        return;
    }
    
    // Validate all parties are different
    for (U8 i = 0; i < party_count; i++) {
        for (U8 j = i + 1; j < party_count; j++) {
            if (compare_pubkeys(parties[i], parties[j])) {
                PrintF("ERROR: Duplicate party addresses\n");
                return;
            }
        }
    }
    
    // Create multi-party escrow with enhanced coordination
    PrintF("Multi-party escrow created with %d parties\n", party_count);
}
```

This comprehensive escrow implementation provides secure, flexible, and trustless exchange mechanisms with dispute resolution and advanced features for complex trading scenarios.
---
layout: default
title: API Reference
description: Complete standard library documentation with 100+ utility functions
---

# API Reference

Comprehensive documentation for the HolyC standard library and Solana-specific APIs.

## Quick Navigation

<div class="content-grid">
  <div class="feature-card">
    <h3>📚 Standard Library</h3>
    <p>Complete documentation of 100+ utility functions, types, and constants.</p>
    <a href="{{ '/api/stdlib/' | relative_url }}" class="card-link">Browse API →</a>
  </div>
</div>

## Library Overview

The HolyC standard library provides comprehensive functionality for Solana development:

### Core Functions
- **Account Management**: Create, modify, and validate accounts
- **Data Serialization**: Efficient borsh and custom serialization
- **Cryptographic Operations**: Hashing, signing, and verification
- **Math Utilities**: Safe arithmetic and decimal operations

### Solana-Specific APIs
- **Program Derived Addresses (PDAs)**: Generate and validate PDAs
- **Cross-Program Invocation (CPI)**: Call other programs securely
- **System Program Interface**: Account creation and transfers
- **Token Program Interface**: SPL token operations

### Type System
- **Primitive Types**: U8, U16, U32, U64, I8, I16, I32, I64
- **Composite Types**: Structs, arrays, and pointers
- **Solana Types**: AccountInfo, Pubkey, Instruction
- **Custom Types**: Application-specific data structures

## Function Categories

All functions are organized by category for easy navigation:

- **Account Functions**: Account validation and manipulation
- **Crypto Functions**: Cryptographic operations and utilities
- **Math Functions**: Safe arithmetic and mathematical operations
- **String Functions**: Text processing and manipulation
- **Memory Functions**: Memory management and allocation
- **System Functions**: System calls and low-level operations

Start exploring with the **[Standard Library Reference]({{ '/api/stdlib/' | relative_url }})**.
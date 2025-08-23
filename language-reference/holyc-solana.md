---
layout: doc
title: HolyC for Solana
description: Complete HolyC language reference for Solana blockchain development
---

# HolyC Language Reference for Solana Development

This document provides a comprehensive reference for developing Solana programs using HolyC with the Pible compiler. It covers language features, Solana-specific extensions, and best practices for blockchain development.

## Basic Syntax

### Data Types

HolyC provides fundamental types optimized for BPF execution:

```c
// Integer types
U8 byte_value = 255;           // 8-bit unsigned integer
U16 short_value = 65535;       // 16-bit unsigned integer  
U32 int_value = 4294967295;    // 32-bit unsigned integer
U64 long_value = 18446744073709551615; // 64-bit unsigned integer

I8 signed_byte = -128;         // 8-bit signed integer
I16 signed_short = -32768;     // 16-bit signed integer
I32 signed_int = -2147483648;  // 32-bit signed integer
I64 signed_long = -9223372036854775808; // 64-bit signed integer

// Floating point
F64 float_value = 3.14159;     // 64-bit floating point

// Boolean
Bool flag = True;              // Boolean value (True/False)
Bool condition = False;

// Arrays
U8 bytes[32];                  // Fixed-size byte array
U64 numbers[10];               // Array of 64-bit integers

// Strings (arrays of characters)
U8 message[256] = "Hello, Solana!";
```

### Variables and Constants

```c
// Variable declarations
U64 counter = 0;
U8[32] public_key;
Bool is_initialized = False;

// Constants
static const U64 MAX_SUPPLY = 1000000000;
static const U8 PROGRAM_VERSION = 1;
static const U64 PRECISION = 1000000; // 6 decimal places
```

### Functions

```c
// Function declaration and definition
U64 add_numbers(U64 a, U64 b) {
    return a + b;
}

// Void function
U0 log_message(U8* message) {
    PrintF("Log: %s\n", message);
    return;
}

// Function with array parameter
U0 process_data(U8* data, U64 length) {
    for (U64 i = 0; i < length; i++) {
        // Process each byte
        data[i] = data[i] + 1;
    }
}
```

### Control Structures

```c
// Conditional statements
if (balance > 0) {
    PrintF("Balance is positive\n");
} else if (balance == 0) {
    PrintF("Balance is zero\n");
} else {
    PrintF("Balance is negative\n");
}

// Loops
for (U64 i = 0; i < 10; i++) {
    PrintF("Iteration: %d\n", i);
}

U64 counter = 0;
while (counter < 5) {
    PrintF("Counter: %d\n", counter);
    counter++;
}

// Switch statements
switch (instruction_type) {
    case 0:
        process_initialization();
        break;
    case 1:
        process_transfer();
        break;
    default:
        PrintF("Unknown instruction\n");
        break;
}
```

## Solana-Specific Features

### Program Entry Points

```c
// Main function for testing
U0 main() {
    PrintF("Program initialization\n");
    // Test logic here
    return 0;
}

// Solana program entrypoint
export U0 entrypoint(U8* input, U64 input_len) {
    PrintF("Solana entrypoint called\n");
    
    // Parse instruction data
    if (input_len < 1) {
        PrintF("ERROR: No instruction data\n");
        return;
    }
    
    U8 instruction_type = *input;
    U8* instruction_data = input + 1;
    U64 data_len = input_len - 1;
    
    // Route to appropriate handler
    process_instruction(instruction_type, instruction_data, data_len);
    
    return;
}
```

### Account Data Structures

```c
// Define account structures
struct TokenAccount {
    U8[32] mint;               // Token mint address
    U8[32] owner;              // Account owner
    U64 amount;                // Token balance
    U8[32] delegate;           // Delegate address (optional)
    U8 state;                  // Account state
    U64 delegated_amount;      // Delegated amount
    U64 close_authority;       // Close authority (optional)
};

// Initialize account data
U0 initialize_token_account(TokenAccount* account, U8* mint, U8* owner) {
    copy_pubkey(account->mint, mint);
    copy_pubkey(account->owner, owner);
    account->amount = 0;
    account->state = 1; // Initialized
    account->delegated_amount = 0;
}
```

### Solana System Calls

```c
// Logging functions
U0 log_message(U8* message) {
    PrintF("%s\n", message);
}

U0 log_number(U64 value) {
    PrintF("Value: %d\n", value);
}

U0 log_pubkey(U8* pubkey) {
    PrintF("Pubkey: %s\n", encode_base58(pubkey));
}

// Cross-program invocation placeholder
U0 invoke_program(U8* program_id, U8* instruction_data, U64 data_len) {
    PrintF("Invoking program: %s\n", encode_base58(program_id));
    // CPI implementation would go here
}
```

### Program Derived Addresses (PDAs)

```c
// Generate PDA for deterministic account addresses
U0 find_program_address(U8* address_out, U8* bump_out, U8* seed1, U8* seed2) {
    // Simplified PDA generation
    // In real implementation, this would use proper cryptographic derivation
    
    U8 combined_seed[64];
    for (U64 i = 0; i < 32; i++) {
        combined_seed[i] = seed1[i];
        combined_seed[i + 32] = seed2[i];
    }
    
    // Generate deterministic address
    U8 hash = 0;
    for (U64 i = 0; i < 64; i++) {
        hash ^= combined_seed[i];
    }
    
    // Create address
    for (U64 i = 0; i < 32; i++) {
        address_out[i] = hash + i;
    }
    
    *bump_out = 255; // Bump seed
}

// Use PDA for token accounts
U0 get_associated_token_address(U8* ata_address, U8* wallet, U8* mint) {
    U8 bump;
    find_program_address(ata_address, &bump, wallet, mint);
}
```

## Memory Management

### Stack Allocation

```c
U0 function_with_local_data() {
    // Local variables allocated on stack
    U8 local_buffer[1024];
    U64 local_counter = 0;
    
    // Initialize buffer
    for (U64 i = 0; i < 1024; i++) {
        local_buffer[i] = 0;
    }
    
    // Use local data
    process_buffer(local_buffer, 1024);
    
    // Automatically cleaned up when function returns
}
```

### Array Operations

```c
// Array initialization
U8 data[100];
for (U64 i = 0; i < 100; i++) {
    data[i] = i % 256;
}

// Array copying
U0 copy_array(U8* dest, U8* src, U64 length) {
    for (U64 i = 0; i < length; i++) {
        dest[i] = src[i];
    }
}

// Array comparison
Bool compare_arrays(U8* arr1, U8* arr2, U64 length) {
    for (U64 i = 0; i < length; i++) {
        if (arr1[i] != arr2[i]) {
            return False;
        }
    }
    return True;
}
```

## Error Handling

### Return Codes

```c
// Define error codes
enum ProgramError {
    SUCCESS = 0,
    INVALID_INSTRUCTION = 1,
    INSUFFICIENT_FUNDS = 2,
    UNAUTHORIZED = 3,
    ACCOUNT_NOT_FOUND = 4,
    INVALID_ACCOUNT_DATA = 5
};

// Function returning error codes
ProgramError transfer_tokens(U8* from, U8* to, U64 amount) {
    if (amount == 0) {
        return INVALID_INSTRUCTION;
    }
    
    if (!validate_account(from)) {
        return ACCOUNT_NOT_FOUND;
    }
    
    if (get_balance(from) < amount) {
        return INSUFFICIENT_FUNDS;
    }
    
    // Perform transfer
    execute_transfer(from, to, amount);
    
    return SUCCESS;
}

// Error handling in caller
U0 process_transfer_request(U8* from, U8* to, U64 amount) {
    ProgramError result = transfer_tokens(from, to, amount);
    
    switch (result) {
        case SUCCESS:
            PrintF("Transfer completed successfully\n");
            break;
        case INSUFFICIENT_FUNDS:
            PrintF("ERROR: Insufficient funds for transfer\n");
            break;
        case UNAUTHORIZED:
            PrintF("ERROR: Unauthorized transfer attempt\n");
            break;
        default:
            PrintF("ERROR: Transfer failed with code %d\n", result);
            break;
    }
}
```

### Validation Functions

```c
// Input validation
Bool validate_pubkey(U8* pubkey) {
    if (!pubkey) return False;
    
    // Check for all-zero key (invalid)
    Bool all_zero = True;
    for (U64 i = 0; i < 32; i++) {
        if (pubkey[i] != 0) {
            all_zero = False;
            break;
        }
    }
    
    return !all_zero;
}

Bool validate_amount(U64 amount, U64 max_amount) {
    return amount > 0 && amount <= max_amount;
}

Bool validate_instruction_data(U8* data, U64 length, U64 expected_length) {
    if (!data || length != expected_length) {
        PrintF("ERROR: Invalid instruction data length\n");
        return False;
    }
    return True;
}
```

## Common Patterns

### Account Initialization

```c
U0 initialize_program_account(U8* account_data, U64 data_len) {
    if (data_len < 1) {
        PrintF("ERROR: Account data too small\n");
        return;
    }
    
    // Check if already initialized
    if (account_data[0] != 0) {
        PrintF("ERROR: Account already initialized\n");
        return;
    }
    
    // Set initialization flag
    account_data[0] = 1;
    
    // Initialize remaining data
    for (U64 i = 1; i < data_len; i++) {
        account_data[i] = 0;
    }
    
    PrintF("Account initialized successfully\n");
}
```

### Access Control

```c
// Authority validation
Bool verify_authority(U8* expected_authority, U8* provided_authority) {
    if (!validate_pubkey(expected_authority) || !validate_pubkey(provided_authority)) {
        return False;
    }
    
    return compare_pubkeys(expected_authority, provided_authority);
}

// Multi-signature validation
Bool verify_multisig(U8 signatures[][64], U8* signers[], U64 signer_count, U64 threshold) {
    if (signer_count < threshold) {
        PrintF("ERROR: Insufficient signers\n");
        return False;
    }
    
    U64 valid_signatures = 0;
    
    for (U64 i = 0; i < signer_count; i++) {
        if (verify_signature(signatures[i], signers[i])) {
            valid_signatures++;
        }
    }
    
    return valid_signatures >= threshold;
}
```

### Data Serialization

```c
// Serialize account data
U0 serialize_token_account(U8* buffer, TokenAccount* account) {
    U64 offset = 0;
    
    // Copy mint (32 bytes)
    copy_array(buffer + offset, account->mint, 32);
    offset += 32;
    
    // Copy owner (32 bytes)
    copy_array(buffer + offset, account->owner, 32);
    offset += 32;
    
    // Copy amount (8 bytes)
    *(U64*)(buffer + offset) = account->amount;
    offset += 8;
    
    // Copy delegate (32 bytes)
    copy_array(buffer + offset, account->delegate, 32);
    offset += 32;
    
    // Copy state (1 byte)
    *(U8*)(buffer + offset) = account->state;
    offset += 1;
    
    // Copy delegated amount (8 bytes)
    *(U64*)(buffer + offset) = account->delegated_amount;
}

// Deserialize account data
U0 deserialize_token_account(TokenAccount* account, U8* buffer) {
    U64 offset = 0;
    
    // Read mint
    copy_array(account->mint, buffer + offset, 32);
    offset += 32;
    
    // Read owner
    copy_array(account->owner, buffer + offset, 32);
    offset += 32;
    
    // Read amount
    account->amount = *(U64*)(buffer + offset);
    offset += 8;
    
    // Read delegate
    copy_array(account->delegate, buffer + offset, 32);
    offset += 32;
    
    // Read state
    account->state = *(U8*)(buffer + offset);
    offset += 1;
    
    // Read delegated amount
    account->delegated_amount = *(U64*)(buffer + offset);
}
```

## Utility Functions

### String Operations

```c
// String length calculation
U64 string_length(U8* str) {
    U64 length = 0;
    while (str[length] != 0 && length < 1024) { // Prevent infinite loop
        length++;
    }
    return length;
}

// String copying
U0 copy_string(U8* dest, U8* src, U64 max_length) {
    U64 i = 0;
    while (i < max_length - 1 && src[i] != 0) {
        dest[i] = src[i];
        i++;
    }
    dest[i] = 0; // Null terminator
}

// String comparison
Bool strings_equal(U8* str1, U8* str2) {
    U64 i = 0;
    while (str1[i] != 0 && str2[i] != 0) {
        if (str1[i] != str2[i]) {
            return False;
        }
        i++;
    }
    return str1[i] == str2[i]; // Both should be null terminators
}
```

### Mathematical Operations

```c
// Safe arithmetic operations
U64 safe_add(U64 a, U64 b) {
    if (a > U64_MAX - b) {
        PrintF("ERROR: Integer overflow in addition\n");
        return 0;
    }
    return a + b;
}

U64 safe_multiply(U64 a, U64 b) {
    if (a == 0 || b == 0) return 0;
    
    if (a > U64_MAX / b) {
        PrintF("ERROR: Integer overflow in multiplication\n");
        return 0;
    }
    return a * b;
}

// Minimum and maximum
U64 min_u64(U64 a, U64 b) {
    return a < b ? a : b;
}

U64 max_u64(U64 a, U64 b) {
    return a > b ? a : b;
}

// Square root approximation
U64 sqrt_u64(U64 n) {
    if (n == 0) return 0;
    
    U64 x = n;
    U64 y = (x + 1) / 2;
    
    while (y < x) {
        x = y;
        y = (x + n / x) / 2;
    }
    
    return x;
}
```

## Best Practices

### Code Organization

```c
// Group related constants
static const U64 TOKEN_DECIMALS = 9;
static const U64 TOKEN_SCALE = 1000000000; // 10^9
static const U64 MAX_SUPPLY = 1000000000000000000; // 1 billion tokens

// Group related data structures
struct MarketConfig {
    U64 fee_rate;
    U64 minimum_trade;
    Bool is_active;
};

struct MarketState {
    U64 total_volume;
    U64 last_price;
    U64 last_update;
};

// Group related functions
U0 market_initialize(MarketConfig* config);
U0 market_trade(MarketState* state, U64 amount, U64 price);
U0 market_update_stats(MarketState* state);
```

### Performance Optimization

```c
// Use appropriate data types
U8 small_counter = 0;    // Instead of U64 for small values
U32 medium_value = 0;    // Instead of U64 for medium values

// Minimize function calls in loops
U0 process_large_array(U8* data, U64 length) {
    // Cache frequently used values
    const U64 chunk_size = 256;
    
    for (U64 i = 0; i < length; i += chunk_size) {
        U64 end = min_u64(i + chunk_size, length);
        process_chunk(data + i, end - i);
    }
}

// Use bitwise operations where appropriate
Bool is_power_of_two(U64 n) {
    return n > 0 && (n & (n - 1)) == 0;
}

U64 next_power_of_two(U64 n) {
    if (n == 0) return 1;
    
    n--;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    n |= n >> 32;
    n++;
    
    return n;
}
```

This language reference provides the foundation for developing sophisticated Solana programs using HolyC with proper type safety, error handling, and performance optimization.
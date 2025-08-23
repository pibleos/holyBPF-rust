---
layout: doc
title: Standard Library
description: Complete documentation of 100+ utility functions, types, and constants
---

# HolyC Solana Standard Library

This document describes the standard library functions available for HolyC Solana development with the Pible compiler.

## Core Data Types

### Primitive Types

```c
// Unsigned integers
typedef U8;                    // 8-bit unsigned integer (0 to 255)
typedef U16;                   // 16-bit unsigned integer (0 to 65,535)
typedef U32;                   // 32-bit unsigned integer (0 to 4,294,967,295)
typedef U64;                   // 64-bit unsigned integer (0 to 18,446,744,073,709,551,615)

// Signed integers
typedef I8;                    // 8-bit signed integer (-128 to 127)
typedef I16;                   // 16-bit signed integer (-32,768 to 32,767)
typedef I32;                   // 32-bit signed integer (-2,147,483,648 to 2,147,483,647)
typedef I64;                   // 64-bit signed integer (-9,223,372,036,854,775,808 to 9,223,372,036,854,775,807)

// Floating point
typedef F64;                   // 64-bit IEEE 754 floating point

// Boolean
typedef Bool;                  // Boolean type (True/False)

// Constants
static const Bool True = 1;
static const Bool False = 0;
static const U64 U64_MAX = 18446744073709551615;
static const I64 I64_MAX = 9223372036854775807;
static const I64 I64_MIN = -9223372036854775808;
```

### Array Types

```c
// Fixed-size arrays
U8 bytes[32];                  // 32-byte array
U64 numbers[10];               // Array of 10 U64 values
Bool flags[8];                 // Array of 8 boolean values

// Multi-dimensional arrays
U8 matrix[10][20];             // 10x20 matrix
U64 lookup_table[16][16];      // 16x16 lookup table
```

## Input/Output Functions

### Logging Functions

```c
// Print formatted output to program logs
U0 PrintF(U8* format, ...);

// Examples:
PrintF("Hello, World!\n");
PrintF("Value: %d\n", 42);
PrintF("Address: %s\n", pubkey_string);
PrintF("Multiple values: %d, %d, %d\n", a, b, c);

// Format specifiers:
// %d - Decimal integer
// %x - Hexadecimal integer
// %s - String
// %c - Character
// \n - Newline
// \t - Tab
```

### Solana-Specific Logging

```c
// Log a message to Solana program logs
U0 sol_log(U8* message);

// Log a 64-bit value
U0 sol_log_64(U64 value1, U64 value2, U64 value3, U64 value4, U64 value5);

// Log a public key
U0 sol_log_pubkey(U8* pubkey);

// Examples:
sol_log("Transaction processing started");
sol_log_64(amount, balance, fee, 0, 0);
sol_log_pubkey(user_account);
```

## Memory Management Functions

### Array Operations

```c
// Copy memory from source to destination
U0 memory_copy(U8* destination, U8* source, U64 length);

// Set memory to a specific value
U0 memory_set(U8* destination, U8 value, U64 length);

// Compare two memory regions
I32 memory_compare(U8* ptr1, U8* ptr2, U64 length);

// Examples:
U8 source[32] = {1, 2, 3, /* ... */};
U8 destination[32];
memory_copy(destination, source, 32);

memory_set(buffer, 0, 1024); // Clear buffer

I32 result = memory_compare(buffer1, buffer2, 64);
if (result == 0) {
    PrintF("Buffers are identical\n");
}
```

### Public Key Operations

```c
// Compare two public keys
Bool compare_pubkeys(U8* key1, U8* key2);

// Copy a public key
U0 copy_pubkey(U8* destination, U8* source);

// Check if public key is zero (invalid)
Bool is_pubkey_zero(U8* pubkey);

// Examples:
U8 user_key[32];
U8 admin_key[32];

if (compare_pubkeys(user_key, admin_key)) {
    PrintF("User is admin\n");
}

copy_pubkey(stored_key, user_key);

if (is_pubkey_zero(provided_key)) {
    PrintF("ERROR: Invalid public key\n");
}
```

## Mathematical Functions

### Basic Arithmetic

```c
// Safe arithmetic operations with overflow protection
U64 safe_add(U64 a, U64 b);
U64 safe_subtract(U64 a, U64 b);
U64 safe_multiply(U64 a, U64 b);
U64 safe_divide(U64 a, U64 b);

// Examples:
U64 result = safe_add(1000000, 2000000);
U64 difference = safe_subtract(5000000, 1000000);
U64 product = safe_multiply(price, quantity);
U64 quotient = safe_divide(total, count);
```

### Utility Math Functions

```c
// Minimum and maximum
U64 min_u64(U64 a, U64 b);
U64 max_u64(U64 a, U64 b);
I64 min_i64(I64 a, I64 b);
I64 max_i64(I64 a, I64 b);

// Absolute value
U64 abs_i64(I64 value);

// Square root (integer approximation)
U64 sqrt_u64(U64 value);

// Power function
U64 power_u64(U64 base, U64 exponent);

// Examples:
U64 smaller = min_u64(balance, limit);
U64 larger = max_u64(bid_price, ask_price);
U64 distance = abs_i64(price_difference);
U64 sqrt_result = sqrt_u64(area);
U64 compound = power_u64(base_rate, years);
```

### Fixed-Point Decimal Math

```c
// Decimal precision constants
static const U64 DECIMAL_PRECISION_6 = 1000000;      // 6 decimal places
static const U64 DECIMAL_PRECISION_9 = 1000000000;   // 9 decimal places (token amounts)
static const U64 DECIMAL_PRECISION_18 = 1000000000000000000; // 18 decimal places

// Decimal multiplication and division
U64 decimal_multiply(U64 a, U64 b, U64 precision);
U64 decimal_divide(U64 a, U64 b, U64 precision);

// Percentage calculations (basis points)
U64 percentage_of(U64 amount, U64 basis_points);
U64 apply_fee(U64 amount, U64 fee_basis_points);

// Examples:
U64 price = decimal_multiply(base_price, multiplier, DECIMAL_PRECISION_6);
U64 ratio = decimal_divide(numerator, denominator, DECIMAL_PRECISION_9);
U64 fee_amount = percentage_of(trade_amount, 30); // 0.3% fee
U64 net_amount = apply_fee(gross_amount, 250); // 2.5% fee
```

## String Functions

### String Operations

```c
// Get string length
U64 string_length(U8* string);

// Copy string
U0 string_copy(U8* destination, U8* source, U64 max_length);

// Compare strings
I32 string_compare(U8* string1, U8* string2);

// Concatenate strings
U0 string_concatenate(U8* destination, U8* source, U64 max_length);

// Examples:
U64 len = string_length("Hello, World!");
string_copy(buffer, message, 256);

if (string_compare(input, "execute") == 0) {
    PrintF("Execute command received\n");
}

string_concatenate(full_message, prefix, 1024);
```

### Base58 Encoding

```c
// Encode public key to Base58 string
U8* encode_base58(U8* pubkey);

// Decode Base58 string to public key
Bool decode_base58(U8* pubkey_out, U8* base58_string);

// Examples:
U8 user_pubkey[32];
U8* encoded = encode_base58(user_pubkey);
PrintF("User: %s\n", encoded);

U8 decoded_key[32];
if (decode_base58(decoded_key, "5QXYZ...")) {
    PrintF("Successfully decoded public key\n");
}
```

## Account Functions

### Account Information

```c
// Get account owner
U8* get_account_owner(U8* account_pubkey);

// Get account data size
U64 get_account_data_size(U8* account_pubkey);

// Check if account exists
Bool account_exists(U8* account_pubkey);

// Get account balance (lamports)
U64 get_account_balance(U8* account_pubkey);

// Examples:
U8* owner = get_account_owner(token_account);
U64 size = get_account_data_size(user_account);

if (!account_exists(target_account)) {
    PrintF("ERROR: Account does not exist\n");
}

U64 balance = get_account_balance(wallet);
```

### Account Data Access

```c
// Get account data pointer
U8* get_account_data(U8* account_pubkey);

// Write to account data
U0 set_account_data(U8* account_pubkey, U8* data, U64 offset, U64 length);

// Read from account data
U0 get_account_data_slice(U8* output, U8* account_pubkey, U64 offset, U64 length);

// Examples:
U8* account_data = get_account_data(user_position);
TokenAccount* token_data = (TokenAccount*)account_data;

set_account_data(user_account, new_data, 0, sizeof(UserData));

U8 balance_bytes[8];
get_account_data_slice(balance_bytes, token_account, 64, 8);
U64 balance = *(U64*)balance_bytes;
```

## Cryptographic Functions

### Hashing

```c
// SHA256 hash
U0 sha256(U8* output, U8* input, U64 input_length);

// Keccak256 hash
U0 keccak256(U8* output, U8* input, U64 input_length);

// Blake3 hash
U0 blake3(U8* output, U8* input, U64 input_length);

// Examples:
U8 hash_output[32];
U8 message[] = "Hello, Solana!";
sha256(hash_output, message, string_length(message));

U8 keccak_hash[32];
keccak256(keccak_hash, data, data_length);
```

### Signature Verification

```c
// Verify Ed25519 signature
Bool verify_ed25519_signature(U8* signature, U8* message, U64 message_length, U8* public_key);

// Verify secp256k1 signature
Bool verify_secp256k1_signature(U8* signature, U8* message, U64 message_length, U8* public_key);

// Examples:
U8 signature[64];
U8 message[] = "Transaction data";
U8 signer_pubkey[32];

if (verify_ed25519_signature(signature, message, sizeof(message), signer_pubkey)) {
    PrintF("Signature is valid\n");
} else {
    PrintF("Invalid signature\n");
}
```

## Time and Clock Functions

### Clock Operations

```c
// Get current Unix timestamp
U64 get_current_timestamp();

// Get current slot number
U64 get_current_slot();

// Get slot height
U64 get_slot_height();

// Convert slots to approximate time
U64 slots_to_seconds(U64 slot_count);

// Convert time to approximate slots
U64 seconds_to_slots(U64 seconds);

// Examples:
U64 now = get_current_timestamp();
U64 current_slot = get_current_slot();

U64 expiry_time = now + 3600; // 1 hour from now
U64 expiry_slot = current_slot + seconds_to_slots(3600);

PrintF("Current time: %d\n", now);
PrintF("Current slot: %d\n", current_slot);
```

## Error Handling

### Error Codes

```c
// Standard error codes
enum StandardError {
    SUCCESS = 0,
    INVALID_INSTRUCTION = 1,
    INVALID_ACCOUNT = 2,
    INSUFFICIENT_FUNDS = 3,
    UNAUTHORIZED = 4,
    ALREADY_INITIALIZED = 5,
    NOT_INITIALIZED = 6,
    ACCOUNT_TOO_SMALL = 7,
    INVALID_OWNER = 8,
    ARITHMETIC_OVERFLOW = 9,
    INVALID_SIGNATURE = 10
};

// Get error message string
U8* get_error_message(U64 error_code);

// Examples:
StandardError result = process_transfer(from, to, amount);
if (result != SUCCESS) {
    PrintF("Error: %s\n", get_error_message(result));
}
```

### Assertion Functions

```c
// Assert condition is true
U0 assert(Bool condition, U8* message);

// Assert with error code
U0 assert_with_error(Bool condition, U64 error_code);

// Examples:
assert(balance >= amount, "Insufficient balance");
assert_with_error(is_initialized, NOT_INITIALIZED);
```

## Utility Functions

### Random Number Generation

```c
// Generate pseudo-random number (not cryptographically secure)
U64 random_u64();

// Generate random number in range
U64 random_range(U64 min, U64 max);

// Seed random number generator
U0 seed_random(U64 seed);

// Examples:
seed_random(get_current_timestamp());
U64 random_value = random_u64();
U64 dice_roll = random_range(1, 6);
```

### Miscellaneous Utilities

```c
// Swap two values
U0 swap_u64(U64* a, U64* b);

// Clamp value to range
U64 clamp_u64(U64 value, U64 min, U64 max);

// Check if value is in range
Bool in_range_u64(U64 value, U64 min, U64 max);

// Examples:
swap_u64(&price1, &price2);
U64 bounded_value = clamp_u64(user_input, 1, 1000);

if (in_range_u64(amount, MIN_TRANSFER, MAX_TRANSFER)) {
    PrintF("Transfer amount is valid\n");
}
```

## Advanced Operations

### Bit Manipulation

```c
// Bit operations
U64 set_bit(U64 value, U8 bit_position);
U64 clear_bit(U64 value, U8 bit_position);
U64 toggle_bit(U64 value, U8 bit_position);
Bool test_bit(U64 value, U8 bit_position);

// Count bits
U8 count_set_bits(U64 value);
U8 count_leading_zeros(U64 value);

// Examples:
U64 flags = 0;
flags = set_bit(flags, 3); // Set bit 3
flags = clear_bit(flags, 1); // Clear bit 1

if (test_bit(permissions, ADMIN_BIT)) {
    PrintF("User has admin permissions\n");
}

U8 active_features = count_set_bits(feature_flags);
```

### Data Conversion

```c
// Endianness conversion
U16 swap_bytes_u16(U16 value);
U32 swap_bytes_u32(U32 value);
U64 swap_bytes_u64(U64 value);

// Type conversion helpers
U64 bytes_to_u64(U8* bytes);
U0 u64_to_bytes(U8* bytes, U64 value);

// Examples:
U64 network_order = swap_bytes_u64(host_order);
U64 value = bytes_to_u64(buffer);
u64_to_bytes(output_buffer, timestamp);
```

This standard library provides the fundamental building blocks for developing sophisticated Solana programs in HolyC. All functions are optimized for BPF execution and follow Solana's security and performance requirements.
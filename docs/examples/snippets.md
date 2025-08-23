# Code Snippets and Common Patterns

This document provides reusable code snippets and common programming patterns for HolyC Solana development.

## Account Management Patterns

### Account Initialization

```c
// Generic account initialization pattern
U0 initialize_account(U8* account_data, U64 data_len, U8 account_type) {
    if (data_len < 8) {
        PrintF("ERROR: Account too small for initialization\n");
        return;
    }
    
    // Check if already initialized
    if (account_data[0] != 0) {
        PrintF("ERROR: Account already initialized\n");
        return;
    }
    
    // Set account discriminator and type
    account_data[0] = 1;           // Initialized flag
    account_data[1] = account_type; // Account type
    
    // Clear remaining data
    for (U64 i = 2; i < data_len; i++) {
        account_data[i] = 0;
    }
    
    PrintF("Account initialized with type %d\n", account_type);
}
```

### Account Validation

```c
// Comprehensive account validation
Bool validate_account_state(U8* account_data, U64 data_len, U8 expected_type) {
    if (!account_data || data_len < 8) {
        PrintF("ERROR: Invalid account data\n");
        return False;
    }
    
    if (account_data[0] == 0) {
        PrintF("ERROR: Account not initialized\n");
        return False;
    }
    
    if (account_data[1] != expected_type) {
        PrintF("ERROR: Wrong account type, expected %d, got %d\n", 
               expected_type, account_data[1]);
        return False;
    }
    
    return True;
}
```

## Token Operations

### Safe Transfer Pattern

```c
// Safe token transfer with validation
U0 safe_transfer_tokens(U8* from_account, U8* to_account, U64 amount) {
    // Validate accounts
    if (!validate_token_account(from_account) || !validate_token_account(to_account)) {
        PrintF("ERROR: Invalid token accounts\n");
        return;
    }
    
    // Get current balances
    U64 from_balance = get_token_balance(from_account);
    U64 to_balance = get_token_balance(to_account);
    
    // Validate transfer amount
    if (amount == 0) {
        PrintF("ERROR: Cannot transfer zero amount\n");
        return;
    }
    
    if (from_balance < amount) {
        PrintF("ERROR: Insufficient balance: %d < %d\n", from_balance, amount);
        return;
    }
    
    // Check for overflow in destination
    if (to_balance > U64_MAX - amount) {
        PrintF("ERROR: Transfer would cause overflow\n");
        return;
    }
    
    // Execute transfer
    set_token_balance(from_account, from_balance - amount);
    set_token_balance(to_account, to_balance + amount);
    
    PrintF("Transferred %d tokens successfully\n", amount);
}
```

### Token Mint Pattern

```c
// Safe token minting with supply cap
U0 mint_tokens_with_cap(U8* token_account, U64 amount, U64 max_supply) {
    if (!validate_token_account(token_account)) {
        PrintF("ERROR: Invalid token account\n");
        return;
    }
    
    U64 current_balance = get_token_balance(token_account);
    U64 current_supply = get_total_supply();
    
    // Check supply cap
    if (current_supply + amount > max_supply) {
        PrintF("ERROR: Minting would exceed max supply\n");
        return;
    }
    
    // Check for overflow
    if (current_balance > U64_MAX - amount) {
        PrintF("ERROR: Minting would cause balance overflow\n");
        return;
    }
    
    // Execute mint
    set_token_balance(token_account, current_balance + amount);
    update_total_supply(current_supply + amount);
    
    PrintF("Minted %d tokens, new supply: %d\n", amount, current_supply + amount);
}
```

## Mathematical Operations

### Decimal Math

```c
// Fixed-point decimal arithmetic with precision
static const U64 DECIMAL_PRECISION = 1000000; // 6 decimal places

U64 decimal_multiply(U64 a, U64 b) {
    // Multiply two decimal numbers maintaining precision
    U64 result = (a * b) / DECIMAL_PRECISION;
    
    // Check for overflow
    if (a != 0 && (a * b) / a != b) {
        PrintF("ERROR: Multiplication overflow\n");
        return 0;
    }
    
    return result;
}

U64 decimal_divide(U64 a, U64 b) {
    if (b == 0) {
        PrintF("ERROR: Division by zero\n");
        return 0;
    }
    
    // Divide two decimal numbers maintaining precision
    return (a * DECIMAL_PRECISION) / b;
}

U64 percentage_of(U64 amount, U64 percentage) {
    // Calculate percentage of amount (percentage in basis points)
    return (amount * percentage) / 10000;
}
```

### Price Calculations

```c
// Calculate exchange rate between two amounts
U64 calculate_exchange_rate(U64 amount_a, U64 amount_b) {
    if (amount_b == 0) {
        PrintF("ERROR: Cannot calculate rate with zero denominator\n");
        return 0;
    }
    
    return decimal_divide(amount_a, amount_b);
}

// Calculate price impact for AMM trades
U64 calculate_price_impact(U64 trade_amount, U64 reserve_amount) {
    if (reserve_amount == 0) {
        return 10000; // 100% impact
    }
    
    return (trade_amount * 10000) / reserve_amount;
}
```

## Security Patterns

### Access Control

```c
// Role-based access control
enum UserRole {
    ADMIN = 0,
    OPERATOR = 1,
    USER = 2
};

Bool check_permission(U8* user_pubkey, UserRole required_role) {
    UserRole user_role = get_user_role(user_pubkey);
    
    if (user_role > required_role) {
        PrintF("ERROR: Insufficient permissions\n");
        return False;
    }
    
    return True;
}

// Owner validation pattern
Bool verify_owner(U8* expected_owner, U8* signer) {
    if (!compare_pubkeys(expected_owner, signer)) {
        PrintF("ERROR: Invalid owner signature\n");
        return False;
    }
    
    return True;
}
```

### Reentrancy Protection

```c
// Simple reentrancy guard
static Bool function_locked = False;

U0 guarded_function() {
    if (function_locked) {
        PrintF("ERROR: Reentrancy detected\n");
        return;
    }
    
    function_locked = True;
    
    // Function logic here
    execute_critical_operations();
    
    function_locked = False;
}
```

### Input Validation

```c
// Comprehensive input validation
Bool validate_instruction_input(U8* data, U64 length, U64 min_length, U64 max_length) {
    if (!data) {
        PrintF("ERROR: Null input data\n");
        return False;
    }
    
    if (length < min_length) {
        PrintF("ERROR: Input too short: %d < %d\n", length, min_length);
        return False;
    }
    
    if (length > max_length) {
        PrintF("ERROR: Input too long: %d > %d\n", length, max_length);
        return False;
    }
    
    return True;
}

// Pubkey validation
Bool validate_pubkey_not_zero(U8* pubkey) {
    for (U64 i = 0; i < 32; i++) {
        if (pubkey[i] != 0) {
            return True;
        }
    }
    
    PrintF("ERROR: Zero pubkey not allowed\n");
    return False;
}
```

## Error Handling Patterns

### Result Type Pattern

```c
// Result type for functions that can fail
struct Result {
    Bool success;
    U64 value;
    U8 error_code;
};

Result safe_operation(U64 input) {
    Result result;
    
    if (input == 0) {
        result.success = False;
        result.error_code = 1; // Invalid input
        result.value = 0;
        return result;
    }
    
    // Perform operation
    U64 output = input * 2;
    
    result.success = True;
    result.error_code = 0;
    result.value = output;
    
    return result;
}

// Usage pattern
U0 use_safe_operation() {
    Result result = safe_operation(42);
    
    if (result.success) {
        PrintF("Operation succeeded: %d\n", result.value);
    } else {
        PrintF("Operation failed with error: %d\n", result.error_code);
    }
}
```

### Error Propagation

```c
// Error code propagation pattern
U8 validate_and_process(U8* data, U64 length) {
    // Validate input
    if (!data || length == 0) {
        return 1; // Invalid input error
    }
    
    // Process data
    U8 process_result = process_data(data, length);
    if (process_result != 0) {
        return process_result; // Propagate processing error
    }
    
    // Validate output
    if (!validate_result()) {
        return 3; // Validation error
    }
    
    return 0; // Success
}
```

## Data Structure Patterns

### Circular Buffer

```c
// Circular buffer for price history
struct PriceHistory {
    U64 prices[100];    // Fixed-size buffer
    U64 head;           // Current write position
    U64 count;          // Number of entries
    Bool is_full;       // Whether buffer has wrapped
};

U0 add_price(PriceHistory* history, U64 price) {
    history->prices[history->head] = price;
    history->head = (history->head + 1) % 100;
    
    if (history->count < 100) {
        history->count++;
    } else {
        history->is_full = True;
    }
}

U64 get_average_price(PriceHistory* history) {
    if (history->count == 0) return 0;
    
    U64 sum = 0;
    U64 entries = history->is_full ? 100 : history->count;
    
    for (U64 i = 0; i < entries; i++) {
        sum += history->prices[i];
    }
    
    return sum / entries;
}
```

### State Machine Pattern

```c
// State machine for order lifecycle
enum OrderState {
    ORDER_PENDING = 0,
    ORDER_ACTIVE = 1,
    ORDER_FILLED = 2,
    ORDER_CANCELLED = 3,
    ORDER_EXPIRED = 4
};

Bool transition_order_state(OrderState* current_state, OrderState new_state) {
    // Define valid transitions
    switch (*current_state) {
        case ORDER_PENDING:
            if (new_state == ORDER_ACTIVE || new_state == ORDER_CANCELLED) {
                *current_state = new_state;
                return True;
            }
            break;
            
        case ORDER_ACTIVE:
            if (new_state == ORDER_FILLED || new_state == ORDER_CANCELLED || new_state == ORDER_EXPIRED) {
                *current_state = new_state;
                return True;
            }
            break;
            
        default:
            // Terminal states cannot transition
            break;
    }
    
    PrintF("ERROR: Invalid state transition from %d to %d\n", *current_state, new_state);
    return False;
}
```

## Utility Functions

### Array Utilities

```c
// Find element in array
I64 find_in_array(U64* array, U64 length, U64 target) {
    for (U64 i = 0; i < length; i++) {
        if (array[i] == target) {
            return i;
        }
    }
    return -1; // Not found
}

// Sort array (bubble sort for simplicity)
U0 sort_array(U64* array, U64 length) {
    for (U64 i = 0; i < length - 1; i++) {
        for (U64 j = 0; j < length - i - 1; j++) {
            if (array[j] > array[j + 1]) {
                // Swap
                U64 temp = array[j];
                array[j] = array[j + 1];
                array[j + 1] = temp;
            }
        }
    }
}

// Calculate array median
U64 array_median(U64* array, U64 length) {
    if (length == 0) return 0;
    
    // Create copy and sort
    U64 sorted[length];
    for (U64 i = 0; i < length; i++) {
        sorted[i] = array[i];
    }
    sort_array(sorted, length);
    
    // Return median
    if (length % 2 == 0) {
        return (sorted[length / 2 - 1] + sorted[length / 2]) / 2;
    } else {
        return sorted[length / 2];
    }
}
```

### Time and Date Utilities

```c
// Time manipulation utilities
U64 add_seconds(U64 timestamp, U64 seconds) {
    if (timestamp > U64_MAX - seconds) {
        PrintF("WARNING: Timestamp overflow\n");
        return U64_MAX;
    }
    return timestamp + seconds;
}

U64 seconds_between(U64 start, U64 end) {
    if (end < start) {
        PrintF("WARNING: End time before start time\n");
        return 0;
    }
    return end - start;
}

Bool is_expired(U64 expiry_time, U64 current_time) {
    return current_time >= expiry_time;
}

// Rate limiting
Bool is_rate_limited(U64 last_action_time, U64 current_time, U64 cooldown_seconds) {
    return seconds_between(last_action_time, current_time) < cooldown_seconds;
}
```

These snippets provide battle-tested patterns for common Solana program development scenarios. Use them as building blocks for your own HolyC programs.
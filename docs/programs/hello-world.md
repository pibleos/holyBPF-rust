# Hello World Program in HolyC

This guide provides a simple introduction to developing Solana programs using HolyC. The Hello World example demonstrates basic program structure, account handling, and logging for BPF execution.

## Overview

The Hello World program is the fundamental starting point for HolyC development on Solana. It demonstrates essential concepts including program entry points, account validation, data serialization, and basic error handling.

### Key Concepts

**Program Entry Point**: The main function that Solana calls when invoking the program.

**Account Handling**: Reading and validating accounts passed to the program.

**Logging**: Using PrintF for debug output and program tracing.

**Error Handling**: Proper error propagation and validation.

**Data Serialization**: Basic techniques for reading and writing account data.

## Program Structure

### Basic Implementation

```c
// Hello World program entry point
U0 main() {
    PrintF("Hello World program initialized\n");
    return 0;
}

// Main program processor
U0 process_instruction(U8* input, U64 input_len) {
    PrintF("Hello, World from Solana!\n");
    PrintF("Input length: %d bytes\n", input_len);
    
    if (input_len > 0) {
        PrintF("Processing input data...\n");
        // Process input data here
    }
    
    return;
}

// Export the entry point for BPF
export U0 entrypoint(U8* input, U64 input_len) {
    process_instruction(input, input_len);
    return;
}
```

### Advanced Example with Account Handling

```c
// Account structure for Hello World state
struct HelloWorldAccount {
    Bool is_initialized;        // Whether account is set up
    U64 greeting_count;         // Number of greetings sent
    U8[32] last_greeter;        // Last person to send greeting
    U64 last_greeting_time;     // Timestamp of last greeting
    U8[64] custom_message;      // Custom greeting message
};

// Instruction types
enum HelloWorldInstruction {
    INITIALIZE = 0,
    SEND_GREETING = 1,
    SET_MESSAGE = 2,
    GET_STATS = 3
};

// Process different instruction types
U0 process_instruction(U8* input, U64 input_len) {
    if (input_len < 1) {
        PrintF("ERROR: No instruction provided\n");
        return;
    }
    
    U8 instruction_type = input[0];
    U8* instruction_data = input + 1;
    U64 data_len = input_len - 1;
    
    switch (instruction_type) {
        case INITIALIZE:
            handle_initialize(instruction_data, data_len);
            break;
            
        case SEND_GREETING:
            handle_send_greeting(instruction_data, data_len);
            break;
            
        case SET_MESSAGE:
            handle_set_message(instruction_data, data_len);
            break;
            
        case GET_STATS:
            handle_get_stats(instruction_data, data_len);
            break;
            
        default:
            PrintF("ERROR: Unknown instruction type: %d\n", instruction_type);
            break;
    }
}

// Initialize Hello World account
U0 handle_initialize(U8* data, U64 len) {
    PrintF("Initializing Hello World account\n");
    
    // In a real program, you would:
    // 1. Validate account ownership
    // 2. Check account size
    // 3. Verify account is not already initialized
    
    HelloWorldAccount account;
    account.is_initialized = True;
    account.greeting_count = 0;
    account.last_greeting_time = get_current_timestamp();
    
    // Clear last greeter (set to zero)
    for (U8 i = 0; i < 32; i++) {
        account.last_greeter[i] = 0;
    }
    
    // Set default message
    copy_string(account.custom_message, "Hello, Solana!", 64);
    
    PrintF("Account initialized successfully\n");
    PrintF("Default message: %s\n", account.custom_message);
}

// Send a greeting
U0 handle_send_greeting(U8* data, U64 len) {
    PrintF("Processing greeting...\n");
    
    if (len < 32) {
        PrintF("ERROR: Invalid greeter address\n");
        return;
    }
    
    // Extract greeter address from instruction data
    U8* greeter_address = data;
    
    // In a real program, you would load the account data
    HelloWorldAccount account;
    // load_account_data(&account);
    
    if (!account.is_initialized) {
        PrintF("ERROR: Account not initialized\n");
        return;
    }
    
    // Update greeting statistics
    account.greeting_count++;
    account.last_greeting_time = get_current_timestamp();
    
    // Copy greeter address
    for (U8 i = 0; i < 32; i++) {
        account.last_greeter[i] = greeter_address[i];
    }
    
    PrintF("Greeting received! 🌟\n");
    PrintF("Total greetings: %d\n", account.greeting_count);
    PrintF("Message: %s\n", account.custom_message);
    
    // Log greeter address (first 8 bytes for brevity)
    PrintF("From: ");
    for (U8 i = 0; i < 8; i++) {
        PrintF("%02x", greeter_address[i]);
    }
    PrintF("...\n");
}

// Set custom greeting message
U0 handle_set_message(U8* data, U64 len) {
    PrintF("Setting custom message\n");
    
    if (len == 0 || len > 64) {
        PrintF("ERROR: Invalid message length (1-64 characters)\n");
        return;
    }
    
    // In a real program, validate message content
    for (U64 i = 0; i < len; i++) {
        if (data[i] < 32 || data[i] > 126) { // Printable ASCII only
            PrintF("ERROR: Message contains invalid characters\n");
            return;
        }
    }
    
    HelloWorldAccount account;
    // load_account_data(&account);
    
    if (!account.is_initialized) {
        PrintF("ERROR: Account not initialized\n");
        return;
    }
    
    // Clear existing message
    for (U8 i = 0; i < 64; i++) {
        account.custom_message[i] = 0;
    }
    
    // Copy new message
    for (U64 i = 0; i < len && i < 63; i++) {
        account.custom_message[i] = data[i];
    }
    
    PrintF("Custom message updated: %s\n", account.custom_message);
}

// Get greeting statistics
U0 handle_get_stats(U8* data, U64 len) {
    PrintF("Retrieving greeting statistics\n");
    
    HelloWorldAccount account;
    // load_account_data(&account);
    
    if (!account.is_initialized) {
        PrintF("Account not initialized\n");
        return;
    }
    
    PrintF("=== Hello World Statistics ===\n");
    PrintF("Total greetings: %d\n", account.greeting_count);
    PrintF("Current message: %s\n", account.custom_message);
    PrintF("Last greeting: %d (timestamp)\n", account.last_greeting_time);
    
    if (account.greeting_count > 0) {
        PrintF("Last greeter: ");
        for (U8 i = 0; i < 8; i++) {
            PrintF("%02x", account.last_greeter[i]);
        }
        PrintF("...\n");
    }
    
    PrintF("Account status: Active\n");
}

// Utility function to get current timestamp
U64 get_current_timestamp() {
    // In a real Solana program, this would use the Clock sysvar
    // For this example, we'll return a placeholder
    return 1640995200; // Example timestamp
}

// Utility function to copy strings safely
U0 copy_string(U8* dest, U8* src, U64 max_len) {
    U64 i = 0;
    while (i < max_len - 1 && src[i] != 0) {
        dest[i] = src[i];
        i++;
    }
    dest[i] = 0; // Null terminate
}
```

## Building and Testing

### Compilation

```bash
# Build the Hello World example
cargo build --release

# Or using the provided build command
./target/release/pible examples/hello-world/src/main.hc
```

### Testing

```bash
# Run basic tests
cargo test hello_world

# Test specific functionality
cargo test test_greeting_flow
```

### Example Test Cases

```c
// Test initialization
U0 test_initialization() {
    PrintF("Testing account initialization...\n");
    
    U8 init_instruction[1] = {0}; // INITIALIZE
    process_instruction(init_instruction, 1);
    
    PrintF("Initialization test completed\n");
}

// Test greeting functionality
U0 test_greeting() {
    PrintF("Testing greeting functionality...\n");
    
    // First initialize
    U8 init_instruction[1] = {0};
    process_instruction(init_instruction, 1);
    
    // Then send greeting
    U8 greeting_instruction[33];
    greeting_instruction[0] = 1; // SEND_GREETING
    
    // Mock greeter address (32 bytes)
    for (U8 i = 1; i <= 32; i++) {
        greeting_instruction[i] = i; // Simple test pattern
    }
    
    process_instruction(greeting_instruction, 33);
    
    PrintF("Greeting test completed\n");
}

// Test custom message
U0 test_custom_message() {
    PrintF("Testing custom message...\n");
    
    U8 message[] = "Welcome to Solana!";
    U8 message_instruction[32];
    message_instruction[0] = 2; // SET_MESSAGE
    
    // Copy message
    for (U8 i = 0; i < 18; i++) {
        message_instruction[i + 1] = message[i];
    }
    
    process_instruction(message_instruction, 19);
    
    PrintF("Custom message test completed\n");
}

// Run all tests
U0 run_tests() {
    PrintF("=== Running Hello World Tests ===\n");
    
    test_initialization();
    test_greeting();
    test_custom_message();
    
    PrintF("=== All Tests Completed ===\n");
}
```

## Error Handling

### Basic Error Patterns

```c
// Validate input parameters
Bool validate_input(U8* input, U64 input_len, U64 min_len, U64 max_len) {
    if (!input) {
        PrintF("ERROR: Null input pointer\n");
        return False;
    }
    
    if (input_len < min_len) {
        PrintF("ERROR: Input too short (min %d, got %d)\n", min_len, input_len);
        return False;
    }
    
    if (input_len > max_len) {
        PrintF("ERROR: Input too long (max %d, got %d)\n", max_len, input_len);
        return False;
    }
    
    return True;
}

// Safe account data access
Bool read_account_safely(HelloWorldAccount* account, U8* data, U64 data_len) {
    if (data_len < sizeof(HelloWorldAccount)) {
        PrintF("ERROR: Account data too small\n");
        return False;
    }
    
    // Copy data safely
    U8* account_bytes = (U8*)account;
    for (U64 i = 0; i < sizeof(HelloWorldAccount); i++) {
        account_bytes[i] = data[i];
    }
    
    return True;
}

// Validate account state
Bool validate_account_state(HelloWorldAccount* account) {
    if (!account->is_initialized) {
        PrintF("ERROR: Account not initialized\n");
        return False;
    }
    
    if (account->greeting_count > 1000000) {
        PrintF("WARNING: Unusually high greeting count\n");
    }
    
    return True;
}
```

## Security Considerations

### Input Validation

```c
// Sanitize string input
Bool sanitize_string_input(U8* input, U64 len) {
    for (U64 i = 0; i < len; i++) {
        U8 ch = input[i];
        
        // Allow only printable ASCII characters
        if (ch < 32 || ch > 126) {
            if (ch == 0 && i == len - 1) {
                continue; // Allow null terminator at end
            }
            PrintF("ERROR: Invalid character at position %d\n", i);
            return False;
        }
    }
    
    return True;
}

// Rate limiting (basic example)
Bool check_rate_limit(U64 last_action_time, U64 min_interval) {
    U64 current_time = get_current_timestamp();
    
    if (current_time < last_action_time + min_interval) {
        U64 wait_time = (last_action_time + min_interval) - current_time;
        PrintF("ERROR: Rate limit exceeded, wait %d seconds\n", wait_time);
        return False;
    }
    
    return True;
}

// Account ownership validation (conceptual)
Bool validate_account_ownership(U8* account_address, U8* expected_owner) {
    // In a real program, this would check the account's owner field
    // For this example, we'll just compare addresses
    
    for (U8 i = 0; i < 32; i++) {
        if (account_address[i] != expected_owner[i]) {
            PrintF("ERROR: Account ownership validation failed\n");
            return False;
        }
    }
    
    return True;
}
```

## Common Patterns

### Instruction Processing Pattern

```c
// Generic instruction processor
U0 process_typed_instruction(U8* input, U64 input_len) {
    // 1. Validate input
    if (!validate_input(input, input_len, 1, 1024)) {
        return;
    }
    
    // 2. Extract instruction type
    U8 instruction_type = input[0];
    U8* data = input + 1;
    U64 data_len = input_len - 1;
    
    // 3. Log instruction
    PrintF("Processing instruction type: %d\n", instruction_type);
    
    // 4. Route to handler
    switch (instruction_type) {
        case 0: handle_init(data, data_len); break;
        case 1: handle_update(data, data_len); break;
        case 2: handle_query(data, data_len); break;
        default: 
            PrintF("ERROR: Unknown instruction: %d\n", instruction_type);
            break;
    }
    
    // 5. Log completion
    PrintF("Instruction processing completed\n");
}
```

### Data Serialization Pattern

```c
// Serialize account data to bytes
U0 serialize_account(HelloWorldAccount* account, U8* output, U64 output_len) {
    if (output_len < sizeof(HelloWorldAccount)) {
        PrintF("ERROR: Output buffer too small\n");
        return;
    }
    
    U8* account_bytes = (U8*)account;
    for (U64 i = 0; i < sizeof(HelloWorldAccount); i++) {
        output[i] = account_bytes[i];
    }
}

// Deserialize bytes to account data
Bool deserialize_account(U8* input, U64 input_len, HelloWorldAccount* account) {
    if (input_len < sizeof(HelloWorldAccount)) {
        PrintF("ERROR: Input buffer too small\n");
        return False;
    }
    
    U8* account_bytes = (U8*)account;
    for (U64 i = 0; i < sizeof(HelloWorldAccount); i++) {
        account_bytes[i] = input[i];
    }
    
    return True;
}
```

This Hello World example provides the foundation for understanding HolyC program development on Solana, demonstrating essential patterns that can be expanded for more complex applications.
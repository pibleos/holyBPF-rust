---
layout: doc
title: Quick Start Guide
description: Get up and running with HolyC Solana development using the Pible compiler in minutes
---

# Quick Start Guide

This guide will get you up and running with HolyC Solana development using the Pible compiler in minutes.

## Prerequisites

### Install Zig Programming Language

Pible requires Zig 0.16.x or later for compilation:

```bash
# Download latest Zig
wget https://ziglang.org/builds/zig-linux-x86_64-0.16.0-dev.1594c8055.tar.xz
tar -xf zig-linux-x86_64-0.16.0-dev.1594c8055.tar.xz
export PATH=$PWD/zig-linux-x86_64-0.16.0-dev.1594c8055:$PATH

# Verify installation
zig version
```

### Clone the Repository

```bash
git clone https://github.com/pibleos/holyBPF-zig
cd holyBPF-zig
```

## Build the Compiler

Compile the Pible compiler from source:

```bash
# Build the compiler (may take 2-5 minutes on first run)
zig build

# Verify compiler is built
ls zig-out/bin/pible
```

## Your First HolyC Program

Create a simple HolyC program:

```c
// hello.hc
U0 main() {
    PrintF("Hello, Solana from HolyC!\n");
    return 0;
}

export U0 entrypoint(U8* input, U64 input_len) {
    PrintF("Solana entrypoint called with %d bytes\n", input_len);
    return;
}
```

Compile and test:

```bash
# Compile to BPF bytecode
./zig-out/bin/pible hello.hc

# Verify output
ls hello.hc.bpf
file hello.hc.bpf
```

## Solana Program Development

### Token Program Example

Create a basic token program:

```c
// token.hc
struct TokenAccount {
    U8[32] mint;
    U8[32] owner;
    U64 amount;
    Bool is_initialized;
};

U0 main() {
    PrintF("=== HolyC Token Program ===\n");
    test_token_operations();
    return 0;
}

export U0 entrypoint(U8* input, U64 input_len) {
    if (input_len < 1) {
        PrintF("ERROR: No instruction provided\n");
        return;
    }
    
    U8 instruction = *input;
    U8* data = input + 1;
    U64 data_len = input_len - 1;
    
    switch (instruction) {
        case 0:
            initialize_token(data, data_len);
            break;
        case 1:
            transfer_tokens(data, data_len);
            break;
        case 2:
            mint_tokens(data, data_len);
            break;
        default:
            PrintF("ERROR: Unknown instruction: %d\n", instruction);
            break;
    }
}

U0 initialize_token(U8* data, U64 data_len) {
    if (data_len < 64) {
        PrintF("ERROR: Insufficient data for initialization\n");
        return;
    }
    
    U8* mint = data;
    U8* owner = data + 32;
    
    PrintF("Initializing token account\n");
    PrintF("Mint: %s\n", encode_base58(mint));
    PrintF("Owner: %s\n", encode_base58(owner));
}

U0 transfer_tokens(U8* data, U64 data_len) {
    if (data_len < 72) {
        PrintF("ERROR: Insufficient data for transfer\n");
        return;
    }
    
    U8* from = data;
    U8* to = data + 32;
    U64 amount = *(U64*)(data + 64);
    
    PrintF("Transferring %d tokens\n", amount);
    PrintF("From: %s\n", encode_base58(from));
    PrintF("To: %s\n", encode_base58(to));
}

U0 mint_tokens(U8* data, U64 data_len) {
    if (data_len < 40) {
        PrintF("ERROR: Insufficient data for minting\n");
        return;
    }
    
    U8* to = data;
    U64 amount = *(U64*)(data + 32);
    
    PrintF("Minting %d tokens to %s\n", amount, encode_base58(to));
}

U0 test_token_operations() {
    PrintF("Running token operation tests...\n");
    
    // Test data
    U8 mint[32] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32};
    U8 owner[32] = {32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1};
    
    // Test initialization
    U8 init_data[64];
    for (U64 i = 0; i < 32; i++) {
        init_data[i] = mint[i];
        init_data[i + 32] = owner[i];
    }
    initialize_token(init_data, 64);
    
    PrintF("Token tests completed successfully\n");
}

U8* encode_base58(U8* data) {
    static U8 encoded[45];
    for (U64 i = 0; i < 44; i++) {
        encoded[i] = 'A' + (data[i % 32] % 26);
    }
    encoded[44] = 0;
    return encoded;
}
```

### Compile for Solana

```bash
# Compile with Solana target
./zig-out/bin/pible --target solana-bpf token.hc

# Generate IDL
./zig-out/bin/pible --target solana-bpf --generate-idl token.hc
```

## DeFi Program Examples

### Simple AMM

```bash
# Build the AMM example
zig build amm

# Check output
ls zig-out/bin/amm.bpf
```

### Lending Protocol

```bash
# Build the lending example
zig build lending

# Check output
ls zig-out/bin/lending.bpf
```

## Development Workflow

### 1. Write HolyC Code

Create your program with proper structure:

```c
// program.hc
U0 main() {
    // Test logic
}

export U0 entrypoint(U8* input, U64 input_len) {
    // Solana program logic
}
```

### 2. Compile and Test

```bash
# Compile
./zig-out/bin/pible program.hc

# Test with BPF VM (if available)
./zig-out/bin/pible --target bpf-vm --enable-vm-testing program.hc
```

### 3. Deploy to Solana

```bash
# Generate deployment-ready files
./zig-out/bin/pible --target solana-bpf --generate-idl program.hc

# Use Solana CLI for deployment (if available)
solana program deploy program.hc.bpf
```

## Common Patterns

### Error Handling

```c
enum ProgramError {
    SUCCESS = 0,
    INVALID_INSTRUCTION = 1,
    INSUFFICIENT_FUNDS = 2,
    UNAUTHORIZED = 3
};

ProgramError validate_transfer(U64 amount, U64 balance) {
    if (amount == 0) {
        return INVALID_INSTRUCTION;
    }
    
    if (amount > balance) {
        return INSUFFICIENT_FUNDS;
    }
    
    return SUCCESS;
}
```

### Account Management

```c
Bool validate_account(U8* account_data, U64 expected_size) {
    if (!account_data) {
        PrintF("ERROR: Account data is null\n");
        return False;
    }
    
    if (get_account_size(account_data) < expected_size) {
        PrintF("ERROR: Account too small\n");
        return False;
    }
    
    return True;
}
```

### Data Serialization

```c
U0 serialize_u64(U8* buffer, U64* offset, U64 value) {
    *(U64*)(buffer + *offset) = value;
    *offset += 8;
}

U64 deserialize_u64(U8* buffer, U64* offset) {
    U64 value = *(U64*)(buffer + *offset);
    *offset += 8;
    return value;
}
```

## Next Steps

### Explore Examples

Study the included examples for advanced patterns:

- `examples/amm/` - Automated Market Maker
- `examples/lending/` - Lending Protocol
- `examples/escrow/` - Escrow Contracts
- `examples/solana-token/` - Token Programs

### Read Documentation

Continue with detailed guides:

- [HolyC Language Reference](../language-reference/holyc-solana.md)
- [AMM Development Guide](../programs/amm.md)
- [Lending Protocol Guide](../programs/lending.md)
- [Orderbook Systems](../programs/orderbook.md)
- [Prediction Markets](../programs/prediction-markets.md)

### Join the Community

- GitHub: https://github.com/pibleos/holyBPF-zig
- Issues: Report bugs and request features
- Discussions: Share your projects and get help

## Troubleshooting

### Common Issues

**"zig: command not found"**
- Install Zig as shown in prerequisites
- Ensure Zig is in your PATH

**"Build failed with fetch errors"**
- Check internet connection
- Dependencies are fetched automatically on first build

**"Program compilation errors"**
- Check HolyC syntax against language reference
- Ensure proper function signatures for Solana programs

**"BPF output not generated"**
- Verify input file exists and has correct syntax
- Check compiler output for error messages

### Getting Help

If you encounter issues:

1. Check the error message carefully
2. Review the relevant documentation section
3. Look at similar examples in the `examples/` directory
4. Open an issue on GitHub with:
   - Your HolyC code
   - Complete error output
   - System information (OS, Zig version)

Happy coding with HolyC on Solana!
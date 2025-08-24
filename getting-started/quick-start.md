---
layout: doc
title: Quick Start Guide (Rust Edition)
description: Get up and running with HolyC-on-Solana using the Rust-based holyBPF toolchain
---

# Quick Start Guide (Rust Edition)

This guide adapts the original Zig-based instructions to the Rust implementation found in this repository. You will install the Rust toolchain, build the compiler (written in Rust), and compile HolyC programs to Solana BPF artifacts.

---

## 1. Prerequisites

### 1.1 Install Rust Toolchain

We rely on stable Rust (1.78+ recommended for modern features and performance).

```bash
# Install rustup (if not already)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Activate environment (if needed)
source $HOME/.cargo/env

# Verify versions
rustc --version
cargo --version
```

Optional performance enhancements:

```bash
# Add nightly (if you want experimental perf flags later)
rustup toolchain install nightly
```

### 1.2 Install Solana CLI (optional but recommended for deployment)

```bash
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
solana --version
```

### 1.3 Clone Repository

```bash
git clone https://github.com/pibleos/holyBPF-rust
cd holyBPF-rust
```

---

## 2. Build the Compiler

The Rust workspace produces the `pible` (HolyC → BPF/Solana) compiler.

```bash
# Release build for speed
cargo build --release

# Binary path
ls target/release/pible
```

(If build dependencies are fetched the first time, network duration may vary.)

---

## 3. Your First HolyC Program

Create a file `hello.hc`:

```c
// hello.hc
U0 main() {
    PrintF("Hello, Solana from HolyC (Rust toolchain)!\n");
    return 0;
}

export U0 entrypoint(U8* input, U64 input_len) {
    PrintF("Solana entrypoint called with %d bytes\n", input_len);
    return;
}
```

Compile:

```bash
./target/release/pible hello.hc
```

Artifacts:

```bash
ls hello.hc.bpf
file hello.hc.bpf
```

If IDL or extra metadata generation is supported:

```bash
./target/release/pible --target solana-bpf --generate-idl hello.hc
```

---

## 4. Token Program Example (HolyC)

Create `token.hc`:

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

    U8 mint[32]  = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32};
    U8 owner[32] = {32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1};

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

Compile for Solana:

```bash
./target/release/pible --target solana-bpf token.hc
./target/release/pible --target solana-bpf --generate-idl token.hc
```

---

## 5. (Optional) Parallel Rust Reference

If you desire a native Rust Solana skeleton (for comparison or hybrid flows):

```bash
cargo new solana-rs-template
cd solana-rs-template
```

In `Cargo.toml` add Solana crates (versions may shift; consult official Solana docs):

```toml
[dependencies]
solana-program = "1.18"
solana-program-test = "1.18"
solana-sdk = "1.18"
```

Minimal `lib.rs`:

```rust
use solana_program::{
    account_info::{next_account_info, AccountInfo},
    entrypoint,
    entrypoint::ProgramResult,
    msg,
    pubkey::Pubkey,
};

entrypoint!(process_instruction);
fn process_instruction(
    _program_id: &Pubkey,
    accounts: &[AccountInfo],
    data: &[u8],
) -> ProgramResult {
    msg!("Rust reference entrypoint: {} bytes", data.len());
    let _iter = &mut accounts.iter();
    Ok(())
}
```

Build:

```bash
cargo build-bpf   # if using older solana tools
# or with new workflows:
cargo build --release
```

Consult official Solana Program Library & docs for current toolchain transitions.

---

## 6. DeFi / Example Modules

If this Rust-based repository provides feature examples (AMM, lending, etc.), build them via Cargo features or example targets:

```bash
# List examples
cargo run --example list

# Hypothetical examples (adjust to actual names)
cargo build --release --example amm
cargo build --release --example lending
```

Generated HolyC-compiled BPF artifacts (if produced) will appear under:

```
target/release/*.bpf
```

---

## 7. Development Workflow

1. Write HolyC source (`*.hc`)
2. Compile with Rust-built `pible`
3. (Optional) Run local BPF VM tests if supported
4. Deploy using Solana CLI

```bash
./target/release/pible program.hc
./target/release/pible --target bpf-vm --enable-vm-testing program.hc
./target/release/pible --target solana-bpf --generate-idl program.hc
solana program deploy program.hc.bpf
```

---

## 8. Common Patterns (HolyC Snippets)

### Error Handling

```c
enum ProgramError {
    SUCCESS = 0,
    INVALID_INSTRUCTION = 1,
    INSUFFICIENT_FUNDS = 2,
    UNAUTHORIZED = 3
};

ProgramError validate_transfer(U64 amount, U64 balance) {
    if (amount == 0) return INVALID_INSTRUCTION;
    if (amount > balance) return INSUFFICIENT_FUNDS;
    return SUCCESS;
}
```

### Account Validation

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

### Serialization Helpers

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

---

## 9. Next Steps

Study repository directories:

- `examples/amm/`
- `examples/lending/`
- `examples/escrow/`
- `examples/solana-token/`

Further reading (consult official sources for accuracy):

- HolyC Language Reference (this repo): `../language-reference/holyc-solana.md`
- Solana Program Docs: https://docs.solana.com/developing/on-chain-programs/overview
- Rust Book: https://doc.rust-lang.org/book/
- Solana Program Library: https://github.com/solana-labs/solana-program-library

---

## 10. Troubleshooting

Issue: `cargo: command not found`  
Fix: Install Rust via rustup; ensure `$HOME/.cargo/bin` on PATH.

Issue: Build fails (linker / crate version)  
Fix: Run `cargo update`; ensure Solana CLI + crate versions align.

Issue: BPF artifact not produced  
Fix: Verify `--target solana-bpf` argument; check compiler logs.

Issue: Deployment fails (account size / compute budget)  
Fix: Inspect program logs:  
```bash
solana logs
```
Optimize HolyC code size (remove unused functions, inline judiciously).

---

## 11. Performance Guidance

- Use release builds: `cargo build --release`
- Strip symbols (if necessary): `llvm-objcopy -g program.hc.bpf program.min.bpf`
- Keep stack usage minimal in HolyC functions
- Prefer fixed-size structs; avoid unnecessary dynamic patterns

---

## 12. Contributing

1. Fork repository
2. Create feature branch: `git checkout -b feat/optimizer-pass`
3. Run tests: `cargo test`
4. Submit PR with:
   - Rationale
   - Benchmark deltas (if perf-related)
   - Minimal diff

---

## 13. Support

Open issues with details:

- HolyC source snippet
- Exact command used
- Full error output
- `rustc --version` and `solana --version`
- Host OS / architecture

---

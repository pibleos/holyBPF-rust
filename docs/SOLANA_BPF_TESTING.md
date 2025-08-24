# Solana BPF Testing with Mollusk

This document outlines the integration of Solana BPF test tools, particularly Mollusk, for testing HolyC-compiled Solana programs.

## Overview

Mollusk is a lightweight framework for testing Solana programs directly without requiring a full validator or test validator. It provides a BPF VM environment that can execute and test Solana programs efficiently.

## Installation

To enable Solana BPF testing tools, uncomment the dependencies in `Cargo.toml`:

```toml
[dependencies]
solana-program = { version = "2.0", optional = true }
solana-sdk = { version = "2.0", optional = true }

[dev-dependencies]
mollusk-svm = "0.1"
```

Then enable the feature:
```bash
cargo test --features solana-bpf
```

## Mollusk Integration

### Basic Test Setup

```rust
use mollusk_svm::Mollusk;
use solana_sdk::{
    account::AccountSharedData,
    instruction::{AccountMeta, Instruction},
    pubkey::Pubkey,
};

#[test]
fn test_holyc_program_with_mollusk() {
    // Load compiled HolyC BPF program
    let program_id = Pubkey::new_unique();
    let program_data = std::fs::read("examples/hello-world/src/main.bpf").unwrap();
    
    // Initialize Mollusk VM
    let mollusk = Mollusk::new(&program_id, &program_data);
    
    // Create test accounts
    let user = Pubkey::new_unique();
    let user_account = AccountSharedData::new(1_000_000, 0, &program_id);
    
    // Create instruction
    let instruction = Instruction::new_with_bincode(
        program_id,
        &(),  // Instruction data
        vec![AccountMeta::new(user, true)],
    );
    
    // Execute and verify
    let result = mollusk.process_instruction(&instruction, &[(user, user_account)]);
    assert!(result.is_ok());
}
```

### Testing DeFi Programs

#### AMM Testing
```rust
#[test]
fn test_amm_swap() {
    let program_id = Pubkey::new_unique();
    let amm_data = std::fs::read("examples/amm/src/main.bpf").unwrap();
    let mollusk = Mollusk::new(&program_id, &amm_data);
    
    // Setup AMM pool accounts
    let pool_account = create_amm_pool_account();
    let token_a_account = create_token_account(1_000_000);
    let token_b_account = create_token_account(2_000_000);
    
    // Test swap instruction
    let swap_instruction = create_swap_instruction(
        program_id,
        10_000,  // Amount to swap
        true,    // A to B direction
    );
    
    let accounts = vec![
        (pool_key, pool_account),
        (token_a_key, token_a_account),
        (token_b_key, token_b_account),
    ];
    
    let result = mollusk.process_instruction(&swap_instruction, &accounts);
    assert!(result.is_ok());
    
    // Verify swap results
    let post_state = result.unwrap();
    verify_swap_results(&post_state);
}
```

#### Yield Farming Testing
```rust
#[test]
fn test_yield_farming_stake() {
    let program_id = Pubkey::new_unique();
    let farm_data = std::fs::read("examples/yield-farming/src/main.bpf").unwrap();
    let mollusk = Mollusk::new(&program_id, &farm_data);
    
    // Setup farming accounts
    let farm_pool = create_farm_pool_account();
    let staker_position = create_staker_position_account();
    let staking_token_account = create_token_account(100_000);
    
    // Test staking instruction
    let stake_instruction = create_stake_instruction(
        program_id,
        50_000,  // Amount to stake
    );
    
    let accounts = vec![
        (farm_pool_key, farm_pool),
        (staker_position_key, staker_position),
        (staking_token_key, staking_token_account),
    ];
    
    let result = mollusk.process_instruction(&stake_instruction, &accounts);
    assert!(result.is_ok());
    
    // Verify staking results
    verify_stake_success(&result.unwrap());
}
```

#### Flash Loan Testing
```rust
#[test]
fn test_flash_loan_execution() {
    let program_id = Pubkey::new_unique();
    let flash_loan_data = std::fs::read("examples/flash-loans/src/main.bpf").unwrap();
    let mollusk = Mollusk::new(&program_id, &flash_loan_data);
    
    // Setup flash loan pool
    let pool_account = create_flash_loan_pool(1_000_000); // 1M liquidity
    let borrower_account = create_user_account();
    
    // Test flash loan execution
    let flash_loan_instruction = create_flash_loan_instruction(
        program_id,
        100_000,  // Borrow amount
        vec![1, 2, 3],  // Callback data for arbitrage
    );
    
    let accounts = vec![
        (pool_key, pool_account),
        (borrower_key, borrower_account),
    ];
    
    // Execute flash loan
    let result = mollusk.process_instruction(&flash_loan_instruction, &accounts);
    assert!(result.is_ok());
    
    // Verify flash loan execution
    verify_flash_loan_success(&result.unwrap());
}
```

## Test Scenarios

### 1. Unit Tests
Test individual program instructions in isolation:
- Account initialization
- Parameter validation
- State transitions
- Error handling

### 2. Integration Tests
Test complex workflows:
- Multi-instruction sequences
- Cross-program invocations
- Account state consistency

### 3. Property-Based Tests
Test invariants across random inputs:
- Conservation laws (e.g., token conservation in AMM)
- Security properties (e.g., no unauthorized withdrawals)
- Mathematical properties (e.g., constant product formula)

### 4. Fuzzing Tests
Test with random or malformed inputs:
- Invalid instruction data
- Boundary value testing
- Stress testing with large values

## Continuous Integration

### GitHub Actions Integration

```yaml
name: Solana BPF Tests

on: [push, pull_request]

jobs:
  test-solana-bpf:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Rust
        uses: dtolnay/rust-toolchain@stable
        
      - name: Compile HolyC Programs
        run: |
          cargo build --release
          ./target/release/pible examples/hello-world/src/main.hc
          ./target/release/pible examples/amm/src/main.hc
          ./target/release/pible examples/yield-farming/src/main.hc
          ./target/release/pible examples/flash-loans/src/main.hc
          
      - name: Run Mollusk Tests
        run: cargo test --features solana-bpf test_mollusk_
```

## Performance Testing

### Compute Unit Analysis
```rust
#[test]
fn test_compute_unit_usage() {
    let result = mollusk.process_instruction_with_compute_limit(
        &instruction,
        &accounts,
        200_000,  // Compute unit limit
    );
    
    assert!(result.is_ok());
    let compute_units_used = result.unwrap().compute_units_consumed;
    assert!(compute_units_used < 150_000, "Program uses too many compute units");
}
```

### Memory Usage Testing
```rust
#[test]
fn test_memory_efficiency() {
    let initial_memory = get_vm_memory_usage();
    
    // Execute multiple operations
    for i in 0..1000 {
        mollusk.process_instruction(&instruction, &accounts).unwrap();
    }
    
    let final_memory = get_vm_memory_usage();
    assert!(final_memory - initial_memory < MEMORY_LIMIT);
}
```

## Best Practices

1. **Test Isolation**: Each test should be independent and not rely on shared state
2. **Realistic Data**: Use realistic account sizes and data structures
3. **Error Testing**: Test both success and failure scenarios
4. **Resource Limits**: Test within Solana's compute and memory constraints
5. **State Verification**: Always verify account state changes after operations
6. **Regression Testing**: Maintain tests for previously fixed bugs

## Debugging

### VM State Inspection
```rust
let result = mollusk.process_instruction(&instruction, &accounts);
if result.is_err() {
    println!("VM Logs: {:?}", mollusk.get_logs());
    println!("Account Changes: {:?}", mollusk.get_account_changes());
}
```

### Custom Assertions
```rust
fn assert_account_balance(account: &AccountSharedData, expected: u64) {
    let balance = u64::from_le_bytes(account.data()[0..8].try_into().unwrap());
    assert_eq!(balance, expected, "Account balance mismatch");
}
```

## Limitations

- Mollusk simulates Solana runtime but may not catch all edge cases
- Cross-program invocations require additional setup
- System programs (like Token Program) need to be mocked
- Time-dependent tests may require custom clock simulation

## Additional Resources

- [Mollusk Documentation](https://docs.rs/mollusk-svm/)
- [Solana Program Testing Guide](https://docs.solana.com/developing/on-chain-programs/testing)
- [BPF Program Development](https://docs.solana.com/developing/on-chain-programs/overview)

This testing framework ensures that HolyC-compiled Solana programs work correctly and efficiently in the Solana runtime environment.
# Solana BPF and Extended Features

This document describes the extended features of the HolyC to BPF compiler (Pible) including Solana BPF support, IDL generation, and BPF VM emulation.

## Multi-Target Compilation

The compiler now supports three different compilation targets:

### Linux BPF (Default)
Traditional Linux BPF compilation for kernel-space execution.
```bash
./pible program.hc
./pible --target linux-bpf program.hc
```

### Solana BPF
Solana BPF runtime compatibility for Solana blockchain programs.
```bash
./pible --target solana-bpf program.hc
```

### BPF VM Emulation
BPF VM emulation for testing and debugging.
```bash
./pible --target bpf-vm program.hc
```

## IDL Generation

Generate Interface Definition Language (IDL) files for Solana programs:

```bash
./pible --target solana-bpf --generate-idl program.hc
```

This creates a JSON IDL file that describes:
- Program instructions and their arguments
- Account definitions
- Custom data types

Example IDL output:
```json
{
  "version": "0.1.0",
  "name": "holyc_program",
  "instructions": [
    {
      "name": "main",
      "args": []
    }
  ],
  "accounts": [],
  "types": []
}
```

## BPF VM Testing

Enable BPF VM testing during compilation to validate program behavior:

```bash
./pible --target bpf-vm --enable-vm-testing program.hc
```

The VM emulator provides:
- Full BPF instruction execution
- System call emulation
- Memory management simulation
- Execution statistics
- Debug logging

## Solana-Specific Features

### System Calls
The Solana BPF target supports Solana-specific system calls:
- `sol_log` - Log messages
- `sol_log_64` - Log 64-bit values  
- `sol_log_pubkey` - Log public keys
- `sol_invoke` - Cross-program invocation
- Various cryptographic functions (SHA256, Blake3, etc.)

### Account Model
Solana programs work with an account-based model:
```c
// Example account access
U0 process_accounts(SolanaAccount* accounts, U64 account_count) {
    // Access account data, lamports, owner, etc.
}
```

### Cross-Program Invocation (CPI)
Support for calling other Solana programs:
```c
// Example CPI call
U0 call_other_program(U8* target_program_id, U8* instruction_data) {
    // Cross-program invocation logic
}
```

## Program Structure

### Linux BPF Programs
```c
U0 main() {
    PrintF("Hello, Linux BPF!\n");
    return 0;
}
```

### Solana BPF Programs
```c
// Main function for testing
U0 main() {
    PrintF("Hello, Solana!\n");
    return 0;
}

// Solana program entrypoint
export U0 entrypoint(U8* input, U64 input_len) {
    // Parse Solana input structure
    // Process instruction
    return;
}
```

## Command Line Options

### Basic Usage
```bash
pible [options] <source_file>
```

### Options
- `--target <target>` - Compilation target (linux-bpf, solana-bpf, bpf-vm)
- `--generate-idl` - Generate IDL file
- `--enable-vm-testing` - Enable BPF VM testing
- `--output-dir <dir>` - Output directory for generated files
- `--help, -h` - Show help message

### Examples
```bash
# Basic Linux BPF compilation
pible program.hc

# Solana BPF with IDL generation
pible --target solana-bpf --generate-idl token_program.hc

# BPF VM testing
pible --target bpf-vm --enable-vm-testing test_program.hc

# Custom output directory
pible --target solana-bpf --output-dir ./build program.hc
```

## Output Files

### BPF Bytecode (`.bpf`)
Binary BPF bytecode ready for execution:
- Linux BPF: Loadable into Linux kernel
- Solana BPF: Deployable to Solana runtime
- BPF VM: Executable in the emulator

### IDL Files (`.json`)
JSON Interface Definition Language files for Solana programs.

## BPF VM Emulator

The built-in BPF VM provides:

### Execution Environment
- 11 64-bit registers (r0-r10)
- 512-byte stack
- Dynamic heap allocation
- Program counter tracking

### System Call Emulation
- Linux BPF syscalls (trace_printk)
- Solana BPF syscalls (sol_log, etc.)
- Error handling and validation

### Debugging Features
- Instruction tracing
- Memory access validation
- Compute unit tracking
- Log message capture

### Statistics
- Execution time
- Compute units consumed
- Memory usage
- System call counts

## Error Handling

The compiler provides comprehensive error reporting:
- Lexical analysis errors
- Syntax parsing errors
- Code generation errors
- BPF validation errors
- VM execution errors

## Performance Considerations

### Compilation Speed
- Linux BPF: Fastest compilation
- Solana BPF: Moderate (includes validation)
- BPF VM: Slower (includes execution)

### Generated Code
- All targets produce optimized BPF bytecode
- Solana BPF includes additional runtime checks
- VM target includes debugging information

## Limitations

### Current Limitations
- Limited HolyC language feature support
- Basic IDL generation (function signatures only)
- Simplified Solana account model
- No complex data type support in IDL

### Future Enhancements
- Full HolyC language support
- Advanced IDL features
- Comprehensive Solana SDK integration
- Performance optimization
- Advanced debugging features

## Examples

See the `examples/` directory for sample programs:
- `hello-world/` - Basic BPF program
- `escrow/` - Solana escrow contract
- `solana-token/` - Solana token program

Each example can be compiled for any target:
```bash
# Compile for different targets
./pible --target linux-bpf examples/hello-world/src/main.hc
./pible --target solana-bpf --generate-idl examples/solana-token/src/main.hc
./pible --target bpf-vm --enable-vm-testing examples/escrow/src/main.hc
```
# Documentation Examples

## API Documentation

The project now has comprehensive docs.rs native documentation. To view the documentation locally:

```bash
cargo doc --open
```

## Key Features

### Library Usage

```rust
use pible::{Compiler, CompileOptions, CompileTarget};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let compiler = Compiler::new();
    let options = CompileOptions {
        target: CompileTarget::SolanaBpf,
        generate_idl: true,
        ..Default::default()
    };

    // Compile HolyC source code
    let source = r#"
        U0 main() {
            PrintF("Hello, divine world!\n");
            return 0;
        }
    "#;

    let bytecode = compiler.compile(source, &options)?;
    println!("Generated {} bytes of BPF bytecode", bytecode.len());
    
    Ok(())
}
```

### Advanced Lexical Analysis

```rust
use pible::{Lexer, TokenType};

fn analyze_holyc_code() -> Result<(), Box<dyn std::error::Error>> {
    let source = r#"
        U64 divine_number = 42;
        if (divine_number > 0) {
            PrintF("Terry's blessing: %d\n", divine_number);
        }
    "#;

    let mut lexer = Lexer::new(source);
    let tokens = lexer.scan_tokens()?;

    // Count different token types
    let identifiers: Vec<_> = tokens.iter()
        .filter(|t| t.token_type == TokenType::Identifier)
        .collect();
    let numbers: Vec<_> = tokens.iter()
        .filter(|t| t.token_type == TokenType::NumberLiteral) 
        .collect();

    println!("Found {} identifiers and {} numbers", identifiers.len(), numbers.len());
    
    Ok(())
}
```

### BPF Virtual Machine Testing

```rust
use pible::{BpfVm, BpfInstruction};

fn test_bpf_program() -> Result<(), Box<dyn std::error::Error>> {
    // Create some test BPF instructions
    let instructions = vec![
        BpfInstruction::new(0xb7, 0, 0, 0, 42), // MOV R0, 42
        BpfInstruction::new(0x95, 0, 0, 0, 0),  // EXIT
    ];
    
    let mut vm = BpfVm::new(&instructions);
    let result = vm.execute()?;
    
    println!("Program exited with code: {}", result.exit_code);
    println!("Compute units used: {}", result.compute_units);
    
    Ok(())
}
```

## Documentation Features

- **Comprehensive API docs**: All public types and functions documented
- **Code examples**: Working examples for all major functionality
- **Error handling**: Detailed error type documentation with examples
- **Multi-target support**: Linux BPF, Solana BPF, and VM testing
- **Integration examples**: Real-world usage patterns

## Generated Documentation

The documentation includes:

1. **Module Overview**: Each module has detailed purpose and usage
2. **Type Documentation**: All structs, enums, and their fields
3. **Method Documentation**: Parameters, returns, examples, and errors
4. **Cross-references**: Links between related types and concepts
5. **Examples**: Executable code examples that demonstrate usage

## docs.rs Integration

The project is configured for docs.rs with:

- `docs.rs` metadata in Cargo.toml
- Feature flags for conditional compilation
- Platform-specific targets (x86_64, aarch64)
- Comprehensive rustdoc configuration
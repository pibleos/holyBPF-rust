# Pible - HolyC to BPF Compiler

Pible is a HolyC to BPF compiler written in Zig that transforms HolyC programs into BPF bytecode for kernel-space execution. This compiler bridges Terry Davis's HolyC with Linux BPF systems.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### What This Compiler Does
Pible transforms HolyC programs into BPF (Berkeley Packet Filter) bytecode that can run in Linux kernel space. The compilation pipeline:
1. **Lexer** → Tokenizes HolyC source code
2. **Parser** → Builds Abstract Syntax Tree (AST)  
3. **CodeGen** → Generates BPF instructions using zbpf library
4. **Output** → Produces .bpf files containing BPF bytecode

### Prerequisites and Setup
- **CRITICAL**: Install Zig programming language (version 0.13.0 or later):
  - **Primary method**: Download from https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz
    ```bash
    cd /tmp
    wget https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz
    tar -xf zig-linux-x86_64-0.13.0.tar.xz
    export PATH=/tmp/zig-linux-x86_64-0.13.0:$PATH
    ```
  - **Alternative method**: Via package manager (if available):
    ```bash
    # Ubuntu/Debian (if available)
    sudo apt install zig
    # Or via snap
    sudo snap install zig --classic
    ```
  - **Verify installation**: `zig version` (should show 0.13.0 or later)
  - **NOTE**: If network access is restricted, Zig installation may fail. Document this limitation.

### Build and Test Commands
- **CRITICAL**: Set timeouts of 120+ seconds for all build commands. Zig builds can take 2-5 minutes.
- **CRITICAL**: Set timeouts of 300+ seconds for test commands. Full test suite can take 5-10 minutes.

**Bootstrap and build the repository:**
```bash
cd /path/to/holyBPF-zig
zig build                    # NEVER CANCEL: Takes 2-5 minutes. Set timeout to 120+ seconds.
```

**Run the test suite:**
```bash
zig build test              # NEVER CANCEL: Takes 5-10 minutes. Set timeout to 300+ seconds.
```

**Build specific examples:**
```bash
zig build hello-world       # Build the hello-world example BPF program
```

**Compile HolyC programs:**
```bash
# Compile a HolyC file to BPF bytecode
./zig-out/bin/pible examples/hello-world/src/main.hc
# This produces main.hc.bpf containing the BPF bytecode

# Verify the output is valid BPF bytecode
file examples/hello-world/src/main.hc.bpf
hexdump -C examples/hello-world/src/main.hc.bpf | head -5
```

**Optional BPF testing (if bpf tools available):**
```bash
# These commands may not work in all environments
bpf-cli verify examples/hello-world/src/main.hc.bpf    # Verify BPF program
bpf-cli run examples/hello-world/src/main.hc.bpf       # Run BPF program
```

## Validation

### Manual Testing Scenarios
After making changes, ALWAYS run through these validation scenarios:

1. **Basic Compilation Test:**
   ```bash
   # Test compiler on hello-world example
   ./zig-out/bin/pible examples/hello-world/src/main.hc
   # Verify main.hc.bpf file is created and non-empty
   ls -la examples/hello-world/src/main.hc.bpf
   file examples/hello-world/src/main.hc.bpf  # Should show binary data
   ```

2. **Error Handling Test:**
   ```bash
   # Create a file with invalid HolyC syntax
   echo "U0 broken() { invalid_syntax" > /tmp/broken.hc
   # Verify compiler reports appropriate error (should fail gracefully)
   ./zig-out/bin/pible /tmp/broken.hc
   ```

3. **Test Suite Validation:**
   ```bash
   # Always run full test suite after changes
   zig build test              # NEVER CANCEL: 5-10 minutes
   ```

4. **Example Programs Validation:**
   ```bash
   # Build and verify all examples
   zig build hello-world
   # Check that example binaries are created
   ls -la zig-out/bin/
   ```

5. **Dependency Verification:**
   ```bash
   # Verify zbpf dependency is fetched correctly
   zig build --verbose 2>&1 | grep zbpf
   ```

### Verification Steps
- ALWAYS build the project first: `zig build`
- ALWAYS run the complete test suite: `zig build test`  
- ALWAYS test the compiler on the hello-world example
- Verify BPF bytecode output files are generated correctly
- The application is a command-line compiler - no GUI to screenshot

## Project Structure

### Key Directories and Files
```
├── src/Pible/              # Core compiler implementation
│   ├── Main.zig            # Entry point and CLI handling
│   ├── Compiler.zig        # Main compiler orchestration
│   ├── Lexer.zig           # HolyC tokenization
│   ├── Parser.zig          # AST generation
│   ├── CodeGen.zig         # BPF bytecode generation
│   └── Tests.zig           # Test entry point
├── tests/                  # Comprehensive test suite
│   ├── main.zig            # Test orchestration
│   ├── lexer_test.zig      # Lexer unit tests
│   ├── parser_test.zig     # Parser unit tests
│   ├── codegen_test.zig    # Code generation tests
│   ├── compiler_test.zig   # Integration tests
│   └── integration_test.zig # End-to-end tests
├── examples/               # Sample programs
│   └── hello-world/        # Basic HolyC example
│       └── src/main.hc     # Sample HolyC program
├── build.zig               # Zig build configuration
├── build.zig.zon           # Project dependencies
└── README.md               # Project documentation
```

### Core Components
- **Lexer**: Tokenizes HolyC source code into language tokens
- **Parser**: Builds Abstract Syntax Tree (AST) from tokens  
- **CodeGen**: Transforms AST into BPF bytecode instructions
- **Main**: CLI interface that orchestrates the compilation pipeline

### Dependencies
- **zbpf**: BPF bytecode generation library (v0.2.0)
  - Automatically fetched during build via build.zig.zon
  - Used for BPF instruction encoding and validation

## Common Tasks

### Making Changes to the Compiler
1. Identify the component to modify:
   - Lexer.zig: For new HolyC keywords or syntax
   - Parser.zig: For new language constructs or grammar
   - CodeGen.zig: For new BPF instruction generation
2. Always add corresponding tests in tests/ directory
3. Build and test iteratively: `zig build && zig build test`

### Adding New HolyC Language Features
1. Update Lexer.zig to recognize new tokens
2. Update Parser.zig to handle new grammar rules
3. Update CodeGen.zig to emit appropriate BPF instructions
4. Add comprehensive tests in all relevant test files
5. Update examples/ if the feature warrants demonstration

### Debugging Build Issues
- **Check Zig version**: `zig version` (requires 0.13.0+)
- **Clean build**: `rm -rf zig-cache zig-out && zig build`
- **Verbose build**: `zig build --verbose`
- **Check dependency fetch**: Dependencies are fetched from build.zig.zon
  - zbpf library from: https://github.com/tw4452852/zbpf/archive/refs/tags/v0.2.0.tar.gz
  - If network restricted, dependency fetch will fail
- **Common issues**:
  - "zig: command not found" → Install Zig first
  - "fetch failed" → Network restrictions preventing dependency download
  - "hash mismatch" → Dependency version or corruption issue

### Performance Notes
- Build time: 2-5 minutes (depending on system)
- Test execution: 5-10 minutes for full suite
- Compilation: Individual HolyC files compile in seconds
- Generated BPF bytecode is optimized for kernel execution

## Repository Context

### Command Reference
```bash
# Most frequently used commands
zig build                    # Build entire project
zig build test              # Run all tests  
zig build hello-world       # Build example
./zig-out/bin/pible file.hc # Compile HolyC file

# Build outputs
zig-out/bin/pible           # Main compiler executable
*.bpf                       # Generated BPF bytecode files
```

### File Extensions
- `.hc` - HolyC source files (e.g., main.hc, types.hc)
- `.zig` - Zig source files (compiler implementation)
- `.bpf` - Generated BPF bytecode files (compiler output)

### HolyC Language Basics
```c
// Example HolyC program structure (from examples/hello-world/src/main.hc)
U0 main() {                           // Entry point for testing
    return 0;
}

U0 process_instruction(U8* input, U64 input_len) {
    PrintF("Hello, World!\n");       // BPF trace output
    return;
}

export U0 entrypoint(U8* input, U64 input_len) {  // BPF program entry
    process_instruction(input, input_len);
    return;
}
```

### Important Notes
- This is a command-line compiler, not a GUI application
- All generated BPF files are intended for kernel-space execution
- The project honors Terry A. Davis's memory and HolyC legacy
- Build system uses Zig's native build system (build.zig)
- No external package managers or additional tools required beyond Zig
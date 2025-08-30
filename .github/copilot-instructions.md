# Pible - HolyC to BPF Compiler

Pible is a HolyC to BPF compiler written in Zig that transforms HolyC programs into BPF bytecode for kernel-space execution. This compiler bridges Terry Davis's HolyC with Linux BPF systems.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

**IMPORTANT**: All timing estimates and command validations in these instructions have been tested and verified. Build times are much faster than typical Zig projects due to no external dependencies.

## Rules for This Project

### Zig Version Requirements
- **ALWAYS use Zig 0.16.x or later** for this project
- The project requires Zig 0.16.x minimum for proper build system and ArrayList API compatibility
- Do not use older Zig versions (0.15.x or earlier) as they have incompatible APIs:
  - ArrayList.init() vs ArrayList{} initialization
  - append() requiring allocator parameter 
  - deinit() requiring allocator parameter
  - writer() requiring allocator parameter
  - toOwnedSlice() requiring allocator parameter
  - .root_source_file vs .root_module build API changes
- When updating Zig version requirements, always test the build to ensure compatibility

## Working Effectively

### What This Compiler Does
Pible transforms HolyC programs into BPF (Berkeley Packet Filter) bytecode that can run in Linux kernel space. The compilation pipeline:
1. **Lexer** → Tokenizes HolyC source code
2. **Parser** → Builds Abstract Syntax Tree (AST)  
3. **CodeGen** → Generates BPF instructions using zbpf library
4. **Output** → Produces .bpf files containing BPF bytecode

### Prerequisites and Setup
- **CRITICAL**: Install Zig programming language (version 0.16.x or later):
  - **Primary method**: Download from https://ziglang.org/builds/ (latest 0.16.x development build)
    ```bash
    cd /tmp
    # Get latest development build (0.16.x) - check https://ziglang.org/download/index.json for current version
    wget https://ziglang.org/builds/zig-x86_64-linux-0.16.0-dev.13+1594c8055.tar.xz
    tar -xf zig-x86_64-linux-0.16.0-dev.13+1594c8055.tar.xz
    export PATH=/tmp/zig-x86_64-linux-0.16.0-dev.13+1594c8055:$PATH
    ```
  - **Alternative method**: Via package manager (if available):
    ```bash
    # Ubuntu/Debian (if available)
    sudo apt install zig
    # Or via snap
    sudo snap install zig --classic
    ```
  - **Verify installation**: `zig version` (should show 0.16.x or later)
  - **IMPORTANT NOTE**: If the specific Zig build URL above returns 404, check https://ziglang.org/download/index.json for the current development build URL and update accordingly.

### Build and Test Commands
- **TIMING**: Build commands are very fast in this project (~6 seconds). Tests are even faster (<1 second).
- **NO EXTERNAL DEPENDENCIES**: This project has no external dependencies to fetch during build.
- **TIMEOUTS**: Use 60+ second timeouts for build commands as a safety buffer, though builds typically complete in seconds.

**Bootstrap and build the repository:**
```bash
cd /path/to/holyBPF-rust
zig build                    # Typically completes in ~6 seconds. No dependency fetching required.
```

**Run the test suite:**
```bash
zig build test              # Typically completes in <1 second. Runs all tests in tests/ directory.
```

**Build specific examples:**
```bash
zig build hello-world       # Build the hello-world example BPF program (~0.03 seconds)
zig build escrow            # Build the escrow example BPF program (~0.03 seconds)
# Note: solana-token example currently has parsing issues - this is a known limitation
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
# These commands may not work in all environments - BPF tools are not typically available
bpf-cli verify examples/hello-world/src/main.hc.bpf    # Verify BPF program (if bpf-cli installed)
bpf-cli run examples/hello-world/src/main.hc.bpf       # Run BPF program (if bpf-cli installed)
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
   # Always run full test suite after changes - completes very quickly
   zig build test              # Typically completes in <1 second
   ```

4. **Example Programs Validation:**
   ```bash
   # Build and verify working examples - each completes in <0.1 seconds
   zig build hello-world
   zig build escrow
   # Check that example binaries are created
   ls -la zig-out/bin/
   # Note: solana-token example has known parsing issues
   ```

5. **Build Validation Tools:**
   ```bash
   # Use provided build validation tools - completes in ~1 second
   ./build_validator.sh
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
- **NO EXTERNAL DEPENDENCIES**: This project has no external dependencies listed in build.zig.zon
  - BPF instruction generation is implemented internally in src/Pible/CodeGen.zig
  - No network access required during build process
  - All functionality is self-contained within the repository

## Common Tasks

### Using Build Validation Tools
The repository includes automated build validation tools:
```bash
./build_validator.sh           # Comprehensive build validation (~1 second)
./recursive_build_fixer.sh     # Automated build issue fixing
./build_analyzer.sh            # Static analysis of build configuration
```

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
- **Check Zig version**: `zig version` (requires 0.16.x+)
- **Clean build**: `rm -rf zig-cache zig-out && zig build`
- **Verbose build**: `zig build --verbose`
- **Use build validation tools**: `./build_validator.sh` or `./recursive_build_fixer.sh`
- **Common issues**:
  - "zig: command not found" → Install Zig first
  - Build failures → Use provided build validation tools
  - Example parsing issues → Some examples (like solana-token) have known parsing limitations

### Performance Notes
- Build time: ~6 seconds (very fast, no external dependencies)
- Test execution: <1 second for full suite
- Compilation: Individual HolyC files compile in milliseconds
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

### Known Limitations
- Some example programs (like solana-token) have parsing issues with complex pointer syntax
- BPF bytecode verification tools (bpf-cli) are not commonly available in most environments
- Error messages may include Zig memory debugging output which can be ignored

## Troubleshooting

### When These Instructions Don't Work
If you encounter issues with these instructions:

1. **"zig: command not found"**
   - Zig is not installed or not in PATH
   - Follow the Prerequisites section above
   - Verify with `zig version`

2. **"fetch failed" or network errors**
   - This project has no external dependencies, so network fetch errors should not occur
   - If you see fetch errors, this indicates an unexpected issue
   - Check firewall/proxy settings if problems persist

3. **Build timeouts or hangs**
   - Builds are typically very fast (~6 seconds)
   - If builds hang, check for system resource issues
   - Use `zig build --verbose` to see progress

4. **Hash mismatch errors**
   - This project has no external dependencies, so hash mismatches should not occur
   - If seen, may indicate Zig installation or project corruption issues
   - Clear cache: `rm -rf zig-cache` and retry

5. **Missing BPF output files**
   - Build may have failed due to HolyC syntax errors
   - Check for error messages in build output
   - Verify input .hc files have correct HolyC syntax
   - Some examples (like solana-token) have known parsing issues
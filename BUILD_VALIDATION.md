# Build Validation Tools

This directory contains automated tools to validate and fix the HolyBPF-rust build system.

## Tools Overview

### 1. build_validator.sh
Basic build validation script that attempts to build the repository and analyzes output for errors.

**Usage:**
```bash
./build_validator.sh
```

**Features:**
- Checks prerequisites (Rust installation, required files)
- Attempts clean build with verbose output
- Runs tests if build succeeds
- Builds example programs
- Analyzes output for common error patterns
- Provides specific fix suggestions
- Saves all logs to build_logs/ directory

### 2. build_analyzer.sh
Static analysis tool that examines build configuration files for potential issues.

**Usage:**
```bash
./build_analyzer.sh
```

**Features:**
- Validates project structure
- Checks file references in Cargo.toml
- Analyzes Cargo.toml for Rust version compatibility
- Validates Cargo.lock syntax
- Suggests dependency requirements
- Reports overall health status

### 3. recursive_build_fixer.sh
Advanced tool that automatically attempts to fix build issues through multiple iterations.

**Usage:**
```bash
./recursive_build_fixer.sh
```

**Features:**
- Automatic Rust installation detection
- Iterative build-fix-retry loop (max 5 iterations)
- Automated fixes for common issues:
  - Cargo.toml dependency version mismatches
  - Missing feature flags configuration
  - Invalid Rust edition specifications  
  - Missing development dependencies
- Comprehensive final report
- Test execution after successful builds

## Common Issues and Fixes

### Issue 1: Rust Version Compatibility
**Error:** `error[E0658]: use of unstable library feature`
**Fix:** Update to stable Rust 1.78+ or add required feature flags

### Issue 2: Missing Dependencies
**Error:** `use of undeclared crate or module`
**Fix:** Add missing dependencies to `[dependencies]` section in Cargo.toml

### Issue 3: Cargo.toml Format
**Error:** `expected string, found integer`
**Fix:** Use correct TOML syntax for version specifications

### Issue 4: Missing Rust Installation
**Error:** `cargo: command not found`
**Fix:** Install Rust 1.78+ from https://rustup.rs/

## Prerequisites

- Rust 1.78 or later
- Linux/Unix environment with bash
- Internet access for crate dependencies (if needed)
- Standard Unix tools: wget, tar, timeout

## Directory Structure

```
build_logs/              # Created by validation tools
├── build.log            # Main build output
├── test.log             # Test execution output
├── examples.log         # Example build output
└── build_attempt_N.log  # Per-iteration logs from recursive fixer
```

## Validation Workflow

1. **Quick Check:** Run `./build_analyzer.sh` for static analysis
2. **Full Validation:** Run `./build_validator.sh` to attempt actual build
3. **Auto-Fix:** Run `./recursive_build_fixer.sh` for automated repair

## Expected Results

### Healthy Build System
```
✅ BUILD SYSTEM APPEARS HEALTHY
Main issue is likely missing Rust 1.78+ installation

Next steps:
1. Install Rust 1.78+ from https://rustup.rs/
2. Run: cargo build --release
3. Run: cargo test
```

### Successful Build
```
🎉 SUCCESS: Both build and tests passed!

Project is ready for development:
- Compiler binary: ./target/release/pible
- Run tests: cargo test
- Build examples: cargo build --release
```

## Troubleshooting

If validation tools fail:

1. **Check Rust Installation:**
   ```bash
   rustc --version  # Should show 1.78 or later
   cargo --version  # Should show corresponding version
   ```

2. **Verify Project Structure:**
   ```bash
   ls src/main.rs      # Should exist
   ls Cargo.toml       # Should exist
   ```

3. **Review Logs:**
   ```bash
   cat build_logs/build.log  # Check for specific errors
   ```

4. **Manual Build:**
   ```bash
   cargo build --verbose  # See detailed build output
   ```

## Integration with CI/CD

These tools can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions usage
- name: Validate Build System
  run: ./build_analyzer.sh

- name: Attempt Automated Fixes
  run: ./recursive_build_fixer.sh
```

## Contributing

When adding new build system features:

1. Run all validation tools to ensure compatibility
2. Update tool logic if new error patterns are introduced
3. Add new validation checks for new build requirements
4. Update this README with new issues/fixes
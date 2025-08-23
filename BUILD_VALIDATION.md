# Build Validation Tools

This directory contains automated tools to validate and fix the HolyBPF-zig build system.

## Tools Overview

### 1. build_validator.sh
Basic build validation script that attempts to build the repository and analyzes output for errors.

**Usage:**
```bash
./build_validator.sh
```

**Features:**
- Checks prerequisites (Zig installation, required files)
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
- Checks file references in build.zig
- Analyzes build.zig for Zig version compatibility
- Validates build.zig.zon syntax
- Suggests dependency requirements
- Reports overall health status

### 3. recursive_build_fixer.sh
Advanced tool that automatically attempts to fix build issues through multiple iterations.

**Usage:**
```bash
./recursive_build_fixer.sh
```

**Features:**
- Automatic Zig installation detection
- Iterative build-fix-retry loop (max 5 iterations)
- Automated fixes for common issues:
  - .root_source_file → .root_src conversion
  - b.path() → LazyPath syntax conversion
  - String → enum literal conversion in .zon files
  - Missing fingerprint/dependencies sections
- Comprehensive final report
- Test execution after successful builds

## Common Issues and Fixes

### Issue 1: Zig Version Compatibility
**Error:** `no field named 'root_source_file'`
**Fix:** Update build.zig to use `.root_src` instead of `.root_source_file`

### Issue 2: Deprecated API Usage
**Error:** `b.path() not found`
**Fix:** Use `.{ .cwd_relative = "path" }` instead of `b.path("path")`

### Issue 3: build.zig.zon Format
**Error:** `expected enum literal`
**Fix:** Use `.name = .holyc_bpf` instead of `.name = "holyc_bpf"`

### Issue 4: Missing Zig Installation
**Error:** `zig: command not found`
**Fix:** Install Zig 0.15.1+ from https://ziglang.org/download/0.15.1/

## Prerequisites

- Zig 0.15.1 or later
- Linux/Unix environment with bash
- Internet access for Zig installation (if needed)
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
Main issue is likely missing Zig 0.15.1+ installation

Next steps:
1. Install Zig 0.15.1 from https://ziglang.org/download/0.15.1/
2. Run: zig build
3. Run: zig build test
```

### Successful Build
```
🎉 SUCCESS: Both build and tests passed!

Project is ready for development:
- Compiler binary: ./zig-out/bin/pible
- Run tests: zig build test
- Build examples: zig build hello-world
```

## Troubleshooting

If validation tools fail:

1. **Check Zig Installation:**
   ```bash
   zig version  # Should show 0.15.1 or later
   ```

2. **Verify Project Structure:**
   ```bash
   ls src/Pible/Main.zig  # Should exist
   ls build.zig           # Should exist
   ```

3. **Review Logs:**
   ```bash
   cat build_logs/build.log  # Check for specific errors
   ```

4. **Manual Build:**
   ```bash
   zig build --verbose  # See detailed build output
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
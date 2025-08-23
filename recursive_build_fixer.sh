#!/bin/bash

# HolyBPF-rust Recursive Build Fixer
# Attempts to automatically fix common build issues

set -e

echo "=== HolyBPF-rust Recursive Build Fixer ==="
echo "Timestamp: $(date)"
echo ""

# Function to log with timestamp
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# Function to check Rust installation
check_rust_installation() {
    log "Checking Rust installation..."
    
    if command -v cargo &> /dev/null; then
        local rust_version=$(rustc --version)
        log "✅ Found Rust: $rust_version"
        return 0
    else
        log "❌ Rust not found. Installing Rust toolchain..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
        log "✅ Rust installation completed"
        return 0
    fi
}

# Function to attempt build and capture issues
attempt_build() {
    log "Attempting cargo build..."
    
    local build_log="recursive_build_attempt.log"
    
    if timeout 300 cargo build --verbose 2>&1 | tee "$build_log"; then
        log "✅ Build successful"
        return 0
    else
        log "❌ Build failed - analyzing issues..."
        return 1
    fi
}

# Function to attempt tests
attempt_tests() {
    log "Attempting cargo test..."
    
    local test_log="recursive_test_attempt.log"
    
    if timeout 600 cargo test 2>&1 | tee "$test_log"; then
        local test_count=$(grep -o "test result: ok\. [0-9]* passed" "$test_log" | grep -o "[0-9]*" || echo "0")
        log "✅ Tests successful - $test_count tests passed"
        return 0
    else
        log "❌ Tests failed - check $test_log for details"
        return 1
    fi
}

# Function to fix common cargo issues
fix_cargo_issues() {
    log "Attempting to fix common cargo issues..."
    
    # Clean cargo cache
    log "Cleaning cargo cache..."
    cargo clean
    
    # Update cargo registry
    log "Updating cargo registry..."
    cargo update
    
    # Check for dependency conflicts
    log "Checking for dependency conflicts..."
    if cargo tree 2>&1 | grep -q "conflict"; then
        log "⚠️  Dependency conflicts detected - manual resolution may be needed"
    fi
    
    # Fix formatting issues
    log "Fixing code formatting..."
    cargo fmt
    
    log "✅ Common fixes applied"
}

# Function to check for missing files and create them if needed
fix_missing_files() {
    log "Checking for missing files..."
    
    # Ensure lib.rs exists if needed
    if [[ ! -f "src/lib.rs" ]] && grep -q "\[lib\]" Cargo.toml 2>/dev/null; then
        log "Creating missing src/lib.rs..."
        cat > src/lib.rs << 'EOF'
//! HolyC to BPF Compiler Library
//! 
//! This library provides the core functionality for compiling HolyC programs
//! to BPF bytecode.

pub mod pible;
pub use pible::*;
EOF
    fi
    
    # Check for gitignore
    if [[ ! -f ".gitignore" ]]; then
        log "Creating .gitignore..."
        cat > .gitignore << 'EOF'
# Rust
/target/
Cargo.lock
**/*.rs.bk
*.pdb

# IDE
.vscode/
.idea/
*.swp
*.swo

# Build artifacts
*.bpf
*.log
EOF
    fi
    
    log "✅ Missing files check complete"
}

# Function to generate status report
generate_status_report() {
    log "Generating status report..."
    
    local report_file="build_fixer_report.txt"
    
    cat > "$report_file" << EOF
HolyBPF-rust Build Fixer Report
Generated: $(date)

=== System Information ===
Rust Version: $(rustc --version 2>/dev/null || echo "Not installed")
Cargo Version: $(cargo --version 2>/dev/null || echo "Not installed")
OS: $(uname -a)

=== Project Status ===
Root Directory: $(pwd)
Cargo.toml: $([ -f "Cargo.toml" ] && echo "Found" || echo "Missing")
Main Source: $([ -f "src/main.rs" ] && echo "Found" || echo "Missing")
Tests: $([ -f "src/tests.rs" ] && echo "Found" || echo "Missing")

=== Recommendations ===
- Build project: cargo build
- Run tests: cargo test
- Compile examples: cargo run --bin pible examples/hello-world/src/main.hc
- Format code: cargo fmt
- Run lints: cargo clippy

=== Next Steps ===
If issues persist:
1. Check Cargo.toml for dependency issues
2. Ensure all required source files exist
3. Run 'cargo clean' and rebuild
4. Check the build logs for specific error messages

EOF

    log "✅ Status report generated: $report_file"
}

# Function to check if we're in the right directory
check_project_root() {
    if [[ ! -f "Cargo.toml" ]]; then
        log "❌ Error: Cargo.toml not found. Are you in the project root?"
        log "   Current directory: $(pwd)"
        log "   Please navigate to the HolyBPF-rust project root directory"
        exit 1
    fi
    
    log "✅ Found Cargo.toml - we're in the project root"
}

# Main recursive fixing function
main() {
    log "Starting recursive build fixing process..."
    
    local max_attempts=3
    local attempt=1
    
    # Initial checks
    check_project_root
    check_rust_installation
    fix_missing_files
    
    while [[ $attempt -le $max_attempts ]]; do
        log "=== Attempt $attempt of $max_attempts ==="
        
        # Try to fix issues
        fix_cargo_issues
        
        # Attempt build
        if attempt_build; then
            log "✅ Build successful on attempt $attempt"
            
            # Try tests
            if attempt_tests; then
                log "🎉 Build and tests successful!"
                generate_status_report
                return 0
            else
                log "⚠️  Build succeeded but tests failed"
            fi
        else
            log "❌ Build failed on attempt $attempt"
        fi
        
        ((attempt++))
        
        if [[ $attempt -le $max_attempts ]]; then
            log "Waiting before next attempt..."
            sleep 2
        fi
    done
    
    log "❌ Failed to fix build issues after $max_attempts attempts"
    generate_status_report
    
    echo ""
    echo "=== Manual Investigation Required ==="
    echo "The automatic fixer could not resolve all issues."
    echo "Please check the generated report and logs for details."
    echo ""
    
    return 1
}

# Run main function
main "$@"
#!/bin/bash

# HolyBPF-rust Build Validator Script
# Validates the build system and runs comprehensive tests

set -e

echo "=== HolyBPF-rust Build Validator ==="
echo "Timestamp: $(date)"
echo ""

# Function to log with timestamp
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if we're in the right directory
    if [[ ! -f "Cargo.toml" ]]; then
        log "❌ Error: Cargo.toml not found. Are you in the project root?"
        exit 1
    fi
    
    # Check Rust installation
    if ! command -v cargo &> /dev/null; then
        log "❌ Error: Cargo not found. Please install Rust toolchain."
        log "   Install via: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        exit 1
    fi
    
    # Check Rust version
    RUST_VERSION=$(rustc --version 2>/dev/null || echo "unknown")
    log "ℹ️  Using Rust: $RUST_VERSION"
    
    # Check for required source files
    local required_files=(
        "src/main.rs"
        "src/pible/mod.rs"
        "src/tests.rs"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log "❌ Error: Required file not found: $file"
            exit 1
        fi
    done
    
    log "✅ Prerequisites check passed"
}

# Function to validate build
validate_build() {
    log "Validating cargo build..."
    
    # Create build output log
    local BUILD_OUTPUT="build_validation_output.log"
    
    if cargo build --verbose 2>&1 | tee "$BUILD_OUTPUT"; then
        log "✅ Build validation passed"
        
        # Check for warnings
        if grep -q "warning:" "$BUILD_OUTPUT"; then
            log "⚠️  Build completed with warnings - check $BUILD_OUTPUT for details"
        fi
        
        return 0
    else
        log "❌ Build validation failed"
        log "   Common fixes:"
        log "   - Check dependency versions in Cargo.toml"
        log "   - Ensure all required source files exist"
        log "   - Run 'cargo clean' and try again"
        return 1
    fi
}

# Function to validate tests
validate_tests() {
    log "Validating cargo test..."
    
    local TEST_OUTPUT="test_validation_output.log"
    
    if timeout 600 cargo test 2>&1 | tee "$TEST_OUTPUT"; then
        local test_count=$(grep -o "test result: ok\. [0-9]* passed" "$TEST_OUTPUT" | grep -o "[0-9]*" || echo "0")
        log "✅ Test validation passed - $test_count tests passed"
        return 0
    else
        log "❌ Test validation failed"
        log "   Check $TEST_OUTPUT for details"
        return 1
    fi
}

# Function to validate examples
validate_examples() {
    log "Validating example compilation..."
    
    local EXAMPLES_OUTPUT="examples_validation_output.log"
    local examples_passed=0
    local examples_failed=0
    
    local examples=(
        "examples/hello-world/src/main.hc"
        "examples/escrow/src/main.hc"
    )
    
    for example in "${examples[@]}"; do
        if [[ -f "$example" ]]; then
            log "Testing compilation of $example..."
            if cargo run --bin pible "$example" 2>&1 | tee -a "$EXAMPLES_OUTPUT"; then
                log "✅ Example compiled successfully: $example"
                ((examples_passed++))
            else
                log "❌ Example compilation failed: $example"
                ((examples_failed++))
            fi
        else
            log "⚠️  Example file not found: $example"
            ((examples_failed++))
        fi
    done
    
    log "Examples validation complete: $examples_passed passed, $examples_failed failed"
    
    if [[ $examples_failed -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Function to run clippy lints
validate_clippy() {
    log "Running clippy lints..."
    
    if cargo clippy --all-targets --all-features -- -D warnings 2>&1; then
        log "✅ Clippy validation passed"
        return 0
    else
        log "❌ Clippy validation failed"
        log "   Fix linting issues and try again"
        return 1
    fi
}

# Function to check formatting
validate_formatting() {
    log "Checking code formatting..."
    
    if cargo fmt --check 2>&1; then
        log "✅ Code formatting is correct"
        return 0
    else
        log "❌ Code formatting issues found"
        log "   Run 'cargo fmt' to fix formatting"
        return 1
    fi
}

# Main validation function
main() {
    log "Starting comprehensive build validation..."
    
    local total_failures=0
    
    # Run all validations
    check_prerequisites || exit 1
    validate_build || ((total_failures++))
    validate_tests || ((total_failures++))
    validate_examples || ((total_failures++))
    validate_clippy || ((total_failures++))
    validate_formatting || ((total_failures++))
    
    echo ""
    echo "=== Validation Summary ==="
    
    if [[ $total_failures -eq 0 ]]; then
        log "🎉 All validations passed successfully!"
        echo ""
        echo "Next steps:"
        echo "- Run tests: cargo test"
        echo "- Build examples: cargo run --bin pible examples/hello-world/src/main.hc"
        echo "- Start development: cargo run --help"
    else
        log "❌ $total_failures validations failed"
        echo ""
        echo "Please fix the issues above and run the validator again."
        exit 1
    fi
}

# Run main function
main "$@"
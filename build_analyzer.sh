#!/bin/bash

# Build Analysis and Fix Generator Script
# Analyzes the HolyBPF-rust build system for potential issues and generates fixes

set -e

echo "=== HolyBPF-rust Build Analysis & Fix Generator ==="
echo "Timestamp: $(date)"
echo ""

# Function to log with timestamp
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# Function to check Cargo.toml for issues
analyze_cargo_toml() {
    log "Analyzing Cargo.toml for potential issues..."
    
    if [[ ! -f "Cargo.toml" ]]; then
        log "❌ Error: Cargo.toml not found. Are you in the project root?"
        return 1
    fi
    
    local issues=0
    
    # Check for proper Rust edition
    if grep -q "edition = \"2021\"" Cargo.toml; then
        log "✅ Found Rust 2021 edition"
    else
        log "⚠️  Warning: Consider updating to Rust 2021 edition"
        ((issues++))
    fi
    
    # Check for required dependencies
    if grep -q "clap" Cargo.toml; then
        log "✅ Found clap dependency for CLI"
    else
        log "❌ Missing clap dependency for CLI"
        ((issues++))
    fi
    
    # Check for release profile optimization
    if grep -q "\[profile.release\]" Cargo.toml; then
        log "✅ Found release profile configuration"
    else
        log "⚠️  Warning: No release profile optimization found"
        ((issues++))
    fi
    
    # Check for test dependencies
    if grep -q "\[dev-dependencies\]" Cargo.toml; then
        log "✅ Found development dependencies"
    else
        log "❌ Missing development dependencies"
        ((issues++))
    fi
    
    return $issues
}

# Function to check for required source files
check_rust_sources() {
    log "Checking Rust source files..."
    
    local issues=0
    local sources=(
        "src/main.rs"
        "src/pible/mod.rs"
        "src/pible/lexer.rs"
        "src/pible/parser.rs"
        "src/pible/codegen.rs"
        "src/pible/compiler.rs"
        "src/tests.rs"
    )
    
    for source in "${sources[@]}"; do
        if [ ! -f "$source" ]; then
            log "❌ Missing source file: $source"
            ((issues++))
        else
            log "✅ Found source file: $source"
        fi
    done
    
    return $issues
}

# Function to check example programs
check_examples() {
    log "Checking example programs..."
    
    local issues=0
    local examples=(
        "examples/hello-world/src/main.hc"
        "examples/escrow/src/main.hc"
        "examples/yield-farming/src/main.hc"
        "examples/flash-loans/src/main.hc"
    )
    
    for example in "${examples[@]}"; do
        if [ ! -f "$example" ]; then
            log "❌ Missing example: $example"
            ((issues++))
        else
            log "✅ Found example: $example"
        fi
    done
    
    return $issues
}

# Function to generate fixes
generate_fixes() {
    log "Generating build fixes..."
    
    echo ""
    echo "=== Recommended Actions ==="
    echo "1. Ensure Rust toolchain is installed: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    echo "2. Run: cargo build"
    echo "3. Run: cargo test"
    echo "4. Build examples: cargo run --bin pible examples/hello-world/src/main.hc"
    echo ""
}

# Main execution
main() {
    log "Starting HolyBPF-rust build analysis..."
    
    local total_issues=0
    
    # Run analysis functions
    analyze_cargo_toml || ((total_issues += $?))
    check_rust_sources || ((total_issues += $?))
    check_examples || ((total_issues += $?))
    
    # Generate fixes if needed
    if [ $total_issues -gt 0 ]; then
        log "❌ Found $total_issues issues"
        generate_fixes
    else
        log "✅ Build analysis completed successfully!"
    fi
    
    echo ""
    log "Analysis complete. Total issues found: $total_issues"
    
    return $total_issues
}

# Run main function
main "$@"
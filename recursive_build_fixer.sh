#!/bin/bash

# Recursive Build Fixer Script for HolyBPF-zig
# Attempts to build and recursively fix issues until all errors are resolved

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAX_ITERATIONS=5
CURRENT_ITERATION=0

echo "=== HolyBPF-zig Recursive Build Fixer ==="
echo "Timestamp: $(date)"
echo "Max iterations: $MAX_ITERATIONS"
echo ""

# Function to log with timestamp
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# Function to check if Zig is available and install if possible
setup_zig() {
    log "Checking Zig installation..."
    
    if command -v zig &> /dev/null; then
        local zig_version=$(zig version)
        log "Found Zig version: $zig_version"
        
        # Check if version is 0.15.1 or later
        if [[ "$zig_version" =~ ^0\.1[5-9]\.|^0\.[2-9][0-9]\.|^[1-9] ]]; then
            log "✅ Zig version is 0.15.1 or later"
            return 0
        else
            log "⚠️  Zig version may be too old (need 0.15.1+)"
        fi
    fi
    
    # Try to find Zig in common locations
    local zig_paths=(
        "/opt/hostedtoolcache/zig/0.15.1/x64/zig"
        "/usr/local/bin/zig"
        "/opt/zig/zig"
        "/tmp/zig-linux-x86_64-0.15.1/zig"
    )
    
    for zig_path in "${zig_paths[@]}"; do
        if [ -f "$zig_path" ]; then
            log "Found Zig at: $zig_path"
            export PATH="$(dirname "$zig_path"):$PATH"
            return 0
        fi
    done
    
    log "❌ Zig 0.15.1+ not found"
    log "🔧 MANUAL FIX REQUIRED:"
    log "   1. Download Zig 0.15.1 from https://ziglang.org/download/0.15.1/"
    log "   2. Extract and add to PATH"
    log "   3. Re-run this script"
    return 1
}

# Function to apply a specific fix based on error pattern
apply_fix() {
    local error_pattern="$1"
    local fix_description="$2"
    
    log "Applying fix: $fix_description"
    
    case "$error_pattern" in
        "root_source_file")
            log "Fixing deprecated .root_source_file usage..."
            sed -i 's/\.root_source_file\s*=/\.root_src =/g' build.zig
            log "✅ Updated .root_source_file to .root_src"
            return 0
            ;;
            
        "b.path")
            log "Fixing deprecated b.path() usage..."
            sed -i 's/b\.path(\([^)]*\))/\.{ \.cwd_relative = \1 }/g' build.zig
            log "✅ Updated b.path() to LazyPath syntax"
            return 0
            ;;
            
        "enum_literal")
            log "Fixing enum literal syntax in build.zig.zon..."
            sed -i 's/\.name\s*=\s*"\([^"]*\)"/\.name = \.\1/g' build.zig.zon
            log "✅ Updated string to enum literal in .name field"
            return 0
            ;;
            
        "missing_fingerprint")
            log "Adding fingerprint to build.zig.zon..."
            if ! grep -q "fingerprint" build.zig.zon; then
                sed -i 's/\.version = "\([^"]*\)",/\.version = "\1",\n    \.fingerprint = 0xe5034f2115cc8bf1,/' build.zig.zon
                log "✅ Added fingerprint field"
            fi
            return 0
            ;;
            
        "missing_dependencies")
            log "Ensuring dependencies section exists..."
            if ! grep -q "dependencies" build.zig.zon; then
                sed -i 's/\.fingerprint = \([^,]*\),/\.fingerprint = \1,\n    \.dependencies = \.{},/' build.zig.zon
                log "✅ Added dependencies section"
            fi
            return 0
            ;;
            
        *)
            log "⚠️  Unknown error pattern: $error_pattern"
            return 1
            ;;
    esac
}

# Function to analyze build output and determine fixes
analyze_and_fix_errors() {
    local build_log="$1"
    local fixes_applied=0
    
    log "Analyzing build errors..."
    
    # Check for specific error patterns and apply fixes
    if grep -q "no field named 'root_source_file'" "$build_log"; then
        apply_fix "root_source_file" "Fix deprecated .root_source_file field"
        ((fixes_applied++))
    fi
    
    if grep -q "b\.path" "$build_log"; then
        apply_fix "b.path" "Fix deprecated b.path() usage"
        ((fixes_applied++))
    fi
    
    if grep -q "expected enum literal" "$build_log"; then
        apply_fix "enum_literal" "Fix enum literal syntax"
        ((fixes_applied++))
    fi
    
    # Check for missing fields that might be required
    if ! grep -q "fingerprint" build.zig.zon; then
        apply_fix "missing_fingerprint" "Add missing fingerprint field"
        ((fixes_applied++))
    fi
    
    if ! grep -q "dependencies" build.zig.zon; then
        apply_fix "missing_dependencies" "Add missing dependencies section"
        ((fixes_applied++))
    fi
    
    return $fixes_applied
}

# Function to attempt build and capture output
attempt_build() {
    local iteration=$1
    local build_log="build_logs/build_attempt_${iteration}.log"
    
    log "Build attempt #$iteration"
    
    # Ensure build_logs directory exists
    mkdir -p build_logs
    
    # Clean previous build
    rm -rf zig-cache zig-out 2>/dev/null || true
    
    # Attempt build with timeout
    if timeout 300 zig build --verbose 2>&1 | tee "$build_log"; then
        log "✅ Build successful!"
        return 0
    else
        log "❌ Build failed - analyzing errors..."
        return 1
    fi
}

# Function to attempt tests if build succeeds
attempt_tests() {
    local iteration=$1
    local test_log="build_logs/test_attempt_${iteration}.log"
    
    log "Running tests for build #$iteration"
    
    if timeout 600 zig build test 2>&1 | tee "$test_log"; then
        log "✅ Tests passed!"
        return 0
    else
        log "❌ Tests failed - see $test_log for details"
        return 1
    fi
}

# Main recursive build loop
recursive_build() {
    while [ $CURRENT_ITERATION -lt $MAX_ITERATIONS ]; do
        ((CURRENT_ITERATION++))
        log "=== ITERATION $CURRENT_ITERATION of $MAX_ITERATIONS ==="
        
        # Attempt build
        if attempt_build $CURRENT_ITERATION; then
            log "Build successful on iteration $CURRENT_ITERATION"
            
            # If build succeeds, try tests
            if attempt_tests $CURRENT_ITERATION; then
                log "🎉 SUCCESS: Both build and tests passed!"
                return 0
            else
                log "Build passed but tests failed - manual investigation needed"
                return 1
            fi
        else
            # Build failed - analyze and fix
            local build_log="build_logs/build_attempt_${CURRENT_ITERATION}.log"
            local fixes_applied=0
            
            analyze_and_fix_errors "$build_log"
            fixes_applied=$?
            
            if [ $fixes_applied -eq 0 ]; then
                log "❌ No automated fixes available for current errors"
                log "Manual intervention required - see $build_log"
                return 1
            else
                log "Applied $fixes_applied automated fixes - retrying..."
            fi
        fi
    done
    
    log "❌ Maximum iterations ($MAX_ITERATIONS) reached without success"
    return 1
}

# Generate final report
generate_report() {
    local success=$1
    
    echo ""
    echo "=== FINAL REPORT ==="
    echo "Iterations completed: $CURRENT_ITERATION"
    echo "Result: $([ $success -eq 0 ] && echo "SUCCESS ✅" || echo "FAILED ❌")"
    echo ""
    
    if [ $success -eq 0 ]; then
        echo "🎉 BUILD AND TESTS COMPLETED SUCCESSFULLY"
        echo ""
        echo "Project is ready for development:"
        echo "- Compiler binary: ./zig-out/bin/pible"
        echo "- Run tests: zig build test"
        echo "- Build examples: zig build hello-world"
    else
        echo "❌ MANUAL INTERVENTION REQUIRED"
        echo ""
        echo "Issues that need manual fixing:"
        
        # List remaining issues from last build log
        if [ -f "build_logs/build_attempt_${CURRENT_ITERATION}.log" ]; then
            echo "Last build errors:"
            grep "error:" "build_logs/build_attempt_${CURRENT_ITERATION}.log" | head -5
        fi
        
        echo ""
        echo "Recommended actions:"
        echo "1. Review build logs in build_logs/ directory"
        echo "2. Check Zig version compatibility (need 0.15.1+)"
        echo "3. Verify all source files exist and are valid"
        echo "4. Consider updating build system for newer Zig versions"
    fi
    
    echo ""
    echo "All logs saved in build_logs/ directory"
}

# Main execution
main() {
    log "Starting recursive build process..."
    
    # Check prerequisites
    if [ ! -f "build.zig" ]; then
        log "❌ Error: build.zig not found. Are you in the project root?"
        exit 1
    fi
    
    # Setup Zig
    if ! setup_zig; then
        log "❌ Cannot proceed without Zig 0.15.1+"
        exit 1
    fi
    
    # Run recursive build process
    if recursive_build; then
        generate_report 0
        exit 0
    else
        generate_report 1
        exit 1
    fi
}

# Run main function
main "$@"
#!/bin/bash

# HolyBPF-zig Build Validator Script
# This script attempts to build the repository and analyze build errors

set -e

echo "=== HolyBPF-zig Build Validator ==="
echo "Timestamp: $(date)"
echo ""

# Function to log with timestamp
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# Function to analyze build output for issues
analyze_build_output() {
    local output_file="$1"
    local phase="$2"
    
    log "Analyzing $phase output for errors..."
    
    # Check for common error patterns
    if grep -q "error:" "$output_file"; then
        log "❌ Found errors in $phase:"
        grep "error:" "$output_file" | head -10
        echo ""
        return 1
    fi
    
    if grep -q "warning:" "$output_file"; then
        log "⚠️  Found warnings in $phase:"
        grep "warning:" "$output_file" | head -5
        echo ""
    fi
    
    log "✅ No critical errors found in $phase"
    return 0
}

# Function to suggest fixes based on error patterns
suggest_fixes() {
    local output_file="$1"
    local phase="$2"
    
    log "Generating fix suggestions for $phase errors..."
    
    # Check for Zig version compatibility issues
    if grep -q "no field named" "$output_file"; then
        log "🔧 Fix suggestion: Zig API compatibility issue detected"
        log "   - Update build.zig to use correct field names for your Zig version"
        log "   - Check Zig documentation for API changes"
    fi
    
    # Check for missing dependencies
    if grep -q "dependency.*not found" "$output_file"; then
        log "🔧 Fix suggestion: Missing dependency detected"
        log "   - Check build.zig.zon for correct dependency URLs and hashes"
        log "   - Ensure network access for dependency fetching"
    fi
    
    # Check for syntax errors
    if grep -q "expected.*literal" "$output_file"; then
        log "🔧 Fix suggestion: Syntax error in .zon file"
        log "   - Check build.zig.zon syntax for enum literals"
        log "   - Ensure proper field naming conventions"
    fi
    
    # Check for file not found errors
    if grep -q "FileNotFound\|No such file" "$output_file"; then
        log "🔧 Fix suggestion: Missing source files"
        log "   - Verify all source files exist in expected locations"
        log "   - Check file paths in build.zig"
    fi
}

# Check prerequisites
log "Checking prerequisites..."

# Check if we're in the right directory
if [ ! -f "build.zig" ]; then
    log "❌ Error: build.zig not found. Are you in the project root?"
    exit 1
fi

# Check for Zig installation
if ! command -v zig &> /dev/null; then
    log "❌ Error: Zig not found in PATH"
    log "🔧 Fix suggestion: Install Zig 0.15.1 or later"
    log "   - Download from: https://ziglang.org/download/"
    log "   - Add to PATH or use package manager"
    exit 1
fi

# Check Zig version
ZIG_VERSION=$(zig version 2>/dev/null || echo "unknown")
log "Found Zig version: $ZIG_VERSION"

# Create output directory for logs
mkdir -p build_logs

# Phase 1: Clean build
log "Phase 1: Cleaning previous build artifacts..."
rm -rf zig-cache zig-out build_logs/*.log 2>/dev/null || true
log "✅ Cleaned build artifacts"

# Phase 2: Attempt build
log "Phase 2: Attempting build..."
BUILD_OUTPUT="build_logs/build.log"
BUILD_SUCCESS=false

if zig build --verbose 2>&1 | tee "$BUILD_OUTPUT"; then
    log "✅ Build completed successfully"
    BUILD_SUCCESS=true
else
    log "❌ Build failed"
    BUILD_SUCCESS=false
fi

# Analyze build output
if ! analyze_build_output "$BUILD_OUTPUT" "build"; then
    suggest_fixes "$BUILD_OUTPUT" "build"
fi

# Phase 3: If build succeeded, try tests
if [ "$BUILD_SUCCESS" = true ]; then
    log "Phase 3: Running tests..."
    TEST_OUTPUT="build_logs/test.log"
    TEST_SUCCESS=false
    
    if timeout 600 zig build test 2>&1 | tee "$TEST_OUTPUT"; then
        log "✅ Tests completed successfully"
        TEST_SUCCESS=true
    else
        log "❌ Tests failed or timed out"
        TEST_SUCCESS=false
    fi
    
    # Analyze test output
    if ! analyze_build_output "$TEST_OUTPUT" "test"; then
        suggest_fixes "$TEST_OUTPUT" "test"
    fi
else
    log "⏭️  Skipping tests due to build failure"
fi

# Phase 4: If build succeeded, try examples
if [ "$BUILD_SUCCESS" = true ]; then
    log "Phase 4: Building examples..."
    EXAMPLES_OUTPUT="build_logs/examples.log"
    
    for example in hello-world escrow solana-token; do
        log "Building example: $example"
        if zig build "$example" 2>&1 | tee -a "$EXAMPLES_OUTPUT"; then
            log "✅ Example $example built successfully"
        else
            log "❌ Example $example failed to build"
        fi
    done
    
    # Analyze examples output
    if ! analyze_build_output "$EXAMPLES_OUTPUT" "examples"; then
        suggest_fixes "$EXAMPLES_OUTPUT" "examples"
    fi
else
    log "⏭️  Skipping examples due to build failure"
fi

# Phase 5: Summary and recommendations
log "Phase 5: Build validation summary"
echo ""
echo "=== BUILD VALIDATION SUMMARY ==="
echo "Build Success: $BUILD_SUCCESS"
if [ "$BUILD_SUCCESS" = true ]; then
    echo "Test Success: $TEST_SUCCESS"
fi
echo ""

# Generate actionable recommendations
log "Generating actionable recommendations..."

if [ "$BUILD_SUCCESS" = false ]; then
    echo "PRIORITY 1: Fix build errors"
    echo "- Review build_logs/build.log for specific errors"
    echo "- Apply suggested fixes above"
    echo "- Re-run this script to verify fixes"
fi

if [ "$BUILD_SUCCESS" = true ] && [ "$TEST_SUCCESS" = false ]; then
    echo "PRIORITY 2: Fix test failures"  
    echo "- Review build_logs/test.log for failing tests"
    echo "- Focus on test-specific issues"
fi

echo ""
echo "All build logs saved in build_logs/ directory"
echo "To re-run validation: ./build_validator.sh"
echo ""

# Exit with appropriate code
if [ "$BUILD_SUCCESS" = true ]; then
    exit 0
else
    exit 1
fi
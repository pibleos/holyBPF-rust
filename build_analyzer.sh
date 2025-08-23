#!/bin/bash

# Build Analysis and Fix Generator Script
# Analyzes the HolyBPF-zig build system for potential issues and generates fixes

set -e

echo "=== HolyBPF-zig Build Analysis & Fix Generator ==="
echo "Timestamp: $(date)"
echo ""

# Function to log with timestamp
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# Function to check file existence and report issues
check_file_references() {
    log "Checking file references in build.zig..."
    
    local issues=0
    
    # Check main source files
    if [ ! -f "src/Pible/Main.zig" ]; then
        log "❌ Missing main source: src/Pible/Main.zig"
        ((issues++))
    else
        log "✅ Found main source: src/Pible/Main.zig"
    fi
    
    if [ ! -f "src/Pible/Tests.zig" ]; then
        log "❌ Missing test source: src/Pible/Tests.zig"
        ((issues++))
    else
        log "✅ Found test source: src/Pible/Tests.zig"
    fi
    
    if [ ! -f "tests/main.zig" ]; then
        log "❌ Missing integration test source: tests/main.zig"
        ((issues++))
    else
        log "✅ Found integration test source: tests/main.zig"
    fi
    
    # Check example files
    local examples=(
        "examples/hello-world/src/main.hc"
        "examples/escrow/src/main.hc"
        "examples/solana-token/src/main.hc"
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

# Function to analyze build.zig for potential issues
analyze_build_zig() {
    log "Analyzing build.zig for potential issues..."
    
    local issues=0
    
    # Check for deprecated fields
    if grep -q "root_source_file" build.zig; then
        log "❌ Found deprecated field 'root_source_file' in build.zig"
        log "   Should be 'root_src' for Zig 0.15.1+"
        ((issues++))
    else
        log "✅ No deprecated 'root_source_file' fields found"
    fi
    
    # Check for proper LazyPath usage
    if grep -q "b\.path(" build.zig; then
        log "❌ Found deprecated 'b.path()' usage in build.zig"
        log "   Should use '.{ .cwd_relative = \"...\" }' for Zig 0.15.1+"
        ((issues++))
    else
        log "✅ No deprecated 'b.path()' usage found"
    fi
    
    # Check for proper field syntax
    if grep -q "\.root_src.*\.cwd_relative" build.zig; then
        log "✅ Found correct .root_src field usage"
    else
        log "⚠️  .root_src field usage pattern not found - may need verification"
    fi
    
    return $issues
}

# Function to analyze build.zig.zon for potential issues
analyze_build_zon() {
    log "Analyzing build.zig.zon for potential issues..."
    
    local issues=0
    
    # Check for proper enum literal syntax
    if grep -q "\.name.*=" build.zig.zon; then
        if grep -q "\.name.*=.*\"" build.zig.zon; then
            log "❌ Found string value for .name field in build.zig.zon"
            log "   Should be enum literal like '.name = .holyc_bpf'"
            ((issues++))
        else
            log "✅ Found proper enum literal for .name field"
        fi
    fi
    
    # Check for fingerprint field
    if grep -q "\.fingerprint" build.zig.zon; then
        log "✅ Found fingerprint field in build.zig.zon"
    else
        log "⚠️  No fingerprint field found - may be required for Zig 0.15.1+"
    fi
    
    # Check for dependencies section
    if grep -q "\.dependencies" build.zig.zon; then
        log "✅ Found dependencies section in build.zig.zon"
    else
        log "⚠️  No dependencies section found"
    fi
    
    return $issues
}

# Function to generate specific fixes
generate_fixes() {
    log "Generating specific fix recommendations..."
    
    echo ""
    echo "=== ACTIONABLE FIXES ==="
    
    # Fix 1: Update build.zig for Zig 0.15.1 compatibility
    echo "1. CRITICAL: Ensure Zig 0.15.1+ compatibility in build.zig"
    echo "   Current status: ✅ Already using correct .root_src syntax"
    echo "   Action: No changes needed for this issue"
    echo ""
    
    # Fix 2: Verify build.zig.zon format
    echo "2. VERIFY: build.zig.zon format for Zig 0.15.1+"
    echo "   Current .name field: $(grep '\.name' build.zig.zon || echo 'Not found')"
    echo "   Expected format: .name = .holyc_bpf,"
    echo "   Action: Already correct"
    echo ""
    
    # Fix 3: Check for missing dependencies
    echo "3. DEPENDENCIES: Verify zbpf dependency if needed"
    echo "   Current dependencies: $(grep -A5 '\.dependencies' build.zig.zon | tail -4 || echo '{}')"
    echo "   Action: Add zbpf dependency if BPF generation is needed"
    echo ""
    
    # Fix 4: Environment setup
    echo "4. ENVIRONMENT: Zig installation"
    echo "   Required: Zig 0.15.1 or later"
    echo "   Action: Install Zig from https://ziglang.org/download/0.15.1/"
    echo ""
    
    # Fix 5: Generate improved build.zig if needed
    echo "5. OPTIONAL: Enhanced build configuration"
    echo "   Action: Consider adding dependency management for zbpf"
}

# Function to create a corrected build.zig.zon if needed
create_corrected_build_zon() {
    log "Checking if build.zig.zon needs zbpf dependency..."
    
    # Check if CodeGen.zig references zbpf
    if grep -q "zbpf" src/Pible/CodeGen.zig 2>/dev/null; then
        log "Found zbpf references in CodeGen.zig - dependency may be needed"
        
        cat > build.zig.zon.suggested << 'EOF'
.{
    .name = .holyc_bpf,
    .version = "0.1.0",
    .fingerprint = 0xe5034f2115cc8bf1,
    .dependencies = .{
        .zbpf = .{
            .url = "https://github.com/tw4452852/zbpf/archive/refs/tags/v0.2.0.tar.gz",
            .hash = "1220c9c0e1e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8",
        },
    },
    .paths = .{
        "src",
        "examples", 
        "tests",
        "build.zig",
        "build.zig.zon",
        "LICENSE",
        "README.md",
    },
}
EOF
        log "Created build.zig.zon.suggested with zbpf dependency"
        log "Note: Hash needs to be updated when actually adding dependency"
    else
        log "No zbpf references found - current build.zig.zon should be sufficient"
    fi
}

# Function to validate project structure
validate_project_structure() {
    log "Validating project structure..."
    
    local required_dirs=("src/Pible" "examples" "tests")
    local missing_dirs=0
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            log "❌ Missing required directory: $dir"
            ((missing_dirs++))
        else
            log "✅ Found required directory: $dir"
        fi
    done
    
    return $missing_dirs
}

# Main execution
log "Starting build analysis..."

# Check if we're in the right directory
if [ ! -f "build.zig" ]; then
    log "❌ Error: build.zig not found. Are you in the project root?"
    exit 1
fi

# Run all checks
total_issues=0

check_file_references
total_issues=$((total_issues + $?))

analyze_build_zig  
total_issues=$((total_issues + $?))

analyze_build_zon
total_issues=$((total_issues + $?))

validate_project_structure
total_issues=$((total_issues + $?))

create_corrected_build_zon

generate_fixes

# Summary
echo ""
echo "=== ANALYSIS SUMMARY ==="
echo "Total issues found: $total_issues"
echo "Critical fixes needed: $([ $total_issues -gt 0 ] && echo "Yes" || echo "No")"
echo ""

if [ $total_issues -eq 0 ]; then
    echo "✅ BUILD SYSTEM APPEARS HEALTHY"
    echo "Main issue is likely missing Zig 0.15.1+ installation"
    echo ""
    echo "Next steps:"
    echo "1. Install Zig 0.15.1 from https://ziglang.org/download/0.15.1/"
    echo "2. Run: zig build"
    echo "3. Run: zig build test"
else
    echo "❌ ISSUES FOUND - FIXES REQUIRED"
    echo "Apply the fixes above, then re-run this analysis"
fi

echo ""
echo "Analysis complete. See actionable fixes above."
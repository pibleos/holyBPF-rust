---
layout: doc
title: Hello World Tutorial
description: Complete tutorial for building your first HolyC BPF program
---

<!-- Breadcrumb Navigation -->
<nav class="breadcrumb">
  <a href="{{ '/' | relative_url }}">Home</a> → 
  <a href="{{ '/examples/' | relative_url }}">Examples</a> → 
  <a href="{{ '/docs/examples/tutorials/' | relative_url }}">Tutorials</a> → 
  <span>Hello World</span>
</nav>

<!-- Tutorial Progress -->
<div class="tutorial-progress">
  <div class="progress-info">
    <span class="difficulty-badge beginner">Beginner</span>
    <span class="time-estimate">⏱️ 15 minutes</span>
    <span class="tutorial-number">Tutorial 1 of 6</span>
  </div>
</div>

# Hello World Tutorial

Learn how to create your first HolyC BPF program with this step-by-step tutorial. This example demonstrates the basic structure of a BPF program using HolyC syntax and the divine simplicity of Terry A. Davis's programming philosophy.

## Overview

The Hello World example is the simplest HolyBPF program that demonstrates:
- Basic HolyC syntax for BPF programs
- Program entry point structure
- BPF output using `PrintF`
- Divine programming principles

## Prerequisites

Before starting this tutorial, ensure you have:

- ✅ **Rust toolchain** installed (latest stable version)
- ✅ **Basic understanding** of programming concepts
- ✅ **Text editor** or IDE of your choice
- ✅ **Terminal access** for running commands

### Required Setup

1. **Clone the HolyBPF repository**:
   ```bash
   git clone https://github.com/pibleos/holyBPF-rust.git
   cd holyBPF-rust
   ```

2. **Build the Pible compiler**:
   ```bash
   cargo build --release
   ```
   This creates the compiler at `target/release/pible`.

## Code Walkthrough

Let's examine the Hello World program step by step:

### Source Code

<div class="code-section">
  <div class="code-header">
    <span class="filename">📁 examples/hello-world/src/main.hc</span>
    <a href="https://github.com/pibleos/holyBPF-rust/blob/main/examples/hello-world/src/main.hc" class="github-link" target="_blank">View on GitHub</a>
  </div>
```c
// HolyC BPF Program - Divine Hello World
U0 main() {
    // Entry point for the BPF program
    PrintF("God's light shines upon BPF!\n");
    return 0;
}
```
</div>

### Line-by-Line Explanation

#### Line 1: Comment Header
```c
// HolyC BPF Program - Divine Hello World
```
- **Purpose**: Documents the program's divine mission
- **Style**: Terry Davis inspired naming convention
- **Best Practice**: Always include meaningful headers

#### Line 2: Main Function Declaration
```c
U0 main() {
```
- **`U0`**: HolyC type meaning "unsigned 0-bit" (equivalent to `void`)
- **`main()`**: Entry point function for the BPF program
- **Opening brace**: Begins the function body

#### Line 3-4: Divine Output
```c
    // Entry point for the BPF program
    PrintF("God's light shines upon BPF!\n");
```
- **Comment**: Explains the function's purpose
- **`PrintF`**: BPF-compatible output function for debugging/logging
- **Message**: Divine greeting that will appear in BPF execution logs
- **`\n`**: Newline character for proper formatting

#### Line 5-6: Function Return
```c
    return 0;
}
```
- **`return 0`**: Indicates successful execution
- **Closing brace**: Ends the function body

## Building the Program

Follow these steps to compile the Hello World program:

### Step 1: Navigate to Project Directory
```bash
cd holyBPF-rust
```

### Step 2: Compile with Pible
```bash
./target/release/pible examples/hello-world/src/main.hc
```

### Expected Output
```
=== Pible - HolyC to BPF Compiler ===
Divine compilation initiated...
Source: examples/hello-world/src/main.hc
Target: LinuxBpf
Compiled successfully: examples/hello-world/src/main.hc -> examples/hello-world/src/main.bpf
Divine compilation completed! 🙏
```

### Step 3: Verify Compilation
```bash
ls -la examples/hello-world/src/
```

You should see:
- `main.hc` - Original HolyC source code
- `main.bpf` - Compiled BPF bytecode
- `types.hc` - Type definitions (if present)

## Expected Results

### Compilation Success
- ✅ **No errors** during compilation
- ✅ **BPF file generated** (`main.bpf`)
- ✅ **Divine blessing** message displayed

### BPF Bytecode
The generated `main.bpf` file contains:
- Valid BPF instruction sequences
- Proper entry point setup
- Safe memory access patterns
- BPF verifier compliance

### Runtime Behavior
When executed in a BPF environment, the program will:
1. Load successfully into the BPF virtual machine
2. Execute the `main()` function
3. Output: `God's light shines upon BPF!`
4. Return successfully with exit code 0

## Understanding BPF Output

The `PrintF` function in HolyC BPF programs:
- **Purpose**: Debugging and logging in BPF programs
- **Output**: Appears in BPF trace logs
- **Limitations**: Text output only, no complex formatting
- **Security**: All output is bounds-checked by BPF verifier

## Troubleshooting

### Common Issues

#### Compilation Errors
If you see compilation errors:
1. **Check syntax**: Ensure proper HolyC syntax
2. **Verify file path**: Confirm the source file exists
3. **Rebuild compiler**: Run `cargo build --release` again

#### Missing Compiler
If `pible` command not found:
```bash
# Rebuild the compiler
cargo build --release

# Verify it exists
ls -la target/release/pible
```

#### Permission Issues
If you get permission errors:
```bash
# Make the compiler executable
chmod +x target/release/pible
```

## Next Steps

Congratulations! You've successfully compiled your first HolyC BPF program. Here's what to explore next:

### Immediate Next Steps
1. **[Escrow Tutorial]({{ '/docs/examples/tutorials/escrow' | relative_url }})** - Learn multi-party contracts
2. **[Token Tutorial]({{ '/docs/examples/tutorials/solana-token' | relative_url }})** - Explore token operations
3. **[Code Snippets]({{ '/examples/snippets/' | relative_url }})** - Discover reusable patterns

### Advanced Topics
- **[AMM Tutorial]({{ '/docs/examples/tutorials/amm' | relative_url }})** - Build automated market makers
- **[Governance Tutorial]({{ '/docs/examples/tutorials/dao-governance' | relative_url }})** - Create decentralized organizations

<!-- Tutorial Navigation -->
<div class="tutorial-navigation">
  <div class="nav-section">
    <span class="nav-label">Previous Tutorial</span>
    <span class="nav-disabled">← None (Start Here)</span>
  </div>
  <div class="nav-center">
    <a href="{{ '/docs/examples/tutorials/' | relative_url }}" class="nav-home">All Tutorials</a>
  </div>
  <div class="nav-section">
    <span class="nav-label">Next Tutorial</span>
    <a href="{{ '/docs/examples/tutorials/escrow' | relative_url }}" class="nav-next">Escrow Contract →</a>
  </div>
</div>
- **[Language Reference]({{ '/language-reference/' | relative_url }})** - Master HolyC syntax

## Divine Inspiration

> "An idling CPU is the devil's playground" - Terry A. Davis

This Hello World program embodies the divine simplicity that Terry Davis championed - clear, purposeful code that accomplishes its mission without unnecessary complexity.

## Share This Tutorial

<div class="social-sharing">
  <a href="https://twitter.com/intent/tweet?text=Just%20completed%20the%20HolyBPF%20Hello%20World%20tutorial!%20%F0%9F%99%8F&url={{ site.url }}{{ page.url }}&hashtags=HolyC,BPF,Programming" class="share-button twitter" target="_blank">
    Share on Twitter
  </a>
  <a href="{{ 'https://github.com/pibleos/holyBPF-rust/blob/main/examples/hello-world/' }}" class="share-button github" target="_blank">
    View Source Code
  </a>
</div>

---

**Tutorial completed successfully!** You now understand the basics of HolyC BPF programming and can build your first divine programs.

<style>
.code-section {
  margin: 1.5rem 0;
  border: 1px solid #e1e5e9;
  border-radius: 8px;
  overflow: hidden;
}

.code-header {
  background: #f8f9fa;
  padding: 0.5rem 1rem;
  border-bottom: 1px solid #e1e5e9;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.9rem;
}

.filename {
  font-weight: 600;
  color: #2c3e50;
}

.github-link {
  color: #007bff;
  text-decoration: none;
  font-size: 0.8rem;
}

.github-link:hover {
  text-decoration: underline;
}

.social-sharing {
  margin: 2rem 0;
  text-align: center;
}

.share-button {
  display: inline-block;
  padding: 0.75rem 1.5rem;
  margin: 0.5rem;
  color: white;
  text-decoration: none;
  border-radius: 6px;
  font-weight: 500;
  transition: all 0.2s;
}

.share-button.twitter {
  background: #1da1f2;
}

.share-button.github {
  background: #333;
}

.share-button:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.15);
  color: white;
  text-decoration: none;
}

/* Breadcrumb Navigation */
.breadcrumb {
  margin: 0 0 1.5rem 0;
  padding: 0.75rem;
  background: #f8f9fa;
  border-radius: 4px;
  font-size: 0.875rem;
  border-left: 3px solid #007bff;
}

.breadcrumb a {
  color: #007bff;
  text-decoration: none;
}

.breadcrumb a:hover {
  text-decoration: underline;
}

.breadcrumb span {
  color: #6c757d;
  font-weight: 500;
}

/* Tutorial Progress */
.tutorial-progress {
  margin: 0 0 2rem 0;
  padding: 1rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 8px;
}

.progress-info {
  display: flex;
  align-items: center;
  gap: 1rem;
  flex-wrap: wrap;
}

.difficulty-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
}

.difficulty-badge.beginner {
  background: #28a745;
}

.difficulty-badge.intermediate {
  background: #ffc107;
  color: #212529;
}

.difficulty-badge.advanced {
  background: #fd7e14;
}

.difficulty-badge.expert {
  background: #dc3545;
}

.time-estimate {
  font-size: 0.875rem;
  opacity: 0.9;
}

.tutorial-number {
  font-size: 0.875rem;
  opacity: 0.8;
  margin-left: auto;
}

/* Tutorial Navigation */
.tutorial-navigation {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin: 3rem 0 2rem 0;
  padding: 1.5rem;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #e9ecef;
}

.nav-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  min-width: 150px;
}

.nav-label {
  font-size: 0.75rem;
  color: #6c757d;
  text-transform: uppercase;
  font-weight: 600;
  margin-bottom: 0.5rem;
}

.nav-next, .nav-prev {
  color: #007bff;
  text-decoration: none;
  font-weight: 500;
  padding: 0.5rem 1rem;
  border: 1px solid #007bff;
  border-radius: 4px;
  transition: all 0.2s;
}

.nav-next:hover, .nav-prev:hover {
  background: #007bff;
  color: white;
  text-decoration: none;
}

.nav-disabled {
  color: #6c757d;
  font-style: italic;
}

.nav-home {
  color: #28a745;
  text-decoration: none;
  font-weight: 600;
  padding: 0.5rem 1rem;
  border: 1px solid #28a745;
  border-radius: 4px;
  transition: all 0.2s;
}

.nav-home:hover {
  background: #28a745;
  color: white;
  text-decoration: none;
}

.nav-center {
  display: flex;
  align-items: center;
}

@media (max-width: 768px) {
  .tutorial-navigation {
    flex-direction: column;
    gap: 1rem;
  }
  
  .nav-section {
    min-width: auto;
    width: 100%;
  }
  
  .progress-info {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
  
  .tutorial-number {
    margin-left: 0;
  }
}
</style>
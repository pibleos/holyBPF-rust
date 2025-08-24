//! # Pible - HolyC to BPF Compiler
//!
//! A divine bridge between Terry Davis's HolyC and BPF runtimes, allowing HolyC programs
//! to run in Linux kernel and Solana blockchain environments.
//!
//! ## Overview
//!
//! Pible is a compiler that transforms HolyC programs into BPF (Berkeley Packet Filter) bytecode.
//! This enables HolyC programs to run with divine efficiency in:
//!
//! - **Linux Kernel Space**: Using eBPF for system programming
//! - **Solana Blockchain**: As on-chain programs with CPI support
//! - **BPF Virtual Machine**: For testing and emulation
//!
//! ## Quick Start
//!
//! ```rust
//! use pible::{Compiler, CompileOptions, CompileTarget};
//!
//! # fn main() -> Result<(), Box<dyn std::error::Error>> {
//! // Create a new compiler instance
//! let compiler = Compiler::new();
//!
//! // Configure compilation options
//! let options = CompileOptions {
//!     target: CompileTarget::LinuxBpf,
//!     generate_idl: false,
//!     enable_vm_testing: false,
//!     solana_program_id: None,
//!     output_directory: None,
//!     output_path: Some("output.bpf".to_string()),
//! };
//!
//! // Compile a HolyC program (this would normally read from a file)
//! // compiler.compile_file("program.hc", &options)?;
//! # Ok(())
//! # }
//! ```
//!
//! ## Architecture
//!
//! The compiler consists of several divine components:
//!
//! - [`pible::lexer`]: Tokenizes HolyC source code into language tokens
//! - [`pible::parser`]: Builds Abstract Syntax Trees (AST) from tokens  
//! - [`pible::codegen`]: Transforms AST into sacred BPF bytecode
//! - [`pible::bpf_vm`]: Built-in BPF virtual machine for testing
//! - [`pible::solana_bpf`]: Solana-specific BPF program generation
//!
//! ## Compilation Targets
//!
//! Pible supports multiple compilation targets through [`CompileTarget`]:
//!
//! ### Linux BPF
//! Generate eBPF programs for Linux kernel execution:
//! ```rust
//! # use pible::{CompileTarget, CompileOptions};
//! let options = CompileOptions {
//!     target: CompileTarget::LinuxBpf,
//!     ..Default::default()
//! };
//! ```
//!
//! ### Solana BPF  
//! Generate Solana programs with IDL support:
//! ```rust
//! # use pible::{CompileTarget, CompileOptions};
//! let options = CompileOptions {
//!     target: CompileTarget::SolanaBpf,
//!     generate_idl: true,
//!     ..Default::default()
//! };
//! ```
//!
//! ### BPF Virtual Machine
//! Test programs using the built-in VM:
//! ```rust
//! # use pible::{CompileTarget, CompileOptions};
//! let options = CompileOptions {
//!     target: CompileTarget::BpfVm,
//!     enable_vm_testing: true,
//!     ..Default::default()
//! };
//! ```
//!
//! ## HolyC Language Support
//!
//! Pible supports Terry A. Davis's HolyC language constructs:
//!
//! - **Data Types**: `U0`, `U8`, `U16`, `U32`, `U64`, `I8`, `I16`, `I32`, `I64`, `F64`, `Bool`
//! - **Control Flow**: `if`/`else`, `while`, `for`, `return`, `break`, `continue`
//! - **Functions**: Function declarations with parameters and return types
//! - **Classes**: Basic object-oriented programming constructs
//! - **Built-ins**: `PrintF` and other divine functions
//! - **Export**: Solana program entry points with `export`
//!
//! ## Error Handling
//!
//! The compiler provides comprehensive error reporting through:
//!
//! - [`CompileError`]: High-level compilation errors
//! - [`LexError`]: Tokenization and syntax errors
//! - [`ParseError`]: AST construction errors  
//! - [`CodeGenError`]: BPF code generation errors
//!
//! ## Features
//!
//! - `default`: Enables Solana BPF support
//! - `solana-bpf`: Solana blockchain program generation
//! - `linux-bpf`: Linux eBPF program generation
//! - `vm-testing`: Built-in BPF virtual machine
//!
//! ## In Memoriam
//!
//! This project is dedicated to Terry A. Davis (1969-2018), whose vision of divine computing
//! continues to inspire us all. His HolyC language and TempleOS represent a unique approach
//! to programming that emphasized simplicity, directness, and divine inspiration.
//!
//! > "God's temple is programming..." - Terry A. Davis
//!
//! Through Pible, we bring Terry's sacred language to modern BPF runtimes, allowing his
//! divine code to execute with blessed efficiency in kernel space and blockchain environments.

#![cfg_attr(docsrs, feature(doc_cfg))]
#![warn(missing_docs)]

pub mod pible;

// Re-export main types for easy access
pub use pible::{
    bpf_vm::{BpfVm, VmError},
    codegen::{BpfInstruction, CodeGen, CodeGenError},
    compiler::{CompileError, CompileOptions, CompileTarget, Compiler},
    lexer::{LexError, Lexer, Token, TokenType},
    parser::{Node, NodeType, ParseError, Parser},
    solana_bpf::{SolanaBpf, SolanaError},
};

/// The current version of the Pible compiler.
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// Divine blessing for successful compilation.
pub const DIVINE_BLESSING: &str = "🙏 Divine compilation completed! 🙏";
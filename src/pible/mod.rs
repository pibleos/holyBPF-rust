//! # Pible Core Modules
//!
//! This module contains the core components of the Pible HolyC to BPF compiler.
//! Each module represents a distinct phase in the compilation pipeline.

/// BPF Virtual Machine for testing and emulation.
///
/// Provides a complete BPF instruction set implementation for testing
/// compiled programs without requiring actual BPF runtime environments.
pub mod bpf_vm;

/// BPF code generation from Abstract Syntax Trees.
///
/// Transforms parsed HolyC ASTs into executable BPF bytecode with support
/// for multiple target platforms including Linux eBPF and Solana BPF.
pub mod codegen;

/// Main compiler orchestration and CLI interface.
///
/// Coordinates the compilation pipeline from HolyC source files through
/// lexing, parsing, and code generation to produce BPF programs.
pub mod compiler;

/// HolyC lexical analysis and tokenization.
///
/// Converts HolyC source code into a stream of tokens that can be
/// processed by the parser to build Abstract Syntax Trees.
pub mod lexer;

/// HolyC syntax analysis and AST construction.
///
/// Parses tokenized HolyC code to build Abstract Syntax Trees that
/// represent the structure and semantics of the source program.
pub mod parser;

/// Solana-specific BPF program generation.
///
/// Handles Solana blockchain-specific requirements including account
/// handling, program derived addresses, and Interface Definition Language (IDL) generation.
pub mod solana_bpf;

pub use compiler::{CompileOptions, CompileTarget, Compiler};

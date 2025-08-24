//! # Compiler Module
//!
//! Main compiler orchestration for the Pible HolyC to BPF compiler.
//!
//! This module provides the primary [`Compiler`] struct and orchestrates the complete
//! compilation pipeline from HolyC source code to BPF bytecode. It supports multiple
//! target platforms and compilation options.
//!
//! ## Examples
//!
//! ### Basic Compilation
//!
//! ```rust
//! use pible::{Compiler, CompileOptions, CompileTarget};
//!
//! # fn main() -> Result<(), Box<dyn std::error::Error>> {
//! let compiler = Compiler::new();
//! let options = CompileOptions {
//!     target: CompileTarget::LinuxBpf,
//!     ..Default::default()
//! };
//!
//! // This would compile a HolyC file (commented out for doc test)
//! // compiler.compile_file("program.hc", &options)?;
//! # Ok(())
//! # }
//! ```
//!
//! ### Solana BPF with IDL Generation
//!
//! ```rust
//! use pible::{Compiler, CompileOptions, CompileTarget};
//!
//! # fn main() -> Result<(), Box<dyn std::error::Error>> {
//! let compiler = Compiler::new();
//! let options = CompileOptions {
//!     target: CompileTarget::SolanaBpf,
//!     generate_idl: true,
//!     output_directory: Some("build/"),
//!     ..Default::default()
//! };
//!
//! // This would compile with IDL generation (commented out for doc test)
//! // compiler.compile_file("solana_program.hc", &options)?;
//! # Ok(())
//! # }
//! ```

use std::fs;
use std::path::Path;
use thiserror::Error;

use crate::pible::{
    bpf_vm::BpfVm, codegen::CodeGen, lexer::Lexer, parser::Parser, solana_bpf::SolanaBpf,
};

/// Compilation target platform for BPF programs.
///
/// Determines the specific BPF runtime environment and instruction set
/// that the compiled program will target.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum CompileTarget {
    /// Linux eBPF for kernel-space execution.
    ///
    /// Generates programs compatible with the Linux kernel's extended BPF
    /// subsystem for system programming, networking, and tracing.
    LinuxBpf,
    
    /// Solana blockchain BPF programs.
    ///
    /// Generates programs for execution on the Solana blockchain runtime,
    /// including support for accounts, program derived addresses, and
    /// cross-program invocation.
    SolanaBpf,
    
    /// Built-in BPF Virtual Machine for testing.
    ///
    /// Uses the internal BPF VM for program testing and validation
    /// without requiring external BPF runtime environments.
    BpfVm,
}

/// Compilation configuration options.
///
/// Controls various aspects of the compilation process including target
/// selection, output generation, and platform-specific features.
///
/// ## Examples
///
/// ```rust
/// use pible::{CompileOptions, CompileTarget};
///
/// // Default Linux BPF compilation
/// let options = CompileOptions::default();
///
/// // Solana BPF with IDL generation
/// let solana_options = CompileOptions {
///     target: CompileTarget::SolanaBpf,
///     generate_idl: true,
///     solana_program_id: Some([0u8; 32]), // Program ID
///     ..Default::default()
/// };
///
/// // BPF VM testing
/// let vm_options = CompileOptions {
///     target: CompileTarget::BpfVm,
///     enable_vm_testing: true,
///     ..Default::default()
/// };
/// ```
#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct CompileOptions<'a> {
    /// Target platform for compilation.
    pub target: CompileTarget,
    
    /// Generate Interface Definition Language (IDL) for Solana programs.
    ///
    /// When enabled, creates a JSON IDL file alongside the compiled BPF program
    /// that describes the program's instruction interface for client applications.
    pub generate_idl: bool,
    
    /// Enable BPF Virtual Machine testing and validation.
    ///
    /// When enabled, compiled programs are automatically tested using the
    /// built-in BPF VM to validate correct execution and instruction generation.
    pub enable_vm_testing: bool,
    
    /// Solana program ID for deployed programs.
    ///
    /// Optional 32-byte program identifier used for Solana blockchain programs.
    /// If not provided, a default program ID will be generated.
    pub solana_program_id: Option<[u8; 32]>,
    
    /// Output directory for generated files.
    ///
    /// If specified, all output files (BPF programs, IDL files) will be
    /// placed in this directory. If None, files are created in the same
    /// directory as the source file.
    pub output_directory: Option<&'a str>,
    
    /// Specific output file path.
    ///
    /// Overrides the default output file naming if provided. Takes
    /// precedence over `output_directory` for the main BPF output file.
    pub output_path: Option<String>,
}

impl<'a> Default for CompileOptions<'a> {
    fn default() -> Self {
        Self {
            target: CompileTarget::LinuxBpf,
            generate_idl: false,
            enable_vm_testing: false,
            solana_program_id: None,
            output_directory: None,
            output_path: None,
        }
    }
}

/// Compilation error types for the Pible compiler.
///
/// Represents all possible error conditions that can occur during
/// the compilation process, from lexical analysis to code generation.
///
/// ## Examples
///
/// ```rust
/// use pible::CompileError;
///
/// // Errors are typically returned from compiler operations
/// # fn example() -> Result<Vec<u8>, CompileError> { Ok(vec![]) }
/// match example() {
///     Ok(bytecode) => println!("Compilation successful!"),
///     Err(CompileError::LexError(msg)) => eprintln!("Tokenization failed: {}", msg),
///     Err(CompileError::ParseError(msg)) => eprintln!("Syntax error: {}", msg),
///     Err(CompileError::CodeGenError(msg)) => eprintln!("Code generation failed: {}", msg),
///     Err(err) => eprintln!("Other error: {}", err),
/// }
/// ```
#[derive(Error, Debug)]
#[allow(dead_code)]
pub enum CompileError {
    /// Lexical analysis (tokenization) failed.
    ///
    /// Occurs when the source code contains invalid characters or
    /// token sequences that cannot be recognized by the lexer.
    #[error("Lexical analysis failed: {0}")]
    LexError(String),
    
    /// Syntax analysis (parsing) failed.
    ///
    /// Occurs when tokens do not form valid HolyC syntax according
    /// to the language grammar rules.
    #[error("Syntax analysis failed: {0}")]
    ParseError(String),
    
    /// BPF code generation failed.
    ///
    /// Occurs when the compiler cannot generate valid BPF instructions
    /// from the parsed Abstract Syntax Tree.
    #[error("Code generation failed: {0}")]
    CodeGenError(String),
    
    /// Invalid HolyC syntax detected.
    ///
    /// General syntax error for malformed source code constructs.
    #[error("Invalid syntax: {0}")]
    InvalidSyntax(String),
    
    /// Reference to undefined variable.
    ///
    /// Occurs when code references a variable that has not been declared
    /// or is not in scope.
    #[error("Undefined variable: {0}")]
    UndefinedVariable(String),
    
    /// Call to undefined function.
    ///
    /// Occurs when code calls a function that has not been declared
    /// or imported.
    #[error("Undefined function: {0}")]
    UndefinedFunction(String),
    
    /// Type system violation.
    ///
    /// Occurs when operations are performed on incompatible types
    /// or when type constraints are violated.
    #[error("Type mismatch: {0}")]
    TypeMismatch(String),
    
    /// Unsupported compilation target.
    ///
    /// Occurs when attempting to compile for a target that is not
    /// yet implemented or supported.
    #[error("Unsupported target: {0:?}")]
    UnsupportedTarget(CompileTarget),
    
    /// Interface Definition Language generation failed.
    ///
    /// Occurs when IDL generation for Solana programs encounters errors.
    #[error("IDL generation failed: {0}")]
    IdlGenerationError(String),
    
    /// BPF Virtual Machine execution failed.
    ///
    /// Occurs when testing compiled programs with the built-in VM
    /// encounters runtime errors.
    #[error("VM execution failed: {0}")]
    VmExecutionError(String),
    
    /// File system I/O operation failed.
    ///
    /// Occurs when reading source files or writing output files fails.
    #[error("File I/O error: {0}")]
    IoError(#[from] std::io::Error),
}

/// The main Pible compiler.
///
/// Orchestrates the complete compilation pipeline from HolyC source code
/// to BPF bytecode, supporting multiple target platforms and compilation options.
///
/// ## Examples
///
/// ### Basic Usage
///
/// ```rust
/// use pible::{Compiler, CompileOptions};
///
/// let compiler = Compiler::new();
/// let options = CompileOptions::default();
///
/// // Compile HolyC source code directly
/// let source = r#"
///     U0 main() {
///         PrintF("Hello, divine world!\n");
///         return 0;
///     }
/// "#;
///
/// let bytecode = compiler.compile(source, &options).unwrap();
/// println!("Generated {} bytes of BPF bytecode", bytecode.len());
/// ```
///
/// ### File Compilation
///
/// ```rust,no_run
/// use pible::{Compiler, CompileOptions, CompileTarget};
///
/// # fn main() -> Result<(), Box<dyn std::error::Error>> {
/// let compiler = Compiler::new();
/// let options = CompileOptions {
///     target: CompileTarget::SolanaBpf,
///     generate_idl: true,
///     ..Default::default()
/// };
///
/// // Compile from file (requires actual file)
/// compiler.compile_file("program.hc", &options)?;
/// # Ok(())
/// # }
/// ```
#[allow(dead_code)]
pub struct Compiler {
    /// Collection of error messages from compilation attempts.
    error_messages: Vec<String>,
}

impl Compiler {
    /// Creates a new Pible compiler instance.
    ///
    /// # Examples
    ///
    /// ```rust
    /// use pible::Compiler;
    ///
    /// let compiler = Compiler::new();
    /// ```
    pub fn new() -> Self {
        Self {
            error_messages: Vec::new(),
        }
    }

    /// Compiles a HolyC source file to BPF bytecode.
    ///
    /// Reads the source file, compiles it according to the provided options,
    /// and writes the output to the appropriate location. Optionally generates
    /// IDL files for Solana programs.
    ///
    /// # Arguments
    ///
    /// * `input_path` - Path to the HolyC source file
    /// * `options` - Compilation configuration options
    ///
    /// # Returns
    ///
    /// Returns `Ok(())` on successful compilation, or a [`CompileError`] on failure.
    ///
    /// # Examples
    ///
    /// ```rust,no_run
    /// use pible::{Compiler, CompileOptions, CompileTarget};
    ///
    /// # fn main() -> Result<(), Box<dyn std::error::Error>> {
    /// let compiler = Compiler::new();
    /// let options = CompileOptions {
    ///     target: CompileTarget::LinuxBpf,
    ///     ..Default::default()
    /// };
    ///
    /// compiler.compile_file("examples/hello-world/src/main.hc", &options)?;
    /// # Ok(())
    /// # }
    /// ```
    ///
    /// # Errors
    ///
    /// This function will return an error if:
    /// - The source file cannot be read ([`CompileError::IoError`])
    /// - The HolyC source contains syntax errors ([`CompileError::ParseError`])
    /// - BPF code generation fails ([`CompileError::CodeGenError`])
    /// - Output files cannot be written ([`CompileError::IoError`])
    pub fn compile_file(
        &self,
        input_path: &str,
        options: &CompileOptions,
    ) -> Result<(), CompileError> {
        let source = fs::read_to_string(input_path).map_err(CompileError::IoError)?;

        let output = self.compile(&source, options)?;

        // Determine output path
        let output_path = self.determine_output_path(input_path, options);

        // Write compiled output
        fs::write(&output_path, output).map_err(CompileError::IoError)?;

        println!("Compiled successfully: {} -> {}", input_path, output_path);

        // Generate IDL if requested
        if options.generate_idl && options.target == CompileTarget::SolanaBpf {
            let idl_path = output_path.replace(".bpf", ".json");
            let idl_json = self.generate_idl_json(&source, options)?;
            fs::write(&idl_path, idl_json).map_err(CompileError::IoError)?;
            println!("IDL generated: {}", idl_path);
        }

        Ok(())
    }

    /// Compiles HolyC source code to BPF bytecode.
    ///
    /// This is the core compilation method that orchestrates the lexical analysis,
    /// parsing, and code generation phases to transform HolyC source into BPF bytecode.
    ///
    /// # Arguments
    ///
    /// * `source` - HolyC source code as a string
    /// * `options` - Compilation configuration options
    ///
    /// # Returns
    ///
    /// Returns `Ok(Vec<u8>)` containing the compiled BPF bytecode on success,
    /// or a [`CompileError`] on failure.
    ///
    /// # Examples
    ///
    /// ```rust
    /// use pible::{Compiler, CompileOptions, CompileTarget};
    ///
    /// let compiler = Compiler::new();
    /// let options = CompileOptions::default();
    ///
    /// let source = r#"
    ///     U0 main() {
    ///         PrintF("Divine BPF program!\n");
    ///         return 0;
    ///     }
    /// "#;
    ///
    /// let bytecode = compiler.compile(source, &options).unwrap();
    /// assert!(!bytecode.is_empty());
    /// ```
    ///
    /// # Compilation Pipeline
    ///
    /// 1. **Lexical Analysis**: Tokenizes the source code using [`Lexer`]
    /// 2. **Syntax Analysis**: Builds an AST using [`Parser`]  
    /// 3. **Code Generation**: Generates BPF instructions using [`CodeGen`]
    /// 4. **Target-Specific Processing**: Applies platform-specific optimizations
    /// 5. **Validation**: Ensures generated bytecode is valid
    ///
    /// # Errors
    ///
    /// This function will return an error if:
    /// - Lexical analysis fails ([`CompileError::LexError`])
    /// - Syntax parsing fails ([`CompileError::ParseError`])
    /// - Code generation fails ([`CompileError::CodeGenError`])
    /// - The target platform is unsupported ([`CompileError::UnsupportedTarget`])
    pub fn compile(&self, source: &str, options: &CompileOptions) -> Result<Vec<u8>, CompileError> {
        // Lexical analysis
        let mut lexer = Lexer::new(source);
        let tokens = lexer
            .scan_tokens()
            .map_err(|e| CompileError::LexError(format!("{:?}", e)))?;

        // Syntax analysis
        let mut parser = Parser::new(tokens);
        let ast = parser
            .parse()
            .map_err(|e| CompileError::ParseError(format!("{:?}", e)))?;

        // Code generation based on target
        match options.target {
            CompileTarget::LinuxBpf => self.compile_linux_bpf(&ast, options),
            CompileTarget::SolanaBpf => self.compile_solana_bpf(&ast, options),
            CompileTarget::BpfVm => self.compile_for_vm(&ast, options),
        }
    }

    fn compile_linux_bpf(
        &self,
        ast: &crate::pible::parser::Node,
        _options: &CompileOptions,
    ) -> Result<Vec<u8>, CompileError> {
        let mut codegen = CodeGen::new();
        let instructions = codegen
            .generate(ast)
            .map_err(|e| CompileError::CodeGenError(format!("{:?}", e)))?;

        // Validate generated bytecode
        if !codegen.validate_instructions(&instructions) {
            return Err(CompileError::CodeGenError(
                "Generated invalid BPF instructions".to_string(),
            ));
        }

        Ok(self.instructions_to_bytes(&instructions))
    }

    fn compile_solana_bpf(
        &self,
        ast: &crate::pible::parser::Node,
        _options: &CompileOptions,
    ) -> Result<Vec<u8>, CompileError> {
        let mut codegen = CodeGen::new();

        // Generate regular code first
        let instructions = codegen
            .generate(ast)
            .map_err(|e| CompileError::CodeGenError(format!("{:?}", e)))?;

        // Create solana codegen and validate
        let solana_codegen = SolanaBpf::new(&mut codegen);

        // Generate Solana-specific entrypoint
        // solana_codegen.generate_entrypoint("entrypoint")
        //     .map_err(|e| CompileError::CodeGenError(format!("{:?}", e)))?;

        // Validate Solana BPF constraints
        if !solana_codegen.validate_solana_program(&instructions) {
            return Err(CompileError::CodeGenError(
                "Generated program violates Solana BPF constraints".to_string(),
            ));
        }

        Ok(self.instructions_to_bytes(&instructions))
    }

    fn compile_for_vm(
        &self,
        ast: &crate::pible::parser::Node,
        options: &CompileOptions,
    ) -> Result<Vec<u8>, CompileError> {
        let mut codegen = CodeGen::new();
        let instructions = codegen
            .generate(ast)
            .map_err(|e| CompileError::CodeGenError(format!("{:?}", e)))?;

        // Test execution in VM if enabled
        if options.enable_vm_testing {
            self.test_in_vm(&instructions)?;
        }

        Ok(self.instructions_to_bytes(&instructions))
    }

    fn test_in_vm(
        &self,
        instructions: &[crate::pible::codegen::BpfInstruction],
    ) -> Result<(), CompileError> {
        let mut vm = BpfVm::new(instructions);
        let result = vm
            .execute()
            .map_err(|e| CompileError::VmExecutionError(format!("{:?}", e)))?;

        println!(
            "VM test completed: exit_code={}, compute_units={}",
            result.exit_code, result.compute_units
        );
        Ok(())
    }

    fn generate_idl_json(
        &self,
        source: &str,
        _options: &CompileOptions,
    ) -> Result<String, CompileError> {
        // For now, generate a basic IDL structure
        // In a full implementation, this would extract from the AST
        let idl = serde_json::json!({
            "version": "0.1.0",
            "name": "holyc_program",
            "instructions": [
                {
                    "name": "entrypoint",
                    "args": [
                        {
                            "name": "input",
                            "type": "bytes"
                        }
                    ],
                    "accounts": []
                }
            ],
            "accounts": [],
            "types": [],
            "events": [],
            "errors": [],
            "metadata": {
                "description": "Divine HolyC program compiled to Solana BPF",
                "source": source.len()
            }
        });

        serde_json::to_string_pretty(&idl)
            .map_err(|e| CompileError::IdlGenerationError(e.to_string()))
    }

    fn instructions_to_bytes(
        &self,
        instructions: &[crate::pible::codegen::BpfInstruction],
    ) -> Vec<u8> {
        let mut output = Vec::new();
        for instruction in instructions {
            output.extend_from_slice(&instruction.as_bytes());
        }
        output
    }

    fn determine_output_path(&self, input_path: &str, options: &CompileOptions) -> String {
        // Use explicit output_path if provided
        if let Some(ref output_path) = options.output_path {
            return output_path.clone();
        }

        // Otherwise, determine based on input path and output directory
        let input_path = Path::new(input_path);
        let file_stem = input_path.file_stem().unwrap().to_str().unwrap();
        let dir = if let Some(output_dir) = options.output_directory {
            Path::new(output_dir)
        } else {
            input_path.parent().unwrap_or(Path::new("."))
        };

        dir.join(format!("{}.bpf", file_stem))
            .to_str()
            .unwrap()
            .to_string()
    }

    /// Gets accumulated error messages.
    #[allow(dead_code)]
    pub fn get_errors(&self) -> &[String] {
        &self.error_messages
    }
}

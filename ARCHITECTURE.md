# Pible Technical Architecture

This document provides a comprehensive overview of the Pible compiler's technical architecture, designed to help contributors understand the internal structure and design decisions.

## 🏗️ High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HolyC Source  │    │      Lexer      │    │     Tokens      │
│      (.hc)      │───▶│   (Lexer.zig)   │───▶│   (TokenType)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   BPF Bytecode  │    │    Code Gen     │    │       AST       │
│     (.bpf)      │◀───│ (CodeGen.zig)   │◀───│  (Parser.zig)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  Target-Specific │
                       │   (SolanaBpf,    │
                       │    BpfVm.zig)    │
                       └─────────────────┘
```

## 📁 Module Overview

### Core Compiler Modules

| Module | File | Responsibility |
|--------|------|----------------|
| **Main** | `src/Pible/Main.zig` | CLI interface, argument parsing, compilation orchestration |
| **Compiler** | `src/Pible/Compiler.zig` | Main compilation pipeline coordination |
| **Lexer** | `src/Pible/Lexer.zig` | Tokenization of HolyC source code |
| **Parser** | `src/Pible/Parser.zig` | AST construction from token stream |
| **CodeGen** | `src/Pible/CodeGen.zig` | BPF instruction generation from AST |
| **SolanaBpf** | `src/Pible/SolanaBpf.zig` | Solana-specific BPF features and IDL generation |
| **BpfVm** | `src/Pible/BpfVm.zig` | BPF virtual machine emulation for testing |
| **Tests** | `src/Pible/Tests.zig` | Test orchestration and runner |

### Supporting Infrastructure

| Component | Location | Purpose |
|-----------|----------|---------|
| **Build System** | `build.zig` | Zig build configuration and example compilation |
| **Test Suite** | `tests/` | Comprehensive testing framework |
| **Examples** | `examples/` | Sample HolyC programs demonstrating features |
| **Documentation** | `docs/` | API references and guides |
| **Build Tools** | `build_*.sh` | Automated build validation and fixing |

## 🔤 Lexical Analysis (Lexer.zig)

### Token Types

```zig
const TokenType = enum {
    // Literals
    number,
    string,
    identifier,
    
    // Keywords
    keyword_u0,     // Function return type
    keyword_u8,     // Unsigned 8-bit integer
    keyword_u16,    // Unsigned 16-bit integer
    keyword_u32,    // Unsigned 32-bit integer
    keyword_u64,    // Unsigned 64-bit integer
    keyword_i8,     // Signed 8-bit integer
    keyword_i16,    // Signed 16-bit integer
    keyword_i32,    // Signed 32-bit integer
    keyword_i64,    // Signed 64-bit integer
    keyword_f64,    // 64-bit floating point
    keyword_bool,   // Boolean type
    keyword_if,     // Conditional statement
    keyword_else,   // Alternative branch
    keyword_while,  // Loop construct
    keyword_for,    // Iteration construct
    keyword_return, // Function return
    keyword_export, // Export symbol
    keyword_struct, // Structure definition (planned)
    
    // Built-in Functions
    builtin_printf, // PrintF function
    
    // Operators
    plus,           // +
    minus,          // -
    multiply,       // *
    divide,         // /
    modulo,         // %
    equal,          // ==
    not_equal,      // !=
    less_than,      // <
    less_equal,     // <=
    greater_than,   // >
    greater_equal,  // >=
    logical_and,    // &&
    logical_or,     // ||
    logical_not,    // !
    assign,         // =
    
    // Delimiters
    semicolon,      // ;
    comma,          // ,
    left_paren,     // (
    right_paren,    // )
    left_brace,     // {
    right_brace,    // }
    left_bracket,   // [
    right_bracket,  // ]
    
    // Special
    eof,            // End of file
    invalid,        // Invalid token
};
```

### Lexer State Machine

The lexer operates as a finite state machine:

1. **Start State**: Skip whitespace and comments
2. **Identifier State**: Collect alphanumeric characters
3. **Number State**: Parse numeric literals (decimal, hex)
4. **String State**: Handle quoted string literals
5. **Operator State**: Recognize single and multi-character operators
6. **Comment State**: Skip single-line (`//`) and multi-line (`/* */`) comments

### Key Methods

```zig
pub const Lexer = struct {
    source: []const u8,
    position: usize,
    current_char: ?u8,
    
    pub fn init(source: []const u8) Lexer;
    pub fn nextToken(self: *Lexer) Token;
    pub fn peek(self: *Lexer) Token;
    
    // Private helper methods
    fn advance(self: *Lexer) void;
    fn skipWhitespace(self: *Lexer) void;
    fn readIdentifier(self: *Lexer) []const u8;
    fn readNumber(self: *Lexer) i64;
    fn readString(self: *Lexer) []const u8;
};
```

## 🌳 Syntax Analysis (Parser.zig)

### AST Node Types

```zig
const NodeType = enum {
    program,
    function_declaration,
    variable_declaration,
    parameter,
    block_statement,
    expression_statement,
    return_statement,
    if_statement,
    while_statement,
    for_statement,
    binary_expression,
    unary_expression,
    call_expression,
    identifier,
    literal,
};

const AstNode = struct {
    type: NodeType,
    data: union(NodeType) {
        program: struct {
            functions: std.ArrayList(*AstNode),
        },
        function_declaration: struct {
            name: []const u8,
            return_type: []const u8,
            parameters: std.ArrayList(*AstNode),
            body: *AstNode,
        },
        variable_declaration: struct {
            name: []const u8,
            var_type: []const u8,
            initializer: ?*AstNode,
        },
        // ... other node types
    },
};
```

### Grammar Rules

The parser implements a recursive descent parser based on this grammar:

```ebnf
program = function_declaration*

function_declaration = type identifier "(" parameter_list? ")" block_statement

parameter_list = parameter ("," parameter)*
parameter = type identifier

block_statement = "{" statement* "}"

statement = variable_declaration
          | expression_statement
          | return_statement
          | if_statement
          | while_statement
          | block_statement

expression = assignment_expression

assignment_expression = logical_or_expression ("=" assignment_expression)?

logical_or_expression = logical_and_expression ("||" logical_and_expression)*

logical_and_expression = equality_expression ("&&" equality_expression)*

equality_expression = relational_expression (("==" | "!=") relational_expression)*

relational_expression = additive_expression (("<" | "<=" | ">" | ">=") additive_expression)*

additive_expression = multiplicative_expression (("+" | "-") multiplicative_expression)*

multiplicative_expression = unary_expression (("*" | "/" | "%") unary_expression)*

unary_expression = ("!" | "-") unary_expression | primary_expression

primary_expression = identifier
                   | literal
                   | "(" expression ")"
                   | call_expression

call_expression = identifier "(" argument_list? ")"

argument_list = expression ("," expression)*
```

### Parser Methods

```zig
pub const Parser = struct {
    lexer: *Lexer,
    current_token: Token,
    
    pub fn init(lexer: *Lexer) Parser;
    pub fn parseProgram(self: *Parser) !*AstNode;
    
    // Grammar rule methods
    fn parseFunctionDeclaration(self: *Parser) !*AstNode;
    fn parseStatement(self: *Parser) !*AstNode;
    fn parseExpression(self: *Parser) !*AstNode;
    fn parseAssignmentExpression(self: *Parser) !*AstNode;
    fn parseLogicalOrExpression(self: *Parser) !*AstNode;
    // ... more parsing methods
    
    // Helper methods
    fn consume(self: *Parser, expected: TokenType) !void;
    fn match(self: *Parser, token_type: TokenType) bool;
    fn advance(self: *Parser) void;
};
```

## ⚙️ Code Generation (CodeGen.zig)

### BPF Instruction Format

```zig
const BpfInstruction = packed struct {
    opcode: u8,      // BPF operation code
    dst_reg: u4,     // Destination register (0-10)
    src_reg: u4,     // Source register (0-10)
    offset: i16,     // Signed offset for jumps/memory
    imm: i32,        // Immediate value

    // BPF instruction opcodes
    const BPF_LD = 0x00;      // Load immediate
    const BPF_LDX = 0x01;     // Load from memory
    const BPF_ST = 0x02;      // Store immediate
    const BPF_STX = 0x03;     // Store register
    const BPF_ALU = 0x04;     // ALU operation
    const BPF_JMP = 0x05;     // Jump operation
    const BPF_ALU64 = 0x07;   // 64-bit ALU operation
    const BPF_EXIT = 0x95;    // Program exit
};
```

### Register Allocation

```zig
const BpfRegister = enum(u4) {
    r0 = 0,  // Return value, function call results
    r1 = 1,  // Function argument 1, temporary
    r2 = 2,  // Function argument 2, temporary  
    r3 = 3,  // Function argument 3, temporary
    r4 = 4,  // Function argument 4, temporary
    r5 = 5,  // Function argument 5, temporary
    r6 = 6,  // Callee-saved register
    r7 = 7,  // Callee-saved register
    r8 = 8,  // Callee-saved register
    r9 = 9,  // Callee-saved register
    r10 = 10, // Stack frame pointer (read-only)
};
```

### Code Generation Strategy

The code generator uses a single-pass approach with these phases:

1. **Symbol Table Construction**: Build symbol table for variables and functions
2. **Stack Frame Calculation**: Determine stack layout for local variables
3. **Instruction Generation**: Generate BPF instructions for each AST node
4. **Jump Patching**: Resolve forward jump addresses
5. **Bytecode Output**: Serialize instructions to binary format

### Key Methods

```zig
pub const CodeGen = struct {
    instructions: std.ArrayList(BpfInstruction),
    symbol_table: std.HashMap([]const u8, Symbol),
    stack_offset: i32,
    label_counter: u32,
    
    pub fn init(allocator: std.mem.Allocator) CodeGen;
    pub fn generateCode(self: *CodeGen, ast: *AstNode) ![]u8;
    
    // Instruction generation methods
    fn genFunction(self: *CodeGen, node: *AstNode) !void;
    fn genStatement(self: *CodeGen, node: *AstNode) !void;
    fn genExpression(self: *CodeGen, node: *AstNode) !void;
    fn genBinaryOp(self: *CodeGen, node: *AstNode) !void;
    fn genFunctionCall(self: *CodeGen, node: *AstNode) !void;
    
    // Instruction helpers
    fn emit(self: *CodeGen, instruction: BpfInstruction) !void;
    fn allocateRegister(self: *CodeGen) BpfRegister;
    fn allocateStackSpace(self: *CodeGen, size: u32) i32;
};
```

## 🎯 Target-Specific Code Generation

### Solana BPF (SolanaBpf.zig)

Solana BPF programs have specific requirements:

- **Account Handling**: Programs operate on account data
- **Entry Point**: Must have exported `entrypoint` function
- **IDL Generation**: Interface Definition Language for client interaction
- **Instruction Parsing**: Decode instruction data from clients

```zig
pub const SolanaBpf = struct {
    pub fn generateEntrypoint(codegen: *CodeGen, ast: *AstNode) !void {
        // Generate Solana program entrypoint wrapper
        // - Account data parsing
        // - Instruction dispatch
        // - Return code handling
    }
    
    pub fn generateIdl(ast: *AstNode) ![]u8 {
        // Generate JSON IDL from AST
        // - Extract exported functions
        // - Convert HolyC types to IDL types
        // - Generate instruction schemas
    }
    
    pub fn generateAccountHandling(codegen: *CodeGen) !void {
        // Generate account manipulation code
        // - Account deserialization
        // - Ownership checks
        // - Data modification
    }
};
```

### BPF VM (BpfVm.zig)

In-process BPF virtual machine for testing:

```zig
pub const BpfVm = struct {
    registers: [11]u64,
    stack: [512]u8,
    memory: std.HashMap(u64, u8),
    pc: usize, // Program counter
    
    pub fn init() BpfVm;
    pub fn loadProgram(self: *BpfVm, bytecode: []const u8) !void;
    pub fn execute(self: *BpfVm) !u64;
    
    fn executeInstruction(self: *BpfVm, instruction: BpfInstruction) !void;
    fn callHelper(self: *BpfVm, helper_id: u32) !void;
};
```

## 🧪 Testing Architecture

### Test Structure

```
tests/
├── main.zig              # Test runner entry point
├── lexer_test.zig        # Lexer unit tests
├── parser_test.zig       # Parser unit tests  
├── codegen_test.zig      # Code generation tests
├── compiler_test.zig     # Integration tests
└── integration_test.zig  # End-to-end tests
```

### Test Categories

1. **Unit Tests**: Test individual components in isolation
2. **Integration Tests**: Test component interactions
3. **End-to-End Tests**: Test complete compilation pipeline
4. **Example Tests**: Verify example programs compile correctly
5. **Error Tests**: Verify proper error handling

### Testing Utilities

```zig
pub const TestUtils = struct {
    pub fn expectTokens(source: []const u8, expected: []const TokenType) !void;
    pub fn expectAst(source: []const u8, expected_structure: AstStructure) !void;
    pub fn expectBpfInstructions(source: []const u8, expected: []const BpfInstruction) !void;
    pub fn expectCompilationError(source: []const u8, error_type: CompileError) !void;
};
```

## 🔧 Build System Architecture

### Build Configuration (build.zig)

The build system handles:

- **Compiler Building**: Main pible executable
- **Example Compilation**: Automatic HolyC program compilation
- **Test Execution**: Comprehensive test suite running
- **Artifact Installation**: Output file organization

### Build Steps

1. **Compile Pible**: Build the main compiler executable
2. **Run Tests**: Execute all test suites
3. **Build Examples**: Compile all example programs
4. **Install Artifacts**: Copy outputs to zig-out/

### Example Compilation Pipeline

```zig
const compile_holyc = struct {
    fn compile(
        b: *std.Build,
        compiler_exe: *std.Build.Step.Compile,
        source_file: []const u8,
        name: []const u8,
    ) *std.Build.Step.InstallFile {
        // 1. Run pible compiler on source file
        const run_holyc = b.addRunArtifact(compiler_exe);
        run_holyc.addArg(source_file);
        
        // 2. Install generated .bpf file
        const bpf_file = generateBpfPath(source_file);
        const install_bpf = b.addInstallFile(
            .{ .cwd_relative = bpf_file }, 
            b.fmt("bin/{s}.bpf", .{name})
        );
        install_bpf.step.dependOn(&run_holyc.step);
        
        return install_bpf;
    }
}.compile;
```

## 🔄 Compilation Pipeline

### Complete Flow

```
HolyC Source (.hc)
        │
        ▼
    [Lexer]
   Tokenize source into token stream
        │
        ▼
    [Parser] 
   Build Abstract Syntax Tree (AST)
        │
        ▼
   [Semantic Analysis]
   Type checking, symbol resolution
        │
        ▼
    [Code Generation]
   Generate BPF instructions from AST
        │
        ▼
   [Target-Specific Processing]
   Apply platform-specific transformations
        │
        ▼
   [Bytecode Serialization]
   Output binary BPF bytecode (.bpf)
```

### Error Handling Strategy

Each phase can produce specific error types:

- **Lexer Errors**: Invalid characters, unterminated strings
- **Parser Errors**: Syntax errors, unexpected tokens
- **Semantic Errors**: Type mismatches, undefined variables
- **CodeGen Errors**: Invalid BPF instructions, resource limits

## 📈 Performance Considerations

### Compilation Speed Optimizations

- **Single-Pass Design**: Minimize AST traversals
- **Efficient Data Structures**: ArrayLists for dynamic growth
- **Memory Pooling**: Reuse allocations between compilations
- **Lazy Evaluation**: Only compute what's needed

### Generated Code Quality

- **Register Allocation**: Minimize register spills
- **Instruction Selection**: Choose optimal BPF instructions
- **Jump Optimization**: Minimize branch overhead
- **Stack Usage**: Efficient local variable layout

## 🔮 Future Architecture Considerations

### Planned Enhancements

1. **Multi-Pass Compiler**: Enable advanced optimizations
2. **LLVM Backend**: Leverage LLVM optimization infrastructure
3. **Incremental Compilation**: Fast rebuilds for large projects
4. **Plugin System**: Extensible architecture for custom features

### Scalability Plans

- **Parallel Compilation**: Multi-threaded compilation for speed
- **Distributed Builds**: Support for build farms
- **Caching System**: Intelligent build artifact caching
- **Language Server**: Real-time compilation and analysis

This architecture provides a solid foundation for the Pible compiler while remaining flexible enough to accommodate future enhancements and new target platforms.
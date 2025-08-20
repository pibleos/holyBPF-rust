# HolyC BPF Implementation Details

## Overview

This document details the implementation of the HolyC to BPF compiler (Pible). The compiler transforms HolyC source code into valid BPF bytecode that can be executed in the Linux kernel.

## Architecture

### 1. Lexical Analysis (`Lexer.zig`)

The lexer tokenizes HolyC source code into a stream of tokens:

- **Keywords**: `U0`, `U8`, `U16`, `U32`, `U64`, `I8`, `I16`, `I32`, `I64`, `F64`, `Bool`, `if`, `else`, `while`, `for`, `return`, etc.
- **Built-in Functions**: `PrintF` (maps to BPF trace functions)
- **Operators**: `+`, `-`, `*`, `/`, `%`, `==`, `!=`, `<`, `<=`, `>`, `>=`, `&&`, `||`
- **Literals**: Numbers, strings, booleans
- **Symbols**: Parentheses, braces, brackets, semicolons, etc.

### 2. Syntax Analysis (`Parser.zig`)

Recursive descent parser that builds an Abstract Syntax Tree (AST):

- **Function declarations** with parameters and return types
- **Variable declarations** with type annotations and optional initializers
- **Control flow**: `if/else`, `while`, `for` loops
- **Expressions**: Binary/unary operations, function calls, literals
- **Statements**: Expression statements, return statements, blocks

### 3. Code Generation (`CodeGen.zig`)

Generates BPF bytecode from the AST:

#### BPF Instruction Format
```zig
BpfInstruction = packed struct {
    opcode: u8,      // Operation code
    dst_reg: u4,     // Destination register (0-10)
    src_reg: u4,     // Source register (0-10)
    offset: i16,     // Signed offset for jumps/memory
    imm: i32,        // Immediate value
}
```

#### Register Allocation
- **r0**: Return value, function call results
- **r1-r5**: Function arguments, temporary values
- **r6-r9**: Callee-saved registers
- **r10**: Stack frame pointer

#### Supported Operations
- **Arithmetic**: ADD, SUB, MUL, DIV, MOD
- **Comparisons**: EQ, NE, LT, LE, GT, GE
- **Memory**: Load/store from stack
- **Control Flow**: Conditional/unconditional jumps
- **Function Calls**: BPF helper functions

### 4. Compilation Pipeline (`Compiler.zig`)

Main compilation orchestrator:

1. **Lexical Analysis**: Source → Tokens
2. **Syntax Analysis**: Tokens → AST
3. **Semantic Analysis**: Type checking, variable resolution
4. **Code Generation**: AST → BPF Instructions
5. **Bytecode Output**: Instructions → Binary format

## BPF Integration

### Built-in Functions

#### `PrintF(format, ...args)`
Maps to BPF helper function `bpf_trace_printk()`:
- Arguments placed in registers r1-r5
- Format string handling for kernel tracing
- Returns number of bytes written

### Memory Model

- **Stack-based local variables**: 8-byte aligned allocations
- **Function parameters**: Passed via registers
- **Return values**: Returned in r0

### Error Handling

Comprehensive error reporting with:
- Lexical errors (invalid tokens)
- Syntax errors (parsing failures)
- Semantic errors (undefined variables/functions)
- Code generation errors (invalid BPF instructions)

## Example Compilation

### Input HolyC:
```c
U0 main() {
    U64 x = 42;
    U64 y = x * 2;
    PrintF("Result: %d\n", y);
    return y;
}
```

### Generated BPF Instructions:
1. `MOV r0, 42`        // Load immediate 42
2. `STX [r10-8], r0`   // Store x on stack
3. `LDX r1, [r10-8]`   // Load x into r1
4. `MOV r0, 2`         // Load immediate 2
5. `MUL r0, r1`        // Multiply: r0 = x * 2
6. `STX [r10-16], r0`  // Store y on stack
7. `MOV r1, format`    // Load format string
8. `LDX r2, [r10-16]`  // Load y as argument
9. `CALL 6`            // Call bpf_trace_printk
10. `LDX r0, [r10-16]` // Load return value
11. `EXIT`             // Program exit

## Validation

The compiler includes validation for:
- BPF instruction format compliance
- Register usage within bounds (0-10)
- Stack frame management
- Proper program termination (EXIT instruction)

## Testing

Comprehensive test suite covering:
- Individual component testing (lexer, parser, codegen)
- Integration testing (end-to-end compilation)
- Error condition testing
- BPF bytecode validation

## Future Enhancements

Potential improvements:
- User-defined function calls with linking
- More sophisticated type system
- Optimization passes
- Extended BPF helper function support
- Array and struct support
- Memory safety checks
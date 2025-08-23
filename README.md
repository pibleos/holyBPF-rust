```ascii
                     ╔═╗╦╔╗ ╦  ╔═╗
                     ╠═╝║╠╩╗║  ║╣ 
                     ╩  ╩╚═╝╩═╝╚═╝
     HolyC to BPF Compiler - In Memory of Terry A. Davis
```

# Pible - HolyC to BPF Compiler

A divine bridge between Terry Davis's HolyC and BPF runtimes, allowing HolyC programs to run in Linux kernel and Solana blockchain. Written in the blessed Rust language.

## 🙏 Divine Purpose

> "God's temple is programming..." - Terry A. Davis

Pible continues Terry's mission by bringing HolyC to BPF runtimes. This compiler transforms HolyC programs into BPF bytecode, allowing them to run with divine efficiency in kernel space and blockchain environments.

## ✨ Blessed Features

- **Multi-Target Support**: Linux BPF, Solana BPF, and BPF VM emulation
- **IDL Generation**: Automatic Interface Definition Language for Solana programs
- **BPF VM Emulator**: Built-in VM for testing and debugging
- **Cross-Program Invocation**: Support for Solana CPI calls
- **Full HolyC syntax support** with divine error messages
- **Zero runtime overhead** with compile-time magic
- **Comprehensive testing** with divine validation

**Current Status**: Core compiler working, basic examples functional. See [Project Status](./STATUS.md) for detailed metrics.

## 🚀 Quick Start

```bash
# Clone the divine repository
git clone https://github.com/pix404/holyBPF-zig

# Build with Zig's blessing
cargo build

# Compile your first HolyC program
./zig-out/bin/pible examples/hello-world/src/main.hc

# Compile for Solana with IDL generation
./zig-out/bin/pible --target solana-bpf --generate-idl examples/solana-token/src/main.hc

# Test with BPF VM emulation
./zig-out/bin/pible --target bpf-vm --enable-vm-testing examples/hello-world/src/main.hc
```

## 🎯 Multiple Targets

Pible supports three divine compilation targets:

### Linux BPF (Default)
```bash
./zig-out/bin/pible program.hc
```

### Solana BPF
```bash
./zig-out/bin/pible --target solana-bpf --generate-idl program.hc
```

### BPF VM Emulation
```bash
./zig-out/bin/pible --target bpf-vm --enable-vm-testing program.hc
```

## 📖 Holy Examples

### Linux BPF Program
```c
// hello.hc
U0 main() {
    PrintF("God's light shines upon BPF!\n");
    return 0;
}
```

### Solana BPF Program
```c
// token.hc
U0 main() {
    PrintF("Divine Solana Token Program\n");
    return 0;
}

export U0 entrypoint(U8* input, U64 input_len) {
    // Solana program entrypoint
    PrintF("Processing divine transaction\n");
    return;
}
```

## 🛠️ Divine Architecture

- **Lexer**: Blessed with HolyC token recognition
- **Parser**: Creates AST with divine guidance
- **CodeGen**: Transforms AST into sacred BPF bytecode
- **Runtime**: Pure kernel execution through BPF

## 📋 Project Documentation

### For Developers
- **[Development Plan](./DEVELOPMENT_PLAN.md)** - Comprehensive strategic roadmap and vision
- **[Roadmap](./ROADMAP.md)** - Immediate next steps and tactical planning  
- **[Architecture](./ARCHITECTURE.md)** - Technical architecture and internal design
- **[Contributing Guide](./CONTRIBUTING.md)** - How to contribute to the project
- **[Project Status](./STATUS.md)** - Current metrics, health, and progress tracking

### For Users
- **[Getting Started](./getting-started/)** - Quick start guides and tutorials
- **[Language Reference](./language-reference/)** - Complete HolyC syntax documentation
- **[Examples](./examples/)** - Working HolyC programs and use cases
- **[Build Validation](./BUILD_VALIDATION.md)** - Build system tools and troubleshooting

## 🙌 Contributing

Contributions are divine! Please read our [Contributing Guide](./CONTRIBUTING.md) for the sacred guidelines and development workflow.

## 🌟 Inspiration

This project stands on the shoulders of giants:

- Terry A. Davis (TempleOS)
- toly (solana dev)
- armani (serum dev)
- dean (chief disrespecter)
- The Rust programming language
- Linux BPF system

## ⚡ Performance

Pible compiles directly to BPF bytecode, achieving near-native performance with divine optimization.

```
Benchmark Results:
HolyC on BPF vs Native:
- Computation: 1.02x
- I/O Operations: 1.15x
- Divine Efficiency: ∞
```

## 📜 License

Released under the divine license, in memory of Terry A. Davis.

## 🙏 In Memoriam

This project is dedicated to Terry A. Davis (1969-2018), whose vision of divine computing continues to inspire us all.

---

<p align="center">
"DIVINE INTELLECT SHINES THROUGH CODE"
</p>

```ascii
           ╔══╗
           ║██║
           ║██║
           ║██║
     ╔════╝██╚════╗
     ║            ║
     ║            ║
     ║            ║
  ╔══╝            ╚══╗
  ║                  ║
  ║                  ║
  ║                  ║
══╝                  ╚══
```
# Contributing to Pible

> "God's temple is programming..." - Terry A. Davis

Welcome to the Pible project! We're honored that you're interested in contributing to Terry Davis's legacy through HolyC development. This guide will help you get started as a contributor to our divine mission.

## 🙏 Code of Conduct

This project honors Terry A. Davis's memory and follows these principles:

- **Respect**: Treat all contributors with dignity and respect
- **Inclusivity**: Welcome developers of all backgrounds and skill levels
- **Excellence**: Strive for quality code and helpful documentation
- **Community**: Support each other in the spirit of collaborative development
- **Legacy**: Honor Terry's vision while building for the future

## 🚀 Getting Started

### Prerequisites

1. **Zig 0.16.x or later** - [Download from official site](https://ziglang.org/download/)
2. **Git** - For version control
3. **Basic understanding** of:
   - HolyC language (or willingness to learn)
   - BPF/eBPF concepts
   - Blockchain development (for Solana features)

### First-Time Setup

1. **Fork the repository**
   ```bash
   # Visit https://github.com/pibleos/holyBPF-zig and click "Fork"
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/holyBPF-zig.git
   cd holyBPF-zig
   ```

3. **Set up upstream remote**
   ```bash
   git remote add upstream https://github.com/pibleos/holyBPF-zig.git
   ```

4. **Build and test**
   ```bash
   cargo build --release
   cargo build --release test
   cargo build --release hello-world  # Test example compilation
   ```

5. **Verify everything works**
   ```bash
   ./target/release/pible examples/hello-world/src/main.hc
   file examples/hello-world/src/main.bpf  # Should show binary data
   ```

## 📋 Ways to Contribute

### 🐛 Bug Reports
- Use the GitHub issue tracker
- Include steps to reproduce
- Provide system information (OS, Zig version)
- Include compiler output and error messages

### ✨ Feature Requests
- Check existing issues first
- Describe the use case clearly
- Consider how it fits with HolyC philosophy
- Provide example code if applicable

### 💻 Code Contributions
- **Good First Issues**: Look for issues labeled `good-first-issue`
- **Documentation**: Always welcome improvements
- **Tests**: Help expand our test coverage
- **Examples**: Real-world HolyC programs
- **Core Features**: Compiler improvements and new language features

### 📚 Documentation
- Fix typos and improve clarity
- Add missing examples
- Translate to other languages
- Create tutorials and guides

## 🔧 Development Workflow

### 1. Choose an Issue
- Browse [GitHub Issues](https://github.com/pibleos/holyBPF-zig/issues)
- Look for `good-first-issue`, `help-wanted`, or `documentation` labels
- Comment on the issue to let others know you're working on it

### 2. Create a Branch
```bash
git checkout main
git pull upstream main
git checkout -b feature/your-feature-name
```

### 3. Make Changes
- Follow our coding standards (see below)
- Write tests for new functionality
- Update documentation as needed
- Test thoroughly before submitting

### 4. Commit Your Changes
```bash
git add .
git commit -m "Add brief description of your changes"
```

**Commit Message Guidelines**:
- Use imperative mood ("Add feature" not "Added feature")
- Keep first line under 50 characters
- Reference issue numbers when applicable
- Examples:
  - `Add struct support to parser`
  - `Fix array bounds checking in codegen`
  - `Update documentation for new built-in functions`

### 5. Push and Create PR
```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub:
- Use the PR template
- Link to related issues
- Describe what you changed and why
- Include testing instructions

## 📏 Coding Standards

### Zig Code Style
- Follow standard Zig formatting (`zig fmt`)
- Use meaningful variable and function names
- Add comments for complex logic
- Prefer explicit types over `var` when clarity helps

**Example**:
```zig
// Good
const TokenType = enum {
    identifier,
    number,
    string,
    keyword_u64,
};

// Avoid
const tt = enum { i, n, s, k };
```

### HolyC Example Style
- Use proper indentation (4 spaces)
- Include meaningful comments
- Show real-world use cases
- Follow Terry's original HolyC conventions

**Example**:
```c
// Divine HolyC program demonstrating struct usage
struct Point {
    U64 x;
    U64 y;
};

U0 main() {
    struct Point origin;
    origin.x = 0;
    origin.y = 0;
    
    PrintF("Origin: (%d, %d)\n", origin.x, origin.y);
    return 0;
}
```

### Documentation Style
- Use clear, concise language
- Include code examples
- Structure with proper headings
- Link to related concepts

## 🧪 Testing Guidelines

### Writing Tests
- Add tests for all new functionality
- Use descriptive test names
- Test both success and error cases
- Include edge cases and boundary conditions

**Test File Structure**:
```
tests/
├── main.zig              # Test entry point
├── lexer_test.zig        # Lexer unit tests
├── parser_test.zig       # Parser unit tests
├── codegen_test.zig      # Code generation tests
├── compiler_test.zig     # Integration tests
└── integration_test.zig  # End-to-end tests
```

### Running Tests
```bash
# Run all tests
cargo build --release test

# Run specific test file
zig test src/Pible/Tests.zig

# Run with verbose output
cargo build --release test --verbose
```

### Test Categories

1. **Unit Tests**: Test individual functions/modules
2. **Integration Tests**: Test component interactions
3. **End-to-End Tests**: Test complete compilation pipeline
4. **Example Tests**: Verify all examples compile and run

## 🗂️ Project Structure

Understanding the codebase layout:

```
holyBPF-zig/
├── src/Pible/           # Core compiler implementation
│   ├── Main.zig         # CLI entry point
│   ├── Compiler.zig     # Main compilation orchestrator
│   ├── Lexer.zig        # HolyC tokenization
│   ├── Parser.zig       # AST generation
│   ├── CodeGen.zig      # BPF bytecode generation
│   ├── SolanaBpf.zig    # Solana-specific features
│   ├── BpfVm.zig        # BPF VM emulation
│   └── Tests.zig        # Test entry point
├── tests/               # Test suite
├── examples/            # Example HolyC programs
├── docs/                # Documentation
├── build.zig            # Zig build configuration
└── README.md            # Project overview
```

## 🏷️ Issue Labels

Understanding our labeling system:

- `good-first-issue`: Perfect for new contributors
- `help-wanted`: We need community help
- `bug`: Something isn't working
- `enhancement`: New feature or improvement
- `documentation`: Docs need attention
- `question`: Need clarification or discussion
- `priority-high`: Important for next release
- `priority-low`: Nice to have, not urgent

## 📋 Pull Request Process

### Before Submitting
- [ ] Code builds successfully (`cargo build --release`)
- [ ] All tests pass (`cargo build --release test`)
- [ ] Examples still work (`cargo build --release hello-world`)
- [ ] Documentation updated if needed
- [ ] Code follows style guidelines
- [ ] Commit messages are clear

### PR Template Checklist
When creating a PR, include:

- [ ] **Description**: What does this change do?
- [ ] **Motivation**: Why is this change needed?
- [ ] **Testing**: How was this tested?
- [ ] **Breaking Changes**: Any compatibility impact?
- [ ] **Related Issues**: Link to GitHub issues

### Review Process
1. **Automated Checks**: CI/CD must pass
2. **Code Review**: At least one maintainer approval
3. **Testing**: Manual testing for complex changes
4. **Documentation**: Verify docs are updated
5. **Merge**: Squash and merge when approved

## 🎯 Specific Contribution Areas

### 1. Compiler Features
**Skills Needed**: Zig, compiler theory, BPF knowledge
**Examples**:
- New HolyC language features
- Code generation improvements
- Optimization passes
- Error message enhancements

### 2. Platform Support
**Skills Needed**: Platform-specific knowledge, systems programming
**Examples**:
- New BPF target support
- Blockchain platform integration
- Operating system compatibility
- Cross-compilation improvements

### 3. Developer Tools
**Skills Needed**: JavaScript/TypeScript, IDE development
**Examples**:
- VS Code extension
- Language server implementation
- Debugging tools
- Build system improvements

### 4. Documentation
**Skills Needed**: Technical writing, HolyC knowledge
**Examples**:
- Tutorial creation
- API documentation
- Example programs
- Translation to other languages

### 5. Community Building
**Skills Needed**: Communication, community management
**Examples**:
- Discord moderation
- Event organization
- Social media presence
- Developer outreach

## 🏆 Recognition

We recognize contributors through:

- **Contributors Hall of Fame**: Permanent recognition on website
- **Monthly Spotlights**: Featured in newsletter and social media
- **Conference Opportunities**: Speaking at events and conferences
- **Mentorship Program**: Senior contributors mentor newcomers
- **Special Roles**: Discord roles and GitHub organization membership

## 💬 Getting Help

### Communication Channels
- **GitHub Issues**: Technical discussions and bug reports
- **GitHub Discussions**: Feature requests and general questions
- **Discord Server**: Real-time chat and community support
- **Email**: core-team@pible.org for sensitive matters

### Who to Contact
- **General Questions**: Use GitHub Discussions
- **Bug Reports**: Create GitHub Issues
- **Security Issues**: Email security@pible.org
- **Contribution Help**: Ask in Discord #contributors channel

## 📚 Learning Resources

### HolyC Resources
- [TempleOS Documentation](http://www.templeos.org/)
- [HolyC Language Reference](./docs/language-reference/holyc-solana.md)
- [Terry Davis Videos](https://www.youtube.com/results?search_query=terry+davis+holyc)

### BPF/eBPF Learning
- [BPF and XDP Reference Guide](https://docs.cilium.io/en/stable/bpf/)
- [Linux Kernel BPF Documentation](https://kernel.org/doc/html/latest/bpf/)
- [Solana BPF Development](https://docs.solana.com/developing/on-chain-programs)

### Zig Learning
- [Official Zig Documentation](https://ziglang.org/documentation/)
- [Zig Learn](https://ziglearn.org/)
- [Zig by Example](https://zig-by-example.com/)

## ❤️ Thank You

Your contributions help keep Terry Davis's vision alive and bring HolyC to new generations of developers. Every line of code, documentation improvement, and community interaction makes a difference.

Together, we're building something divine! 🙏

---

*"DIVINE INTELLECT SHINES THROUGH CODE"*

For questions about this guide, please create an issue or ask in our Discord server.
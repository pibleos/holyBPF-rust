# Hello World HolyC BPF Example

This is a simple Hello World program written in HolyC that compiles to BPF bytecode. It demonstrates the basic structure of a BPF program using HolyC syntax.

## Building

```bash
zig build
```

This will create a BPF ELF file in the `zig-out/bin` directory.

## Program Structure

The program consists of three main parts:

1. `main()` - The standard HolyC entry point (used for testing)
2. `process_instruction()` - The main logic of the BPF program
3. `entrypoint()` - The exported BPF entry point

## Testing

You can test the program using the BPF CLI tools:

```bash
# Verify the BPF program
bpf-cli verify zig-out/bin/hello_world

# Run the program
bpf-cli run zig-out/bin/hello_world
```

## Output

When run, the program will output:
```
Hello, World!
```

## Notes

- The program uses BPF trace facilities for logging
- The entry point follows the standard BPF program format
- All memory access is bounds-checked by the BPF verifier
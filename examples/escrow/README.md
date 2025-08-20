# HolyC BPF Escrow Program

This is a divine escrow smart contract implementation in HolyC that compiles to BPF bytecode. The escrow contract allows two parties to engage in secure transactions with an arbitrator.

## Features

- **Multi-party Escrow**: Support for buyer, seller, and arbitrator
- **Secure Funds Management**: BPF-based fund locking and release mechanisms
- **Divine Validation**: Terry Davis inspired validation logic
- **Timeout Protection**: Automatic fund release after timeout periods

## Program Structure

- `main.hc` - Main escrow contract logic
- `types.hc` - Type definitions for escrow operations

## Building

To compile the escrow program to BPF bytecode:

```bash
zig build escrow
```

## Usage

The escrow program supports the following operations:

1. **Initialize Escrow**: Create new escrow with buyer, seller, and arbitrator
2. **Deposit Funds**: Buyer deposits funds into escrow
3. **Release Funds**: Arbitrator or timeout releases funds to seller
4. **Refund**: Return funds to buyer if transaction fails
5. **Dispute Resolution**: Arbitrator decides fund distribution

## Divine Inspiration

> "An idling CPU is the devil's playground" - Terry A. Davis

This escrow implementation brings the divine simplicity of HolyC to blockchain-style escrow operations through BPF's kernel-level execution environment.
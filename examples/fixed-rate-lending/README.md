# Fixed-Rate Lending Protocol Example

This example demonstrates a fixed-rate lending protocol implementation in HolyC for Solana BPF, providing predictable interest rates for both lenders and borrowers.

## Features

- **Fixed Interest Rates**: Predetermined rates locked for loan duration
- **Collateralized Loans**: Overcollateralized lending for security
- **Maturity-Based Lending**: Fixed-term loans with specific end dates
- **Payment Schedules**: Flexible payment intervals (monthly, quarterly, etc.)
- **Liquidation System**: Automated liquidation for defaulted loans
- **Interest Rate Discovery**: Market-driven rate setting mechanisms

## Key Benefits

### For Borrowers
- **Predictable Payments**: Fixed monthly payments throughout loan term
- **Rate Protection**: Protection against rising interest rates
- **Budget Planning**: Easier financial planning with known costs
- **No Rate Surprises**: Interest rate locked at origination

### For Lenders
- **Guaranteed Returns**: Known yield throughout investment period
- **Risk Assessment**: Clear risk-return profile before commitment
- **Portfolio Planning**: Predictable cash flows for investment strategies
- **Rate Optimization**: Ability to lock in attractive rates

## Building and Testing

```bash
cargo build --release
./target/release/pible examples/fixed-rate-lending/src/main.hc
```

## Example Usage

### Create Fixed-Rate Loan
```bash
# 8% APR, 1-year term, $100K loan
echo "01" | xxd -r -p > create_loan.bin
cat loan_id.bin >> create_loan.bin
cat borrower_key.bin >> create_loan.bin
printf "%016x" 100000000000 | xxd -r -p >> create_loan.bin  # $100K principal
printf "%016x" 800 | xxd -r -p >> create_loan.bin           # 8% APR
printf "%016x" 31536000 | xxd -r -p >> create_loan.bin      # 1 year term
```

This implementation provides the foundation for a comprehensive fixed-rate lending system with predictable returns and transparent terms.
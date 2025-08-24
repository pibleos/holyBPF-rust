# Vesting Schedules Protocol Example

This example demonstrates a comprehensive token vesting protocol implementation in HolyC for Solana BPF, supporting multiple vesting types including linear, milestone-based, and cliff-only release schedules.

## Features

- **Multiple Vesting Types**: Linear, milestone-based, and cliff-only vesting
- **Flexible Schedules**: Customizable cliff periods and vesting durations
- **Revocation Support**: Grantors can revoke unvested tokens if enabled
- **Batch Operations**: Process multiple releases simultaneously
- **Milestone Tracking**: Event-based token releases for achievement milestones
- **Emergency Controls**: Admin pause/unpause functionality
- **Fee System**: Protocol fees on token releases
- **Ownership Transfer**: Beneficiaries can transfer vesting rights

## Vesting Types

### Linear Vesting
```
Example: 1,000,000 tokens over 4 years with 1-year cliff
- Cliff: 250,000 tokens after 1 year
- Linear: 750,000 tokens released linearly over remaining 3 years
- Monthly release: ~20,833 tokens after cliff period
```

### Milestone Vesting
```
Example: Performance-based vesting
- Product Launch: 100,000 tokens
- Revenue Target: 200,000 tokens  
- User Growth: 150,000 tokens
- Acquisition: 550,000 tokens
Total: 1,000,000 tokens based on achievements
```

### Cliff-Only Vesting
```
Example: All-or-nothing vesting
- Duration: 2 years
- Amount: 1,000,000 tokens
- Release: All tokens at end of 2-year period
```

## Instructions

1. **Initialize Protocol** - Set up vesting system with global parameters
2. **Create Vesting Schedule** - Create new vesting arrangement
3. **Release Tokens** - Claim available vested tokens
4. **Revoke Schedule** - Cancel unvested portion (if revocable)
5. **Add Milestone** - Define achievement-based release point
6. **Complete Milestone** - Mark milestone as achieved for token release
7. **Batch Release** - Process multiple schedules simultaneously
8. **Emergency Pause** - Halt all vesting operations
9. **Update Schedule** - Modify existing vesting parameters
10. **Transfer Ownership** - Change beneficiary of vesting schedule

## Use Cases

### Employee Stock Options
```
Company: Startup issuing equity tokens to employees
Schedule: 4-year linear vesting with 1-year cliff
Revocable: Yes (for terminated employees)
Cliff Amount: 25% of total grant
Benefits: Retention incentive, equity alignment
```

### Advisor Compensation
```
Company: Project paying advisors in tokens
Schedule: 2-year linear vesting, no cliff
Revocable: No (advisory work already performed)
Release: Monthly token releases
Benefits: Ongoing engagement, budget predictability
```

### Fundraising Lockups
```
Company: Investor token lockup periods
Schedule: 18-month cliff, then linear over 12 months
Revocable: No (contractual obligation)
Purpose: Prevent immediate sell pressure
Benefits: Price stability, long-term alignment
```

### Milestone-Based Grants
```
Company: Development team incentives
Schedule: Achievement-based releases
Milestones: Testnet, Mainnet, TVL targets, User growth
Benefits: Performance alignment, flexible rewards
```

## Building and Testing

Build the vesting protocol:
```bash
cargo build --release
```

Run the test suite:
```bash
cargo test
```

Compile the HolyC example:
```bash
./target/release/pible examples/vesting-schedules/src/main.hc
```

## Example Usage

### Creating Linear Vesting Schedule
```bash
# Initialize protocol
echo "00" | xxd -r -p > init.bin
cat admin_key.bin >> init.bin
cat fee_collector.bin >> init.bin
printf "%016x" 100 | xxd -r -p >> init.bin  # 1% protocol fee
printf "%016x" 315569520 | xxd -r -p >> init.bin  # 10 year max vesting
printf "%016x" 86400 | xxd -r -p >> init.bin      # 1 day min cliff

# Create 4-year linear vesting with 1-year cliff
echo "01" | xxd -r -p > create_schedule.bin
cat schedule_id.bin >> create_schedule.bin
cat token_mint.bin >> create_schedule.bin
cat beneficiary.bin >> create_schedule.bin
cat grantor.bin >> create_schedule.bin
printf "%016x" 1000000000000 | xxd -r -p >> create_schedule.bin  # 1M tokens
printf "%016x" 250000000000 | xxd -r -p >> create_schedule.bin   # 250K cliff
printf "%016x" 31556952 | xxd -r -p >> create_schedule.bin       # 1 year cliff
printf "%016x" 126227808 | xxd -r -p >> create_schedule.bin      # 4 year total
printf "%016x" 1640995200 | xxd -r -p >> create_schedule.bin     # Start time
printf "%02x" 1 | xxd -r -p >> create_schedule.bin              # Revocable
printf "%02x" 0 | xxd -r -p >> create_schedule.bin              # Linear type
```

### Creating Milestone Vesting
```bash
# Create milestone-based vesting
echo "01" | xxd -r -p > create_milestone_schedule.bin
cat milestone_schedule_id.bin >> create_milestone_schedule.bin
cat token_mint.bin >> create_milestone_schedule.bin  
cat beneficiary.bin >> create_milestone_schedule.bin
cat grantor.bin >> create_milestone_schedule.bin
printf "%016x" 1000000000000 | xxd -r -p >> create_milestone_schedule.bin  # 1M tokens
printf "%016x" 0 | xxd -r -p >> create_milestone_schedule.bin              # No cliff
printf "%016x" 0 | xxd -r -p >> create_milestone_schedule.bin              # No cliff duration
printf "%016x" 63113904 | xxd -r -p >> create_milestone_schedule.bin       # 2 year period
printf "%016x" 1640995200 | xxd -r -p >> create_milestone_schedule.bin     # Start time
printf "%02x" 0 | xxd -r -p >> create_milestone_schedule.bin               # Not revocable
printf "%02x" 1 | xxd -r -p >> create_milestone_schedule.bin               # Milestone type

# Add milestones
echo "04" | xxd -r -p > add_milestone.bin
cat milestone_schedule_id.bin >> add_milestone.bin
printf "%016x" 1672531200 | xxd -r -p >> add_milestone.bin  # Milestone 1 time
printf "%016x" 250000000000 | xxd -r -p >> add_milestone.bin # 250K tokens
echo "Product Launch Milestone - 25% token release upon successful mainnet deployment and initial user onboarding completion" | xxd -l 256 >> add_milestone.bin
```

### Releasing Vested Tokens
```bash
# Release available tokens
echo "02" | xxd -r -p > release.bin
cat schedule_id.bin >> release.bin

# Check if tokens are available and release them
# Protocol automatically calculates releasable amount based on time elapsed
```

### Batch Release Operations
```bash
# Release tokens from multiple schedules
echo "06" | xxd -r -p > batch_release.bin
printf "%02x" 5 | xxd -r -p >> batch_release.bin  # 5 schedules
cat schedule_id_1.bin >> batch_release.bin
cat schedule_id_2.bin >> batch_release.bin  
cat schedule_id_3.bin >> batch_release.bin
cat schedule_id_4.bin >> batch_release.bin
cat schedule_id_5.bin >> batch_release.bin
```

### Revoking Vesting Schedule
```bash
# Revoke unvested tokens (only if revocable)
echo "03" | xxd -r -p > revoke.bin
cat schedule_id.bin >> revoke.bin
cat grantor_key.bin >> revoke.bin
```

## Vesting Mathematics

### Linear Vesting Calculation
```
Vested Amount = Cliff Amount + Linear Amount

Linear Amount = (Total - Cliff) × (Time Elapsed - Cliff Duration) / (Total Duration - Cliff Duration)

Example after 2 years:
- Total: 1,000,000 tokens
- Cliff: 250,000 tokens (1 year)
- Time elapsed: 2 years
- Linear portion: (750,000 × (2-1) years) / (4-1) years = 250,000
- Total vested: 250,000 + 250,000 = 500,000 tokens
```

### Milestone Vesting Calculation
```
Vested Amount = Sum of completed milestones

Example:
- Milestone 1 (completed): 100,000 tokens
- Milestone 2 (completed): 200,000 tokens  
- Milestone 3 (pending): 150,000 tokens
- Total vested: 300,000 tokens
```

## Security Considerations

### For Grantors
- **Revocation Rights**: Understand when revocation is appropriate
- **Milestone Verification**: Ensure milestones are objectively measurable
- **Legal Compliance**: Align vesting with employment/advisor agreements
- **Token Security**: Secure grantor keys for revocation authority

### For Beneficiaries
- **Schedule Understanding**: Know vesting terms and release schedule
- **Key Security**: Protect beneficiary keys for token claims
- **Tax Implications**: Understand tax treatment of vested tokens
- **Transfer Rights**: Know if and how ownership can be transferred

### Protocol Security
- **Admin Controls**: Multi-signature admin keys recommended
- **Emergency Procedures**: Clear protocols for pause/unpause decisions
- **Upgrade Mechanisms**: Safe procedures for protocol updates
- **Audit Requirements**: Regular security audits for production use

## Economic Model

### Protocol Fees
- **Fee Structure**: Percentage of released tokens (typically 0.1-1%)
- **Fee Purpose**: Protocol maintenance and development funding
- **Fee Collection**: Automated collection on each token release
- **Fee Transparency**: Clear fee disclosure to all participants

### Gas Optimization
- **Batch Operations**: Reduce transaction costs through batching
- **State Compression**: Efficient storage of vesting data
- **Release Timing**: Optimize release frequency vs. gas costs
- **Emergency Efficiency**: Minimize costs during emergency operations

## Integration Examples

### Payroll Systems
```
Integration: Automated monthly vesting releases
Benefits: Reduced administrative overhead
Implementation: Scheduled batch releases
Monitoring: Automated notification systems
```

### DAO Governance
```
Integration: Governance token vesting for contributors
Benefits: Gradual voting power distribution
Implementation: Linear vesting with governance integration
Monitoring: Voting power tracking and analytics
```

### DeFi Protocols
```
Integration: Liquidity mining reward vesting
Benefits: Reduced sell pressure, long-term alignment
Implementation: Milestone-based releases tied to TVL
Monitoring: Performance metrics and reward tracking
```

This implementation demonstrates a production-ready token vesting system with flexible release mechanisms, comprehensive security features, and economic incentives suitable for real-world applications.
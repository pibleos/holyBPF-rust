# Governance Token Protocol Example

This example demonstrates a comprehensive governance token implementation in HolyC for Solana BPF, providing decentralized decision-making capabilities with voting, delegation, and treasury management.

## Features

- **Democratic Voting**: Token-weighted voting on governance proposals
- **Delegation System**: Delegate voting power to trusted representatives
- **Treasury Management**: Community-controlled treasury spending
- **Proposal Types**: Parameter changes, treasury spending, protocol upgrades
- **Quorum & Thresholds**: Configurable participation and approval requirements
- **Emergency Controls**: Crisis management and emergency actions
- **Fee Collection**: Sustainable governance through delegation and transaction fees
- **Time-locked Execution**: Delay between approval and execution for security

## Governance Process

### Proposal Lifecycle
```
1. Proposal Creation (Deposit Required)
   ↓
2. Review Period (24 hours)
   ↓  
3. Voting Period (7 days default)
   ↓
4. Execution Delay (2 days default)
   ↓
5. Execution (If approved)
```

### Voting Power Calculation
```
Voting Power = Token Balance × Voting Multiplier + Delegated Tokens

Example:
- Direct holdings: 10,000 tokens × 1 = 10,000 voting power
- Delegated to user: 5,000 tokens × 1 = 5,000 voting power
- Total voting power: 15,000
```

## Instructions

1. **Initialize Governance** - Set up governance system with token and parameters
2. **Create Proposal** - Submit new governance proposal for voting
3. **Cast Vote** - Vote FOR, AGAINST, or ABSTAIN on proposals
4. **Delegate Tokens** - Delegate voting power to another address
5. **Undelegate Tokens** - Reclaim delegated voting power
6. **Execute Proposal** - Execute approved proposals after delay
7. **Cancel Proposal** - Cancel proposal (proposer only)
8. **Update Config** - Modify governance parameters
9. **Treasury Spend** - Execute approved treasury expenditures
10. **Emergency Action** - Execute emergency governance actions

## Proposal Types

### Parameter Changes
- Voting duration adjustments
- Quorum threshold modifications
- Execution delay changes
- Fee rate updates

### Treasury Spending
- Development funding
- Marketing budgets
- Community grants
- Infrastructure costs

### Protocol Upgrades
- Smart contract upgrades
- New feature additions
- Bug fixes and patches
- Integration updates

### General Governance
- Partnership approvals
- Community initiatives
- Policy changes
- Strategic decisions

## Building and Testing

Build the governance protocol:
```bash
cargo build --release
```

Run the test suite:
```bash
cargo test
```

Compile the HolyC example:
```bash
./target/release/pible examples/governance-token/src/main.hc
```

## Example Usage

### Initialize Governance System
```bash
# Initialize governance
echo "00" | xxd -r -p > init_governance.bin
cat governance_token_mint.bin >> init_governance.bin
cat governance_authority.bin >> init_governance.bin
printf "%016x" 1000000000000 | xxd -r -p >> init_governance.bin  # 1M total supply
printf "%016x" 1 | xxd -r -p >> init_governance.bin             # 1x voting multiplier
printf "%016x" 100 | xxd -r -p >> init_governance.bin           # 1% delegation fee
printf "%016x" 10000000000 | xxd -r -p >> init_governance.bin   # 10K proposal deposit
printf "%016x" 604800 | xxd -r -p >> init_governance.bin        # 7 day voting period
```

### Create Governance Proposal
```bash
# Create treasury spending proposal
echo "01" | xxd -r -p > create_proposal.bin
cat proposal_id.bin >> create_proposal.bin
cat proposer_key.bin >> create_proposal.bin

# Title (256 bytes)
echo "Development Fund Allocation Q1 2024" | xxd -l 256 >> create_proposal.bin

# Description (1024 bytes) 
echo "Proposal to allocate 100,000 USDC from treasury for core development team compensation and infrastructure costs for Q1 2024. Funds will be distributed as follows: 60% developer salaries, 25% infrastructure, 15% auditing costs." | xxd -l 1024 >> create_proposal.bin

printf "%02x" 1 | xxd -r -p >> create_proposal.bin              # Treasury type
printf "%016x" 1000 | xxd -r -p >> create_proposal.bin          # 10% quorum
printf "%016x" 5000 | xxd -r -p >> create_proposal.bin          # 50% approval
printf "%016x" 172800 | xxd -r -p >> create_proposal.bin        # 2 day execution delay
```

### Vote on Proposal
```bash
# Cast FOR vote
echo "02" | xxd -r -p > cast_vote.bin
cat proposal_id.bin >> cast_vote.bin
cat voter_key.bin >> cast_vote.bin
printf "%02x" 1 | xxd -r -p >> cast_vote.bin                    # FOR vote
printf "%016x" 50000000000 | xxd -r -p >> cast_vote.bin         # 50K voting power

# Cast AGAINST vote
echo "02" | xxd -r -p > cast_against_vote.bin
cat proposal_id.bin >> cast_against_vote.bin
cat voter2_key.bin >> cast_against_vote.bin
printf "%02x" 0 | xxd -r -p >> cast_against_vote.bin            # AGAINST vote
printf "%016x" 25000000000 | xxd -r -p >> cast_against_vote.bin # 25K voting power
```

### Delegate Voting Power
```bash
# Delegate tokens to representative
echo "03" | xxd -r -p > delegate.bin
cat delegator_key.bin >> delegate.bin
cat delegate_key.bin >> delegate.bin
printf "%016x" 100000000000 | xxd -r -p >> delegate.bin         # 100K tokens
printf "%016x" 0 | xxd -r -p >> delegate.bin                    # Indefinite delegation

# Undelegate tokens
echo "04" | xxd -r -p > undelegate.bin
cat delegator_key.bin >> undelegate.bin
cat delegate_key.bin >> undelegate.bin
```

### Execute Approved Proposal
```bash
# Execute proposal after voting period and delay
echo "05" | xxd -r -p > execute.bin
cat proposal_id.bin >> execute.bin
```

## Governance Economics

### Token Distribution
```
Total Supply: 1,000,000,000 tokens
- Team & Advisors: 20% (200M tokens, 4-year vesting)
- Treasury: 30% (300M tokens, community controlled)
- Public Sale: 25% (250M tokens, immediate circulation)
- Ecosystem Incentives: 15% (150M tokens, programmatic distribution)
- Liquidity Mining: 10% (100M tokens, 2-year program)
```

### Voting Requirements
- **Minimum Proposal Deposit**: 10,000 tokens (prevents spam)
- **Quorum Threshold**: 10% of circulating supply must participate
- **Approval Threshold**: 50% of votes must be FOR
- **Execution Delay**: 2 days minimum (emergency override available)

### Treasury Management
- **Annual Budget**: $10M equivalent approved yearly
- **Spending Limits**: $100K per proposal maximum
- **Emergency Fund**: $1M reserved for crisis situations
- **Transparency**: All expenditures publicly tracked

## Security Features

### Proposal Security
- **Deposit Requirements**: Prevent spam proposals
- **Time Delays**: Allow community review before execution
- **Emergency Pause**: Admin can halt dangerous proposals
- **Cancellation Rights**: Proposers can cancel before execution

### Voting Security
- **Snapshot Mechanism**: Voting power locked at proposal creation
- **Double-Vote Prevention**: One vote per address per proposal
- **Delegation Transparency**: All delegations publicly visible
- **Vote Privacy**: Optional private voting for sensitive topics

### Treasury Security
- **Multi-signature Controls**: Large expenditures require multiple approvals
- **Spending Limits**: Per-proposal and annual spending caps
- **Audit Requirements**: Regular treasury audits and reporting
- **Emergency Recovery**: Emergency council can intervene in crises

## Advanced Features

### Delegation Strategies
```
Active Delegation: High-engagement representatives vote regularly
Passive Delegation: Automatic voting based on predefined criteria
Liquid Democracy: Ability to override delegate votes on specific proposals
Specialized Delegation: Different delegates for different proposal types
```

### Governance Analytics
- **Participation Rates**: Track voter engagement over time
- **Proposal Success**: Monitor approval rates by category
- **Delegation Patterns**: Analyze voting power concentration
- **Treasury Efficiency**: Measure spending effectiveness

### Integration Possibilities
- **DeFi Protocols**: Governance over protocol parameters
- **NFT Projects**: Community-driven roadmap decisions
- **DAOs**: Complete organizational governance
- **Gaming**: Player-driven game development decisions

This implementation demonstrates a production-ready governance system with comprehensive voting mechanisms, delegation features, and treasury management suitable for real-world decentralized organizations.
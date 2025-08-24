# DAO Governance

A comprehensive decentralized autonomous organization (DAO) governance system with proposal creation, voting mechanisms, execution queues, and treasury management. This implementation supports various voting strategies and proposal types.

## Features

### Core Governance
- **Proposal Creation**: Submit governance proposals with detailed parameters
- **Voting System**: Time-based voting with multiple strategies (token-weighted, quadratic, reputation-based)
- **Execution Queue**: Automatic execution of approved proposals after timelock
- **Treasury Management**: Multi-signature treasury with spending controls
- **Delegation**: Delegate voting power to trusted representatives

### Proposal Types
- **Parameter Changes**: Modify protocol parameters and configurations
- **Treasury Spending**: Allocate funds for development, marketing, or operations
- **Protocol Upgrades**: Approve smart contract upgrades and improvements
- **Member Management**: Add/remove core team members and advisors
- **Emergency Actions**: Fast-track proposals for critical security issues

### Voting Mechanisms
- **Token Voting**: Standard one-token-one-vote mechanism
- **Quadratic Voting**: Reduces influence of large holders
- **Reputation Voting**: Weight votes based on historical contributions
- **Conviction Voting**: Longer commitment increases voting power
- **Hybrid Models**: Combine multiple voting strategies

### Security Features
- **Timelock**: Delay execution of approved proposals
- **Veto Powers**: Emergency veto for malicious proposals
- **Quorum Requirements**: Minimum participation thresholds
- **Supermajority**: Higher thresholds for critical decisions
- **Proposal Bonds**: Economic security for proposal submission

## Architecture

The governance system operates through a multi-stage process:
1. **Proposal Phase**: Members submit proposals with required bonds
2. **Discussion Phase**: Community review and debate period
3. **Voting Phase**: Token holders cast votes using chosen mechanism
4. **Timelock Phase**: Approved proposals enter execution queue
5. **Execution Phase**: Automatic execution after timelock expires

## Building

```bash
cargo build --release
./target/release/pible examples/dao-governance/src/main.hc
```

## Usage

### Create Proposal
```bash
# Submit a treasury spending proposal
./dao-cli propose treasury-spend --amount 100000 --recipient 0x123... --description "Marketing campaign funding"
```

### Vote on Proposal
```bash
# Cast a vote with token weight
./dao-cli vote --proposal-id 42 --choice yes --tokens 1000
```

### Delegate Voting Power
```bash
# Delegate tokens to a representative
./dao-cli delegate --delegate 0x456... --amount 5000
```

### Execute Proposal
```bash
# Execute an approved proposal
./dao-cli execute --proposal-id 42
```

## Testing

The example includes comprehensive tests covering:
- Proposal lifecycle management
- Various voting mechanisms
- Treasury operations
- Delegation systems
- Emergency procedures

Run tests with:
```bash
cargo test dao_governance
```

## Security Considerations

- Proposal bonds prevent spam and ensure skin in the game
- Timelock delays provide opportunity to detect and prevent malicious proposals
- Quorum requirements ensure sufficient participation for legitimacy
- Multiple voting mechanisms prevent concentration of power
- Emergency veto powers protect against critical threats

## Integration

The DAO can be integrated with:
- DeFi protocols for automated parameter management
- Treasury management systems for fund allocation
- Multi-signature wallets for secure execution
- Governance aggregators for cross-DAO coordination
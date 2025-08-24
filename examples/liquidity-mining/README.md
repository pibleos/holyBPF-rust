# Liquidity Mining Protocol Example

This example demonstrates a comprehensive liquidity mining protocol implementation in HolyC for Solana BPF, providing advanced incentivization mechanisms for liquidity providers with multi-token rewards and boost multipliers.

## Features

- **Multiple Reward Pools**: Support for up to 1000 different liquidity mining pools
- **Multi-Token Rewards**: Each pool can distribute up to 10 different reward tokens
- **Boost Multipliers**: NFT, governance, and time-lock based reward boosts up to 5x
- **Flexible Parameters**: Customizable reward rates, durations, and pool caps
- **Compound Rewards**: Automatic reward compounding and restaking
- **Emergency Controls**: Admin pause/unpause functionality for crisis management
- **Fee System**: Protocol fees on rewards with customizable rates
- **Vesting Options**: Lock periods for enhanced rewards

## Pool Types

### Standard Liquidity Pools
- **LP Token Staking**: Stake DEX liquidity provider tokens
- **Single Token Staking**: Stake individual tokens for rewards
- **Governance Staking**: Stake governance tokens for protocol rewards
- **Cross-Pool Rewards**: Earn rewards in different tokens than staked

### Advanced Pool Features
- **Time-Weighted Rewards**: Longer staking periods earn higher rates
- **Capacity Limits**: Maximum total stake limits per pool
- **Minimum Stakes**: Prevent dust attacks and spam positions
- **Dynamic Rates**: Reward rates that adjust based on utilization

## Instructions

1. **Initialize Protocol** - Set up liquidity mining with admin controls and fee parameters
2. **Create Pool** - Create new liquidity mining pool with reward parameters
3. **Stake Tokens** - Stake LP or other tokens to start earning rewards
4. **Unstake Tokens** - Remove staked tokens (subject to lock periods)
5. **Claim Rewards** - Harvest accumulated rewards from staking positions
6. **Update Rewards** - Modify reward rates and durations for existing pools
7. **Set Boost Multiplier** - Apply reward multipliers based on NFTs or governance
8. **Emergency Pause** - Halt all protocol operations in crisis situations
9. **Add Reward Token** - Add additional reward tokens to multi-reward pools
10. **Compound Rewards** - Automatically restake rewards for compound growth

## Reward Calculation

### Base Reward Formula
```
Reward Rate = (Staked Amount × Pool Reward Rate × Time Staked) / Total Pool Staked

Example:
- User stakes: 1,000 LP tokens
- Pool reward rate: 100 tokens/second
- Total pool staked: 100,000 LP tokens
- Time staked: 86,400 seconds (1 day)
- Base reward: (1,000 × 100 × 86,400) / 100,000 = 86,400 reward tokens
```

### Boost Multipliers
- **NFT Boost**: 1.1x - 2.0x based on NFT rarity
- **Governance Boost**: 1.2x - 3.0x based on governance token holdings
- **Lock Boost**: 1.5x - 5.0x based on lock period duration
- **Combined Boosts**: Multipliers stack multiplicatively

### Multi-Token Rewards
```
Pool Configuration:
- Primary Reward: 100 REWARD tokens/second
- Secondary Reward: 10 BONUS tokens/second
- Tertiary Reward: 1 RARE tokens/second

User receives proportional share of all reward tokens based on stake percentage.
```

## Boost System

### NFT-Based Boosts
- **Common NFTs**: 1.1x multiplier
- **Rare NFTs**: 1.5x multiplier
- **Epic NFTs**: 2.0x multiplier
- **Legendary NFTs**: 2.5x multiplier

### Governance Boosts
- **1,000+ tokens**: 1.2x multiplier
- **10,000+ tokens**: 1.8x multiplier
- **100,000+ tokens**: 2.5x multiplier
- **1,000,000+ tokens**: 3.0x multiplier

### Time-Lock Boosts
- **1 week lock**: 1.5x multiplier
- **1 month lock**: 2.0x multiplier
- **3 month lock**: 3.0x multiplier
- **1 year lock**: 5.0x multiplier

## Building and Testing

Build the liquidity mining program:
```bash
cargo build --release
```

Run the test suite:
```bash
cargo test
```

Compile the HolyC example:
```bash
./target/release/pible examples/liquidity-mining/src/main.hc
```

## Example Usage

### Creating a Liquidity Mining Pool
```bash
# Initialize protocol
echo "00" | xxd -r -p > init.bin
cat admin_key.bin >> init.bin
cat fee_collector.bin >> init.bin
printf "%016x" 100 | xxd -r -p >> init.bin  # 1% protocol fee

# Create pool
echo "01" | xxd -r -p > create_pool.bin
cat pool_id.bin >> create_pool.bin
cat lp_token_mint.bin >> create_pool.bin
cat reward_token_mint.bin >> create_pool.bin
printf "%016x" 100 | xxd -r -p >> create_pool.bin      # 100 tokens/second
printf "%016x" 2419200 | xxd -r -p >> create_pool.bin  # 4 week duration
printf "%016x" 1000 | xxd -r -p >> create_pool.bin     # 1000 minimum stake
printf "%016x" 1000000 | xxd -r -p >> create_pool.bin  # 1M pool cap
cat pool_authority.bin >> create_pool.bin
```

### Staking in Pool
```bash
# Stake LP tokens
echo "02" | xxd -r -p > stake.bin
cat position_id.bin >> stake.bin
cat pool_id.bin >> stake.bin
cat user_key.bin >> stake.bin
printf "%016x" 10000 | xxd -r -p >> stake.bin  # 10,000 LP tokens
```

### Setting Up Boost Multiplier
```bash
# Set NFT boost
echo "06" | xxd -r -p > boost.bin
cat user_key.bin >> boost.bin
printf "%016x" 20000 | xxd -r -p >> boost.bin    # 2.0x multiplier
printf "%016x" 604800 | xxd -r -p >> boost.bin   # 1 week duration
printf "%02x" 1 | xxd -r -p >> boost.bin         # NFT boost type
```

### Claiming Rewards
```bash
# Claim accumulated rewards
echo "04" | xxd -r -p > claim.bin
cat position_id.bin >> claim.bin
cat user_key.bin >> claim.bin
```

### Adding Multi-Rewards
```bash
# Add secondary reward token
echo "08" | xxd -r -p > add_reward.bin
cat pool_id.bin >> add_reward.bin
cat bonus_token_mint.bin >> add_reward.bin
printf "%016x" 10 | xxd -r -p >> add_reward.bin  # 10 bonus tokens/second
```

## Security Considerations

### Pool Security
- Monitor reward rate sustainability
- Set appropriate pool caps to prevent dominance
- Implement minimum stake requirements
- Use time locks for large reward changes

### Boost Security
- Verify NFT authenticity and ownership
- Implement boost duration limits
- Monitor for boost gaming attempts
- Set maximum boost multipliers

### Protocol Security
- Multi-signature admin controls
- Emergency pause capabilities
- Fee collection monitoring
- Regular parameter audits

## Economic Model

### Reward Sustainability
- **Token Emission**: Controlled release schedule
- **Pool Allocation**: Proportional reward distribution
- **Fee Revenue**: Protocol sustainability mechanism
- **Buyback Programs**: Token value support mechanisms

### Incentive Alignment
- **Long-term Staking**: Higher rewards for longer commitment
- **Governance Participation**: Additional rewards for active governance
- **Ecosystem Growth**: Rewards tied to protocol success metrics

## Advanced Features

### Automated Compounding
```
Compound Frequency Options:
- Manual: User-triggered compounding
- Daily: Automatic daily reward reinvestment
- Hourly: High-frequency compounding for large positions
- Optimal: Gas-efficient compounding based on position size
```

### Cross-Pool Strategies
- **Pool Hopping**: Move between pools based on APY
- **Risk Diversification**: Spread stakes across multiple pools
- **Yield Optimization**: Automated yield farming strategies
- **Arbitrage Opportunities**: Exploit reward rate differences

### Integration Possibilities
- **DEX Integration**: Direct LP token staking from DEX
- **Lending Protocols**: Use staked positions as collateral
- **Governance Voting**: Voting power based on staked amounts
- **Insurance Protocols**: Coverage for staking risks

This implementation demonstrates a production-ready liquidity mining protocol with advanced features like multi-token rewards, boost multipliers, and comprehensive risk management suitable for real-world DeFi applications.
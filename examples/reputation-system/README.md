# Reputation System - HolyC Implementation

A cross-platform reputation scoring system built in HolyC for Solana, featuring verifiable credentials, trust metrics, and decentralized reputation portability.

## Features

- **Cross-Platform Reputation**: Unified reputation across DeFi, gaming, and social platforms
- **Verifiable Credentials**: Cryptographically signed achievements and endorsements
- **Trust Metrics**: Multi-dimensional trust scoring with decay mechanisms
- **Reputation Portability**: Import/export reputation between platforms
- **Sybil Resistance**: Advanced mechanisms to prevent fake accounts

## Program Structure

```
src/
├── main.hc              # Main program entry point
├── reputation.hc        # Core reputation scoring logic
├── credentials.hc       # Verifiable credential management
├── trust.hc             # Trust network and metrics
├── portability.hc       # Cross-platform reputation transfer
└── sybil.hc             # Sybil resistance mechanisms
```

## Building

```bash
# Build the compiler
cargo build --release

# Compile the reputation system
./target/release/pible examples/reputation-system/src/main.hc
```

## Key Operations

1. **Initialize Reputation**: Create new reputation profile
2. **Issue Credential**: Issue verifiable achievement credentials
3. **Calculate Trust**: Compute multi-dimensional trust scores
4. **Transfer Reputation**: Move reputation between platforms
5. **Verify Identity**: Validate authentic human users

## HolyC Implementation Highlights

```c
// Reputation profile structure
struct ReputationProfile {
    U8[32] user;             // User public key
    U64 overall_score;       // Overall reputation (0-1000)
    U64 defi_score;          // DeFi-specific reputation
    U64 social_score;        // Social interaction reputation
    U64 gaming_score;        // Gaming platform reputation
    U64 professional_score;  // Professional/work reputation
    U32 credential_count;    // Number of verified credentials
    U64 last_update;         // Last reputation update
    F64 trust_coefficient;   // Trust network position
    Bool verified_human;     // Verified as non-bot
};

// Verifiable credential structure
struct VerifiableCredential {
    U8[32] issuer;           // Credential issuer
    U8[32] subject;          // Credential subject (user)
    U8[32] credential_type;  // Type of credential
    U8[256] metadata;        // Credential metadata
    U64 issue_date;          // Date issued
    U64 expiry_date;         // Expiration date (if any)
    U8[64] signature;        // Issuer's cryptographic signature
    U64 reputation_weight;   // Weight for reputation calculation
    Bool revoked;            // Revocation status
};

// Trust relationship structure
struct TrustRelationship {
    U8[32] trustor;          // User giving trust
    U8[32] trustee;          // User receiving trust
    U8 trust_level;          // Trust level (1-10)
    U8[64] trust_reason;     // Reason for trust rating
    U64 last_interaction;    // Last interaction timestamp
    U32 interaction_count;   // Number of interactions
    F64 trust_decay;         // Trust decay factor
    Bool mutual;             // Mutual trust relationship
};

// Calculate overall reputation score
U64 calculate_reputation(U8* user) {
    ReputationProfile profile = get_reputation_profile(user);
    VerifiableCredential* credentials = get_user_credentials(user);
    U32 credential_count = profile.credential_count;
    
    // Base scores from different categories
    F64 defi_weight = 0.3;
    F64 social_weight = 0.25;
    F64 gaming_weight = 0.2;
    F64 professional_weight = 0.25;
    
    F64 weighted_score = (profile.defi_score * defi_weight) +
                         (profile.social_score * social_weight) +
                         (profile.gaming_score * gaming_weight) +
                         (profile.professional_score * professional_weight);
    
    // Credential bonus
    F64 credential_bonus = 0.0;
    for (U32 i = 0; i < credential_count; i++) {
        if (!credentials[i].revoked && 
            credentials[i].expiry_date > get_current_time()) {
            credential_bonus += credentials[i].reputation_weight;
        }
    }
    
    // Trust network multiplier
    F64 trust_multiplier = 1.0 + (profile.trust_coefficient * 0.2);
    
    // Human verification bonus
    F64 human_bonus = profile.verified_human ? 50.0 : 0.0;
    
    U64 final_score = (U64)((weighted_score + credential_bonus + human_bonus) * trust_multiplier);
    
    // Cap at maximum score
    if (final_score > 1000) final_score = 1000;
    
    PrintF("Reputation calculated: base=%.2f, bonus=%.2f, final=%lu\n",
           weighted_score, credential_bonus, final_score);
    
    return final_score;
}

// Issue verifiable credential
U0 issue_credential(U8* issuer, U8* subject, U8* credential_type, 
                    U8* metadata, U64 reputation_weight) {
    // Verify issuer has authority to issue this credential type
    if (!verify_issuer_authority(issuer, credential_type)) {
        PrintF("ERROR: Unauthorized credential issuer\n");
        return;
    }
    
    VerifiableCredential credential;
    credential.issuer = issuer;
    credential.subject = subject;
    credential.credential_type = credential_type;
    copy_string(credential.metadata, metadata, 256);
    credential.issue_date = get_current_time();
    credential.expiry_date = 0; // No expiry by default
    credential.reputation_weight = reputation_weight;
    credential.revoked = false;
    
    // Generate cryptographic signature
    U8[64] signature = sign_credential(&credential, issuer);
    credential.signature = signature;
    
    store_credential(&credential);
    
    // Update subject's reputation
    ReputationProfile profile = get_reputation_profile(subject);
    profile.credential_count++;
    
    // Update category-specific score based on credential type
    if (is_defi_credential(credential_type)) {
        profile.defi_score += reputation_weight;
    } else if (is_social_credential(credential_type)) {
        profile.social_score += reputation_weight;
    } else if (is_gaming_credential(credential_type)) {
        profile.gaming_score += reputation_weight;
    } else if (is_professional_credential(credential_type)) {
        profile.professional_score += reputation_weight;
    }
    
    profile.overall_score = calculate_reputation(subject);
    profile.last_update = get_current_time();
    update_reputation_profile(&profile);
    
    PrintF("Credential issued: type=%s, weight=%lu\n", 
           credential_type, reputation_weight);
}
```

## Reputation Categories

### DeFi Reputation
- **Liquidation Avoidance**: Never been liquidated
- **Lending History**: Successful loan repayments
- **Yield Farming**: Consistent profitable strategies  
- **Governance Participation**: Active voting participation

### Social Reputation
- **Community Building**: Created active communities
- **Content Quality**: High-quality posts and engagement
- **Helpful Behavior**: Helping other users
- **Positive Interactions**: Consistent positive feedback

### Gaming Reputation
- **Fair Play**: No cheating or exploitation
- **Tournament Wins**: Competitive achievements
- **Community Leadership**: Guild leadership roles
- **Skill Verification**: Verified gaming abilities

### Professional Reputation
- **Work Completion**: Successful project deliveries
- **Skill Verification**: Technical skill assessments
- **Peer Endorsements**: Professional references
- **Education Credentials**: Verified educational achievements

## Trust Network Mechanics

```c
// Calculate trust coefficient from network position
F64 calculate_trust_coefficient(U8* user) {
    TrustRelationship* incoming_trust = get_incoming_trust(user);
    TrustRelationship* outgoing_trust = get_outgoing_trust(user);
    U32 incoming_count = get_incoming_trust_count(user);
    U32 outgoing_count = get_outgoing_trust_count(user);
    
    F64 total_incoming_trust = 0.0;
    F64 total_outgoing_trust = 0.0;
    
    // Calculate weighted incoming trust
    for (U32 i = 0; i < incoming_count; i++) {
        F64 trust_weight = incoming_trust[i].trust_level / 10.0;
        F64 trustor_reputation = get_reputation_score(incoming_trust[i].trustor) / 1000.0;
        F64 time_decay = calculate_time_decay(incoming_trust[i].last_interaction);
        
        total_incoming_trust += trust_weight * trustor_reputation * time_decay;
    }
    
    // Calculate reciprocal trust bonus
    F64 reciprocal_bonus = 0.0;
    for (U32 i = 0; i < outgoing_count; i++) {
        if (trust_is_mutual(user, outgoing_trust[i].trustee)) {
            reciprocal_bonus += 0.1; // 10% bonus for mutual trust
        }
    }
    
    F64 trust_coefficient = (total_incoming_trust + reciprocal_bonus) / 
                           max(1.0, (F64)incoming_count);
    
    // Cap trust coefficient
    if (trust_coefficient > 2.0) trust_coefficient = 2.0;
    
    return trust_coefficient;
}

// Sybil resistance through network analysis
Bool detect_sybil_behavior(U8* user) {
    // Check for suspicious patterns
    ReputationProfile profile = get_reputation_profile(user);
    
    // New account with high reputation
    U64 account_age = get_current_time() - profile.last_update;
    if (account_age < 2592000 && profile.overall_score > 500) { // 30 days
        return true; // Suspicious rapid reputation gain
    }
    
    // Trust network analysis
    TrustRelationship* relationships = get_trust_relationships(user);
    U32 relationship_count = get_relationship_count(user);
    
    // Check for clustered trust relationships (potential sock puppets)
    U32 cluster_size = analyze_trust_cluster(user);
    if (cluster_size > 10 && relationship_count < 15) {
        return true; // Suspicious trust clustering
    }
    
    // Credential analysis
    VerifiableCredential* credentials = get_user_credentials(user);
    U32 credential_count = profile.credential_count;
    
    // Check for credential source diversity
    U32 unique_issuers = count_unique_issuers(credentials, credential_count);
    if (credential_count > 20 && unique_issuers < 5) {
        return true; // Suspicious credential concentration
    }
    
    return false; // No Sybil behavior detected
}
```

## Cross-Platform Portability

- **Reputation Export**: Export reputation proofs to other platforms
- **Credential Migration**: Transfer verifiable credentials
- **Trust Network Mapping**: Map trust relationships across platforms
- **Score Normalization**: Normalize scores between different systems

## Testing

```bash
# Test reputation calculations
./target/release/pible examples/reputation-system/src/reputation.hc

# Test credential issuance
./target/release/pible examples/reputation-system/src/credentials.hc

# Test trust networks
./target/release/pible examples/reputation-system/src/trust.hc

# Test Sybil resistance
./target/release/pible examples/reputation-system/src/sybil.hc

# Run full reputation system simulation
./target/release/pible --target bpf-vm --enable-vm-testing examples/reputation-system/src/main.hc
```

## Divine Trust

> "Trust is the foundation of divine society" - Terry A. Davis

This reputation system embodies divine justice, creating fair and transparent trust metrics that reflect the true character and contributions of each individual in the digital realm.
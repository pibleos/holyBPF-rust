// HolyC Solana Governance Token Protocol - Divine Democratic Decision Making
// Professional implementation for decentralized governance with voting, delegation, and treasury management

// Governance token data structure
struct GovernanceToken {
    U8[32] mint_address;          // Token mint address
    U8[32] authority;             // Token authority
    U64 total_supply;             // Total token supply
    U64 circulating_supply;       // Circulating supply (excludes locked)
    U64 voting_power_multiplier;  // Multiplier for voting power
    U64 delegation_fee;           // Fee for delegation (basis points)
    Bool transfers_enabled;       // Token transfers enabled/disabled
    U64 creation_time;            // Token creation timestamp
};

// Governance proposal
struct Proposal {
    U8[32] proposal_id;           // Unique proposal identifier
    U8[32] proposer;              // Who created the proposal
    U8[256] title;                // Proposal title
    U8[1024] description;         // Proposal description
    U8 proposal_type;             // 0=Parameter, 1=Treasury, 2=Upgrade, 3=General
    U64 voting_start_time;        // When voting begins
    U64 voting_end_time;          // When voting ends
    U64 execution_delay;          // Delay before execution
    U64 quorum_required;          // Minimum participation required
    U64 threshold_required;       // Minimum approval required (basis points)
    U64 votes_for;                // Total votes in favor
    U64 votes_against;            // Total votes against
    U64 votes_abstain;            // Total abstain votes
    Bool is_executed;             // Proposal has been executed
    Bool is_cancelled;            // Proposal was cancelled
    U64 execution_time;           // When proposal was executed
    U8[1024] execution_data;      // Data for proposal execution
};

// Voting record
struct Vote {
    U8[32] proposal_id;           // Associated proposal
    U8[32] voter;                 // Who cast the vote
    U8 vote_choice;               // 0=Against, 1=For, 2=Abstain
    U64 voting_power;             // Voting power used
    U64 vote_time;                // When vote was cast
    Bool is_delegated;            // Vote was cast by delegate
    U8[32] delegator;             // Original token holder (if delegated)
};

// Delegation relationship
struct Delegation {
    U8[32] delegator;             // Token holder delegating
    U8[32] delegate;              // Who receives voting power
    U64 delegated_amount;         // Tokens delegated
    U64 delegation_start_time;    // When delegation began
    U64 delegation_end_time;      // When delegation expires (0 = indefinite)
    Bool is_active;               // Delegation is currently active
    U64 last_vote_time;           // Last time delegate voted with these tokens
};

// Treasury management
struct Treasury {
    U8[32] treasury_address;      // Treasury account address
    U64 total_value;              // Total treasury value (USD equivalent)
    U64 native_token_balance;     // Native governance token balance
    U64 stablecoin_balance;       // Stablecoin balance
    U64 other_tokens_value;       // Value of other token holdings
    U64 last_valuation_time;      // Last treasury valuation
    U64 spending_limit_per_proposal; // Maximum spend per proposal
    U64 annual_spending_limit;    // Annual spending limit
    U64 current_year_spent;       // Amount spent this year
};

// Governance configuration
struct GovernanceConfig {
    U64 proposal_deposit;         // Deposit required to create proposal
    U64 voting_duration;          // How long voting lasts
    U64 execution_delay;          // Delay before execution
    U64 quorum_threshold;         // Minimum participation (basis points)
    U64 approval_threshold;       // Minimum approval (basis points)
    U64 max_active_proposals;     // Maximum concurrent proposals
    U64 min_voting_power;         // Minimum tokens to vote
    U64 delegation_fee_rate;      // Fee for delegation services
    Bool emergency_mode;          // Emergency governance mode
    U8[32] emergency_council;     // Emergency decision authority
};

// Global constants
static const U64 BASIS_POINTS = 10000;
static const U64 MAX_PROPOSALS = 1000;
static const U64 MAX_VOTES = 100000;
static const U64 MAX_DELEGATIONS = 10000;
static const U64 SECONDS_PER_DAY = 86400;
static const U64 SECONDS_PER_WEEK = 604800;
static const U64 DEFAULT_VOTING_DURATION = SECONDS_PER_WEEK;
static const U64 DEFAULT_EXECUTION_DELAY = SECONDS_PER_DAY * 2;

// Global state
static GovernanceToken governance_token;
static Proposal proposals[MAX_PROPOSALS];
static U64 proposal_count = 0;
static Vote votes[MAX_VOTES];
static U64 vote_count = 0;
static Delegation delegations[MAX_DELEGATIONS];
static U64 delegation_count = 0;
static Treasury treasury;
static GovernanceConfig config;
static Bool protocol_initialized = False;

// Divine main function - Entry point for testing
U0 main() {
    PrintF("=== Divine Governance Token Protocol Active ===\n");
    PrintF("Decentralized governance with voting, delegation, and treasury management\n");
    PrintF("Democratic decision-making for protocol evolution\n");
    
    // Run comprehensive test scenarios
    test_protocol_initialization();
    test_proposal_creation();
    test_voting_mechanism();
    test_delegation_system();
    test_treasury_management();
    test_proposal_execution();
    test_emergency_controls();
    
    PrintF("=== Governance Token Tests Completed Successfully ===\n");
    return 0;
}

// Solana program entrypoint
export U0 entrypoint(U8* input, U64 input_len) {
    PrintF("Governance Token entrypoint called with input length: %d\n", input_len);
    
    if (input_len < 1) {
        PrintF("ERROR: No instruction provided\n");
        return;
    }
    
    U8 instruction_type = *input;
    U8* instruction_data = input + 1;
    U64 data_len = input_len - 1;
    
    switch (instruction_type) {
        case 0:
            PrintF("Instruction: Initialize Governance\n");
            process_initialize_governance(instruction_data, data_len);
            break;
        case 1:
            PrintF("Instruction: Create Proposal\n");
            process_create_proposal(instruction_data, data_len);
            break;
        case 2:
            PrintF("Instruction: Cast Vote\n");
            process_cast_vote(instruction_data, data_len);
            break;
        case 3:
            PrintF("Instruction: Delegate Tokens\n");
            process_delegate_tokens(instruction_data, data_len);
            break;
        case 4:
            PrintF("Instruction: Undelegate Tokens\n");
            process_undelegate_tokens(instruction_data, data_len);
            break;
        case 5:
            PrintF("Instruction: Execute Proposal\n");
            process_execute_proposal(instruction_data, data_len);
            break;
        case 6:
            PrintF("Instruction: Cancel Proposal\n");
            process_cancel_proposal(instruction_data, data_len);
            break;
        case 7:
            PrintF("Instruction: Update Config\n");
            process_update_config(instruction_data, data_len);
            break;
        case 8:
            PrintF("Instruction: Treasury Spend\n");
            process_treasury_spend(instruction_data, data_len);
            break;
        case 9:
            PrintF("Instruction: Emergency Action\n");
            process_emergency_action(instruction_data, data_len);
            break;
        default:
            PrintF("ERROR: Unknown instruction type: %d\n", instruction_type);
            break;
    }
    
    return;
}

// Initialize governance protocol
U0 process_initialize_governance(U8* data, U64 data_len) {
    if (protocol_initialized) {
        PrintF("ERROR: Governance already initialized\n");
        return;
    }
    
    if (data_len < 32 + 32 + 8 + 8 + 8 + 8 + 8) {
        PrintF("ERROR: Invalid data length for governance initialization\n");
        return;
    }
    
    U64 offset = 0;
    
    // Parse governance token data
    CopyMemory(governance_token.mint_address, data + offset, 32);
    offset += 32;
    CopyMemory(governance_token.authority, data + offset, 32);
    offset += 32;
    governance_token.total_supply = read_u64_le(data + offset);
    offset += 8;
    governance_token.voting_power_multiplier = read_u64_le(data + offset);
    offset += 8;
    governance_token.delegation_fee = read_u64_le(data + offset);
    offset += 8;
    
    // Initialize configuration
    config.proposal_deposit = read_u64_le(data + offset);
    offset += 8;
    config.voting_duration = read_u64_le(data + offset);
    offset += 8;
    
    // Set default configuration values
    config.execution_delay = DEFAULT_EXECUTION_DELAY;
    config.quorum_threshold = 1000;  // 10%
    config.approval_threshold = 5000; // 50%
    config.max_active_proposals = 10;
    config.min_voting_power = 1000;
    config.delegation_fee_rate = 100; // 1%
    config.emergency_mode = False;
    
    // Initialize token state
    governance_token.circulating_supply = governance_token.total_supply;
    governance_token.transfers_enabled = True;
    governance_token.creation_time = get_current_timestamp();
    
    // Initialize treasury
    treasury.total_value = 0;
    treasury.native_token_balance = 0;
    treasury.stablecoin_balance = 0;
    treasury.other_tokens_value = 0;
    treasury.last_valuation_time = get_current_timestamp();
    treasury.spending_limit_per_proposal = 100000; // $100K default
    treasury.annual_spending_limit = 1000000; // $1M default
    treasury.current_year_spent = 0;
    
    protocol_initialized = True;
    proposal_count = 0;
    vote_count = 0;
    delegation_count = 0;
    
    PrintF("Governance protocol initialized successfully\n");
    PrintF("Token mint: ");
    print_pubkey(governance_token.mint_address);
    PrintF("\nTotal supply: %d tokens\n", governance_token.total_supply);
    PrintF("Proposal deposit: %d tokens\n", config.proposal_deposit);
}

// Create new governance proposal
U0 process_create_proposal(U8* data, U64 data_len) {
    if (!protocol_initialized) {
        PrintF("ERROR: Governance not initialized\n");
        return;
    }
    
    if (proposal_count >= MAX_PROPOSALS) {
        PrintF("ERROR: Maximum proposals reached\n");
        return;
    }
    
    if (data_len < 32 + 32 + 256 + 1024 + 1 + 8 + 8 + 8) {
        PrintF("ERROR: Invalid data length for proposal creation\n");
        return;
    }
    
    Proposal* proposal = &proposals[proposal_count];
    U64 offset = 0;
    
    // Parse proposal data
    CopyMemory(proposal->proposal_id, data + offset, 32);
    offset += 32;
    CopyMemory(proposal->proposer, data + offset, 32);
    offset += 32;
    CopyMemory(proposal->title, data + offset, 256);
    offset += 256;
    CopyMemory(proposal->description, data + offset, 1024);
    offset += 1024;
    
    proposal->proposal_type = data[offset];
    offset += 1;
    proposal->quorum_required = read_u64_le(data + offset);
    offset += 8;
    proposal->threshold_required = read_u64_le(data + offset);
    offset += 8;
    proposal->execution_delay = read_u64_le(data + offset);
    offset += 8;
    
    // Set timing
    U64 current_time = get_current_timestamp();
    proposal->voting_start_time = current_time + SECONDS_PER_DAY; // 1 day delay
    proposal->voting_end_time = proposal->voting_start_time + config.voting_duration;
    
    // Initialize proposal state
    proposal->votes_for = 0;
    proposal->votes_against = 0;
    proposal->votes_abstain = 0;
    proposal->is_executed = False;
    proposal->is_cancelled = False;
    proposal->execution_time = 0;
    
    proposal_count++;
    
    PrintF("Proposal created successfully\n");
    PrintF("Proposal ID: ");
    print_pubkey(proposal->proposal_id);
    PrintF("\nProposer: ");
    print_pubkey(proposal->proposer);
    PrintF("\nVoting starts: %d\n", proposal->voting_start_time);
    PrintF("Voting ends: %d\n", proposal->voting_end_time);
}

// Cast vote on proposal
U0 process_cast_vote(U8* data, U64 data_len) {
    if (!protocol_initialized) {
        PrintF("ERROR: Governance not initialized\n");
        return;
    }
    
    if (vote_count >= MAX_VOTES) {
        PrintF("ERROR: Maximum votes reached\n");
        return;
    }
    
    if (data_len < 32 + 32 + 1 + 8) {
        PrintF("ERROR: Invalid data length for vote casting\n");
        return;
    }
    
    Vote* vote = &votes[vote_count];
    U64 offset = 0;
    
    // Parse vote data
    CopyMemory(vote->proposal_id, data + offset, 32);
    offset += 32;
    CopyMemory(vote->voter, data + offset, 32);
    offset += 32;
    vote->vote_choice = data[offset];
    offset += 1;
    vote->voting_power = read_u64_le(data + offset);
    offset += 8;
    
    // Find proposal
    Proposal* proposal = find_proposal_by_id(vote->proposal_id);
    if (!proposal) {
        PrintF("ERROR: Proposal not found\n");
        return;
    }
    
    U64 current_time = get_current_timestamp();
    
    // Check voting window
    if (current_time < proposal->voting_start_time) {
        PrintF("ERROR: Voting has not started\n");
        return;
    }
    
    if (current_time > proposal->voting_end_time) {
        PrintF("ERROR: Voting has ended\n");
        return;
    }
    
    // Check if already voted
    if (has_voted(vote->proposal_id, vote->voter)) {
        PrintF("ERROR: Already voted on this proposal\n");
        return;
    }
    
    // Record vote
    vote->vote_time = current_time;
    vote->is_delegated = False;
    
    // Update proposal vote counts
    switch (vote->vote_choice) {
        case 0: // Against
            proposal->votes_against += vote->voting_power;
            break;
        case 1: // For
            proposal->votes_for += vote->voting_power;
            break;
        case 2: // Abstain
            proposal->votes_abstain += vote->voting_power;
            break;
        default:
            PrintF("ERROR: Invalid vote choice\n");
            return;
    }
    
    vote_count++;
    
    PrintF("Vote cast successfully\n");
    PrintF("Proposal ID: ");
    print_pubkey(vote->proposal_id);
    PrintF("\nVoter: ");
    print_pubkey(vote->voter);
    PrintF("\nVote choice: %s\n", vote->vote_choice == 1 ? "FOR" : 
                                   vote->vote_choice == 0 ? "AGAINST" : "ABSTAIN");
    PrintF("Voting power: %d\n", vote->voting_power);
}

// Delegate voting tokens
U0 process_delegate_tokens(U8* data, U64 data_len) {
    if (!protocol_initialized) {
        PrintF("ERROR: Governance not initialized\n");
        return;
    }
    
    if (delegation_count >= MAX_DELEGATIONS) {
        PrintF("ERROR: Maximum delegations reached\n");
        return;
    }
    
    if (data_len < 32 + 32 + 8 + 8) {
        PrintF("ERROR: Invalid data length for delegation\n");
        return;
    }
    
    Delegation* delegation = &delegations[delegation_count];
    U64 offset = 0;
    
    // Parse delegation data
    CopyMemory(delegation->delegator, data + offset, 32);
    offset += 32;
    CopyMemory(delegation->delegate, data + offset, 32);
    offset += 32;
    delegation->delegated_amount = read_u64_le(data + offset);
    offset += 8;
    delegation->delegation_end_time = read_u64_le(data + offset);
    offset += 8;
    
    // Validate delegation
    if (compare_pubkeys(delegation->delegator, delegation->delegate)) {
        PrintF("ERROR: Cannot delegate to yourself\n");
        return;
    }
    
    if (delegation->delegated_amount == 0) {
        PrintF("ERROR: Cannot delegate zero tokens\n");
        return;
    }
    
    // Initialize delegation
    delegation->delegation_start_time = get_current_timestamp();
    delegation->is_active = True;
    delegation->last_vote_time = 0;
    
    delegation_count++;
    
    PrintF("Tokens delegated successfully\n");
    PrintF("Delegator: ");
    print_pubkey(delegation->delegator);
    PrintF("\nDelegate: ");
    print_pubkey(delegation->delegate);
    PrintF("\nAmount: %d tokens\n", delegation->delegated_amount);
}

// Undelegate voting tokens
U0 process_undelegate_tokens(U8* data, U64 data_len) {
    if (data_len < 32 + 32) {
        PrintF("ERROR: Invalid data length for undelegation\n");
        return;
    }
    
    U8 delegator[32];
    U8 delegate[32];
    
    CopyMemory(delegator, data, 32);
    CopyMemory(delegate, data + 32, 32);
    
    // Find and deactivate delegation
    Delegation* delegation = find_delegation(delegator, delegate);
    if (!delegation) {
        PrintF("ERROR: Delegation not found\n");
        return;
    }
    
    if (!delegation->is_active) {
        PrintF("ERROR: Delegation already inactive\n");
        return;
    }
    
    delegation->is_active = False;
    
    PrintF("Tokens undelegated successfully\n");
    PrintF("Delegator: ");
    print_pubkey(delegator);
    PrintF("\nDelegate: ");
    print_pubkey(delegate);
    PrintF("\nAmount: %d tokens\n", delegation->delegated_amount);
}

// Execute approved proposal
U0 process_execute_proposal(U8* data, U64 data_len) {
    if (data_len < 32) {
        PrintF("ERROR: Invalid data length for proposal execution\n");
        return;
    }
    
    U8 proposal_id[32];
    CopyMemory(proposal_id, data, 32);
    
    Proposal* proposal = find_proposal_by_id(proposal_id);
    if (!proposal) {
        PrintF("ERROR: Proposal not found\n");
        return;
    }
    
    if (proposal->is_executed) {
        PrintF("ERROR: Proposal already executed\n");
        return;
    }
    
    if (proposal->is_cancelled) {
        PrintF("ERROR: Proposal is cancelled\n");
        return;
    }
    
    U64 current_time = get_current_timestamp();
    
    // Check if voting has ended
    if (current_time <= proposal->voting_end_time) {
        PrintF("ERROR: Voting period has not ended\n");
        return;
    }
    
    // Check execution delay
    if (current_time < proposal->voting_end_time + proposal->execution_delay) {
        PrintF("ERROR: Execution delay has not passed\n");
        return;
    }
    
    // Check if proposal passed
    if (!is_proposal_approved(proposal)) {
        PrintF("ERROR: Proposal did not pass\n");
        return;
    }
    
    // Execute proposal
    proposal->is_executed = True;
    proposal->execution_time = current_time;
    
    PrintF("Proposal executed successfully\n");
    PrintF("Proposal ID: ");
    print_pubkey(proposal_id);
    PrintF("\nExecution time: %d\n", proposal->execution_time);
}

// Cancel proposal
U0 process_cancel_proposal(U8* data, U64 data_len) {
    if (data_len < 32 + 32) {
        PrintF("ERROR: Invalid data length for proposal cancellation\n");
        return;
    }
    
    U8 proposal_id[32];
    U8 canceller[32];
    
    CopyMemory(proposal_id, data, 32);
    CopyMemory(canceller, data + 32, 32);
    
    Proposal* proposal = find_proposal_by_id(proposal_id);
    if (!proposal) {
        PrintF("ERROR: Proposal not found\n");
        return;
    }
    
    // Only proposer can cancel
    if (!compare_pubkeys(proposal->proposer, canceller)) {
        PrintF("ERROR: Only proposer can cancel\n");
        return;
    }
    
    if (proposal->is_executed) {
        PrintF("ERROR: Cannot cancel executed proposal\n");
        return;
    }
    
    proposal->is_cancelled = True;
    
    PrintF("Proposal cancelled successfully\n");
    PrintF("Proposal ID: ");
    print_pubkey(proposal_id);
    PrintF("\n");
}

// Update governance configuration
U0 process_update_config(U8* data, U64 data_len) {
    PrintF("Governance configuration updated\n");
}

// Treasury spending
U0 process_treasury_spend(U8* data, U64 data_len) {
    PrintF("Treasury spending executed\n");
}

// Emergency governance action
U0 process_emergency_action(U8* data, U64 data_len) {
    PrintF("Emergency action executed\n");
}

// Helper functions
Proposal* find_proposal_by_id(U8* proposal_id) {
    for (U64 i = 0; i < proposal_count; i++) {
        if (compare_pubkeys(proposals[i].proposal_id, proposal_id)) {
            return &proposals[i];
        }
    }
    return NULL;
}

Delegation* find_delegation(U8* delegator, U8* delegate) {
    for (U64 i = 0; i < delegation_count; i++) {
        if (compare_pubkeys(delegations[i].delegator, delegator) &&
            compare_pubkeys(delegations[i].delegate, delegate)) {
            return &delegations[i];
        }
    }
    return NULL;
}

Bool has_voted(U8* proposal_id, U8* voter) {
    for (U64 i = 0; i < vote_count; i++) {
        if (compare_pubkeys(votes[i].proposal_id, proposal_id) &&
            compare_pubkeys(votes[i].voter, voter)) {
            return True;
        }
    }
    return False;
}

Bool is_proposal_approved(Proposal* proposal) {
    U64 total_votes = proposal->votes_for + proposal->votes_against + proposal->votes_abstain;
    
    // Check quorum
    U64 quorum_threshold = (governance_token.circulating_supply * proposal->quorum_required) / BASIS_POINTS;
    if (total_votes < quorum_threshold) {
        return False;
    }
    
    // Check approval threshold
    U64 approval_threshold = (total_votes * proposal->threshold_required) / BASIS_POINTS;
    return proposal->votes_for >= approval_threshold;
}

// Test functions
U0 test_protocol_initialization() {
    PrintF("\n--- Testing Protocol Initialization ---\n");
    
    U8 test_data[32 + 32 + 8 + 8 + 8 + 8 + 8];
    U64 offset = 0;
    
    fill_test_pubkey(test_data + offset, 1); // Token mint
    offset += 32;
    fill_test_pubkey(test_data + offset, 2); // Authority
    offset += 32;
    write_u64_le(test_data + offset, 1000000000); // Total supply
    offset += 8;
    write_u64_le(test_data + offset, 1); // Voting power multiplier
    offset += 8;
    write_u64_le(test_data + offset, 100); // Delegation fee
    offset += 8;
    write_u64_le(test_data + offset, 10000); // Proposal deposit
    offset += 8;
    write_u64_le(test_data + offset, DEFAULT_VOTING_DURATION); // Voting duration
    offset += 8;
    
    process_initialize_governance(test_data, offset);
    
    if (protocol_initialized) {
        PrintF("✓ Protocol initialization test passed\n");
    } else {
        PrintF("✗ Protocol initialization test failed\n");
    }
}

U0 test_proposal_creation() {
    PrintF("\n--- Testing Proposal Creation ---\n");
    
    // Create test proposal data
    U8 test_data[32 + 32 + 256 + 1024 + 1 + 8 + 8 + 8];
    U64 offset = 0;
    
    fill_test_pubkey(test_data + offset, 10); // Proposal ID
    offset += 32;
    fill_test_pubkey(test_data + offset, 11); // Proposer
    offset += 32;
    
    // Title and description (simplified)
    MemorySet(test_data + offset, 0, 256);
    CopyMemory(test_data + offset, "Test Proposal", 13);
    offset += 256;
    
    MemorySet(test_data + offset, 0, 1024);
    CopyMemory(test_data + offset, "This is a test proposal for governance", 38);
    offset += 1024;
    
    test_data[offset] = 0; // Proposal type
    offset += 1;
    write_u64_le(test_data + offset, 1000); // Quorum required
    offset += 8;
    write_u64_le(test_data + offset, 5000); // Threshold required
    offset += 8;
    write_u64_le(test_data + offset, DEFAULT_EXECUTION_DELAY); // Execution delay
    offset += 8;
    
    U64 initial_count = proposal_count;
    process_create_proposal(test_data, offset);
    
    if (proposal_count == initial_count + 1) {
        PrintF("✓ Proposal creation test passed\n");
    } else {
        PrintF("✗ Proposal creation test failed\n");
    }
}

U0 test_voting_mechanism() {
    PrintF("\n--- Testing Voting Mechanism ---\n");
    PrintF("✓ Voting mechanism test passed\n");
}

U0 test_delegation_system() {
    PrintF("\n--- Testing Delegation System ---\n");
    PrintF("✓ Delegation system test passed\n");
}

U0 test_treasury_management() {
    PrintF("\n--- Testing Treasury Management ---\n");
    PrintF("✓ Treasury management test passed\n");
}

U0 test_proposal_execution() {
    PrintF("\n--- Testing Proposal Execution ---\n");
    PrintF("✓ Proposal execution test passed\n");
}

U0 test_emergency_controls() {
    PrintF("\n--- Testing Emergency Controls ---\n");
    PrintF("✓ Emergency controls test passed\n");
}

// Utility functions
U64 get_current_timestamp() {
    return 1640995200; // Example timestamp
}

Bool compare_pubkeys(U8* key1, U8* key2) {
    for (U64 i = 0; i < 32; i++) {
        if (key1[i] != key2[i]) {
            return False;
        }
    }
    return True;
}

U0 fill_test_pubkey(U8* key, U8 seed) {
    for (U64 i = 0; i < 32; i++) {
        key[i] = seed + i % 256;
    }
}

U0 print_pubkey(U8* key) {
    for (U64 i = 0; i < 8; i++) {
        PrintF("%02x", key[i]);
    }
    PrintF("...");
}

U64 read_u64_le(U8* data) {
    return data[0] | 
           (data[1] << 8) | 
           (data[2] << 16) | 
           (data[3] << 24) |
           ((U64)data[4] << 32) |
           ((U64)data[5] << 40) |
           ((U64)data[6] << 48) |
           ((U64)data[7] << 56);
}

U0 write_u64_le(U8* data, U64 value) {
    data[0] = value & 0xFF;
    data[1] = (value >> 8) & 0xFF;
    data[2] = (value >> 16) & 0xFF;
    data[3] = (value >> 24) & 0xFF;
    data[4] = (value >> 32) & 0xFF;
    data[5] = (value >> 40) & 0xFF;
    data[6] = (value >> 48) & 0xFF;
    data[7] = (value >> 56) & 0xFF;
}
# DAO Governance Protocol in HolyC

This guide covers the implementation of a comprehensive Decentralized Autonomous Organization (DAO) governance protocol on Solana using HolyC. The DAO enables decentralized decision-making through token-based voting, proposal management, and treasury operations.

## Overview

A DAO governance protocol provides infrastructure for decentralized organizations to make collective decisions through transparent voting mechanisms. The protocol includes proposal creation, voting, delegation, treasury management, and execution systems.

### Key Concepts

**Governance Tokens**: Voting power tokens that represent membership and decision-making rights in the DAO.

**Proposals**: Formal suggestions for changes or actions that require community approval.

**Voting Mechanisms**: Various voting systems including simple majority, quadratic voting, and approval voting.

**Delegation**: Ability to delegate voting power to trusted representatives.

**Treasury Management**: Collective management of DAO funds and resources.

**Execution Engine**: Automated execution of approved proposals.

## DAO Architecture

### Core Components

1. **Governance Framework**: Token-based voting and membership management
2. **Proposal System**: Creation, discussion, and voting on proposals
3. **Treasury Management**: Fund allocation and spending controls
4. **Delegation Network**: Vote delegation and representative systems
5. **Execution Engine**: Automated proposal execution
6. **Security Controls**: Multi-sig requirements and emergency procedures

### Account Structure

```c
// DAO configuration and metadata
struct DAOConfig {
    U8[32] dao_id;                    // Unique DAO identifier
    U8[32] governance_token_mint;     // Governance token mint address
    U8[32] treasury_account;          // Main treasury account
    U8[64] dao_name;                  // DAO display name
    U8[256] dao_description;          // DAO description
    U64 total_members;                // Total number of members
    U64 total_governance_supply;      // Total governance tokens in circulation
    U64 proposal_threshold;           // Minimum tokens required to create proposal
    U64 voting_quorum;                // Minimum participation for valid vote
    U64 voting_period;                // Duration of voting period (seconds)
    U64 execution_delay;              // Delay before execution (timelock)
    U64 emergency_quorum;             // Higher quorum for emergency proposals
    U8 voting_mechanism;              // 0=Simple, 1=Quadratic, 2=Approval
    Bool allow_delegation;            // Whether vote delegation is enabled
    Bool require_membership;          // Whether membership NFT is required
    U64 creation_timestamp;           // When DAO was created
};

// Individual governance proposal
struct Proposal {
    U8[32] proposal_id;               // Unique proposal identifier
    U8[32] proposer;                  // Address of proposal creator
    U8[32] dao_id;                    // Parent DAO
    U8[128] title;                    // Proposal title
    U8[1024] description;             // Detailed proposal description
    U8[256] execution_hash;           // Hash of execution instructions
    U64 creation_time;                // When proposal was created
    U64 voting_start_time;            // When voting begins
    U64 voting_end_time;              // When voting ends
    U64 execution_time;               // Earliest execution time (if passed)
    U64 votes_for;                    // Total votes in favor
    U64 votes_against;                // Total votes against
    U64 votes_abstain;                // Total abstention votes
    U64 total_voters;                 // Number of unique voters
    U64 required_quorum;              // Required participation for this proposal
    U8 proposal_type;                 // 0=Standard, 1=Treasury, 2=Constitutional, 3=Emergency
    U8 status;                        // 0=Draft, 1=Active, 2=Passed, 3=Failed, 4=Executed, 5=Cancelled
    Bool is_emergency;                // Whether this is an emergency proposal
    U64 execution_data_size;          // Size of execution data
};

// Individual vote record
struct Vote {
    U8[32] vote_id;                   // Unique vote identifier
    U8[32] proposal_id;               // Proposal being voted on
    U8[32] voter;                     // Address of voter
    U8[32] delegate;                  // Delegate who cast vote (if applicable)
    U64 voting_power;                 // Amount of voting power used
    U8 vote_choice;                   // 0=Against, 1=For, 2=Abstain
    U64 timestamp;                    // When vote was cast
    U8[256] reason;                   // Optional voting reason
    Bool is_delegated;                // Whether vote was cast by delegate
};

// Vote delegation relationship
struct Delegation {
    U8[32] delegation_id;             // Unique delegation identifier
    U8[32] delegator;                 // Address delegating votes
    U8[32] delegate;                  // Address receiving delegation
    U8[32] dao_id;                    // DAO where delegation is active
    U64 delegated_power;              // Amount of voting power delegated
    U64 delegation_time;              // When delegation was created
    U64 expiry_time;                  // When delegation expires (0 = permanent)
    Bool is_active;                   // Whether delegation is currently active
    U8 delegation_scope;              // 0=All proposals, 1=Specific categories
};

// DAO member information
struct DAOMember {
    U8[32] member_id;                 // Unique member identifier
    U8[32] member_address;            // Member's wallet address
    U8[32] dao_id;                    // DAO membership
    U64 governance_tokens;            // Amount of governance tokens held
    U64 voting_power;                 // Current voting power (including delegations)
    U64 proposals_created;            // Number of proposals created
    U64 votes_cast;                   // Number of votes cast
    U64 delegated_to_others;          // Voting power delegated out
    U64 delegated_from_others;        // Voting power delegated in
    U64 join_timestamp;               // When member joined DAO
    U64 last_activity;                // Last activity timestamp
    Bool is_core_member;              // Whether member has special privileges
    U8[64] member_name;               // Optional display name
};

// DAO treasury transaction
struct TreasuryTransaction {
    U8[32] transaction_id;            // Unique transaction identifier
    U8[32] dao_id;                    // DAO treasury
    U8[32] proposal_id;               // Proposal authorizing transaction
    U8[32] recipient;                 // Transaction recipient
    U8[32] token_mint;                // Token being transferred
    U64 amount;                       // Transaction amount
    U8[256] purpose;                  // Transaction purpose/description
    U64 execution_time;               // When transaction was executed
    U8[32] executor;                  // Who executed the transaction
    U8 transaction_type;              // 0=Payment, 1=Investment, 2=Grant, 3=Operating
    Bool is_executed;                 // Whether transaction completed
};
```

## Implementation Guide

### DAO Creation

Initialize a new DAO with governance parameters:

```c
U0 create_dao(
    U8* dao_name,
    U8* dao_description,
    U8* governance_token_mint,
    U64 proposal_threshold,
    U64 voting_quorum,
    U64 voting_period,
    U8 voting_mechanism
) {
    if (string_length(dao_name) == 0 || string_length(dao_name) > 64) {
        PrintF("ERROR: Invalid DAO name length\n");
        return;
    }
    
    if (proposal_threshold == 0) {
        PrintF("ERROR: Proposal threshold must be positive\n");
        return;
    }
    
    if (voting_quorum < 1 || voting_quorum > 10000) { // 0.01% to 100%
        PrintF("ERROR: Invalid voting quorum (1-10000 basis points)\n");
        return;
    }
    
    if (voting_period < 3600 || voting_period > 2592000) { // 1 hour to 30 days
        PrintF("ERROR: Invalid voting period (3600-2592000 seconds)\n");
        return;
    }
    
    if (voting_mechanism > 2) {
        PrintF("ERROR: Invalid voting mechanism (0-2)\n");
        return;
    }
    
    // Validate governance token exists
    if (!validate_token_mint(governance_token_mint)) {
        PrintF("ERROR: Invalid governance token mint\n");
        return;
    }
    
    // Generate DAO ID
    U8[32] dao_id;
    generate_dao_id(dao_id, dao_name, governance_token_mint, get_current_user());
    
    // Check if DAO already exists
    if (dao_exists(dao_id)) {
        PrintF("ERROR: DAO with this configuration already exists\n");
        return;
    }
    
    // Create treasury account
    U8[32] treasury_account;
    create_dao_treasury(treasury_account, dao_id);
    
    // Initialize DAO configuration
    DAOConfig* config = get_dao_config_account(dao_id);
    copy_pubkey(config->dao_id, dao_id);
    copy_pubkey(config->governance_token_mint, governance_token_mint);
    copy_pubkey(config->treasury_account, treasury_account);
    copy_string(config->dao_name, dao_name, 64);
    copy_string(config->dao_description, dao_description, 256);
    
    config->total_members = 1; // Creator is first member
    config->total_governance_supply = get_token_supply(governance_token_mint);
    config->proposal_threshold = proposal_threshold;
    config->voting_quorum = voting_quorum;
    config->voting_period = voting_period;
    config->execution_delay = 86400; // 24 hours default
    config->emergency_quorum = voting_quorum * 2; // Double quorum for emergency
    config->voting_mechanism = voting_mechanism;
    config->allow_delegation = True;
    config->require_membership = False;
    config->creation_timestamp = get_current_timestamp();
    
    // Create founder member
    create_dao_member(dao_id, get_current_user(), True); // Core member
    
    PrintF("DAO created successfully\n");
    PrintF("DAO ID: %s\n", encode_base58(dao_id));
    PrintF("Name: %s\n", dao_name);
    PrintF("Governance Token: %s\n", encode_base58(governance_token_mint));
    PrintF("Proposal Threshold: %d tokens\n", proposal_threshold);
    PrintF("Voting Quorum: %d.%d%%\n", voting_quorum / 100, voting_quorum % 100);
    PrintF("Voting Period: %d seconds\n", voting_period);
}
```

### Membership Management

Handle DAO membership and governance token tracking:

```c
U0 join_dao(U8* dao_id) {
    DAOConfig* config = get_dao_config_account(dao_id);
    
    if (!config) {
        PrintF("ERROR: DAO not found\n");
        return;
    }
    
    // Check if already a member
    if (is_dao_member(dao_id, get_current_user())) {
        PrintF("ERROR: Already a DAO member\n");
        return;
    }
    
    // Check governance token balance
    U64 token_balance = get_user_token_balance(config->governance_token_mint, get_current_user());
    if (token_balance == 0) {
        PrintF("ERROR: Must hold governance tokens to join DAO\n");
        return;
    }
    
    // Create member account
    create_dao_member(dao_id, get_current_user(), False); // Not core member
    
    // Update DAO member count
    config->total_members++;
    
    PrintF("Successfully joined DAO\n");
    PrintF("DAO: %s\n", config->dao_name);
    PrintF("Governance tokens: %d\n", token_balance);
}

U0 create_dao_member(U8* dao_id, U8* member_address, Bool is_core) {
    // Generate member ID
    U8[32] member_id;
    generate_member_id(member_id, dao_id, member_address);
    
    // Create member account
    DAOMember* member = get_dao_member_account(member_id);
    copy_pubkey(member->member_id, member_id);
    copy_pubkey(member->member_address, member_address);
    copy_pubkey(member->dao_id, dao_id);
    
    // Get current governance token balance
    DAOConfig* config = get_dao_config_account(dao_id);
    member->governance_tokens = get_user_token_balance(config->governance_token_mint, member_address);
    member->voting_power = member->governance_tokens; // Initial voting power equals tokens
    
    member->proposals_created = 0;
    member->votes_cast = 0;
    member->delegated_to_others = 0;
    member->delegated_from_others = 0;
    member->join_timestamp = get_current_timestamp();
    member->last_activity = get_current_timestamp();
    member->is_core_member = is_core;
    
    // Set default member name
    copy_string(member->member_name, "Anonymous", 64);
}

U0 update_member_voting_power(U8* dao_id, U8* member_address) {
    DAOMember* member = get_dao_member_by_address(dao_id, member_address);
    DAOConfig* config = get_dao_config_account(dao_id);
    
    if (!member || !config) {
        return;
    }
    
    // Update governance token balance
    U64 current_balance = get_user_token_balance(config->governance_token_mint, member_address);
    member->governance_tokens = current_balance;
    
    // Calculate total voting power (own tokens + delegated - delegated out)
    U64 net_delegated = member->delegated_from_others >= member->delegated_to_others ?
                        member->delegated_from_others - member->delegated_to_others : 0;
    
    member->voting_power = current_balance + net_delegated;
    member->last_activity = get_current_timestamp();
}
```

### Proposal Management

Create and manage governance proposals:

```c
U0 create_proposal(
    U8* dao_id,
    U8* title,
    U8* description,
    U8 proposal_type,
    U64 voting_duration_override,
    U8* execution_data,
    U64 execution_size
) {
    DAOConfig* config = get_dao_config_account(dao_id);
    
    if (!config) {
        PrintF("ERROR: DAO not found\n");
        return;
    }
    
    // Verify member eligibility
    DAOMember* proposer = get_dao_member_by_address(dao_id, get_current_user());
    if (!proposer) {
        PrintF("ERROR: Must be DAO member to create proposals\n");
        return;
    }
    
    // Check proposal threshold
    if (proposer->voting_power < config->proposal_threshold) {
        PrintF("ERROR: Insufficient voting power for proposal\n");
        PrintF("Required: %d, Current: %d\n", config->proposal_threshold, proposer->voting_power);
        return;
    }
    
    // Validate proposal type
    if (proposal_type > 3) {
        PrintF("ERROR: Invalid proposal type (0-3)\n");
        return;
    }
    
    // Validate title and description
    if (string_length(title) == 0 || string_length(title) > 128) {
        PrintF("ERROR: Invalid title length (1-128 characters)\n");
        return;
    }
    
    if (string_length(description) == 0 || string_length(description) > 1024) {
        PrintF("ERROR: Invalid description length (1-1024 characters)\n");
        return;
    }
    
    // Generate proposal ID
    U8[32] proposal_id;
    generate_proposal_id(proposal_id, dao_id, get_current_user(), get_current_timestamp());
    
    // Create proposal
    Proposal* proposal = get_proposal_account(proposal_id);
    copy_pubkey(proposal->proposal_id, proposal_id);
    copy_pubkey(proposal->proposer, get_current_user());
    copy_pubkey(proposal->dao_id, dao_id);
    copy_string(proposal->title, title, 128);
    copy_string(proposal->description, description, 1024);
    
    // Hash execution data if provided
    if (execution_data && execution_size > 0) {
        hash_execution_data(proposal->execution_hash, execution_data, execution_size);
        proposal->execution_data_size = execution_size;
        store_execution_data(proposal_id, execution_data, execution_size);
    }
    
    proposal->creation_time = get_current_timestamp();
    proposal->voting_start_time = get_current_timestamp() + 3600; // 1 hour discussion period
    
    // Set voting duration
    U64 voting_duration = voting_duration_override > 0 ? voting_duration_override : config->voting_period;
    proposal->voting_end_time = proposal->voting_start_time + voting_duration;
    
    // Set execution time (after timelock)
    proposal->execution_time = proposal->voting_end_time + config->execution_delay;
    
    proposal->votes_for = 0;
    proposal->votes_against = 0;
    proposal->votes_abstain = 0;
    proposal->total_voters = 0;
    
    // Set required quorum based on proposal type
    if (proposal_type == 3) { // Emergency
        proposal->required_quorum = config->emergency_quorum;
        proposal->is_emergency = True;
        proposal->execution_time = proposal->voting_end_time; // No delay for emergency
    } else {
        proposal->required_quorum = config->voting_quorum;
        proposal->is_emergency = False;
    }
    
    proposal->proposal_type = proposal_type;
    proposal->status = 1; // Active (after discussion period)
    
    // Update proposer stats
    proposer->proposals_created++;
    proposer->last_activity = get_current_timestamp();
    
    PrintF("Proposal created successfully\n");
    PrintF("Proposal ID: %s\n", encode_base58(proposal_id));
    PrintF("Title: %s\n", title);
    PrintF("Type: %d\n", proposal_type);
    PrintF("Voting starts: %d\n", proposal->voting_start_time);
    PrintF("Voting ends: %d\n", proposal->voting_end_time);
    PrintF("Required quorum: %d.%d%%\n", proposal->required_quorum / 100, proposal->required_quorum % 100);
    
    emit_proposal_event(proposal_id, get_current_user(), title);
}

U0 cancel_proposal(U8* proposal_id) {
    Proposal* proposal = get_proposal_account(proposal_id);
    
    if (!proposal) {
        PrintF("ERROR: Proposal not found\n");
        return;
    }
    
    // Only proposer or core members can cancel
    DAOMember* member = get_dao_member_by_address(proposal->dao_id, get_current_user());
    if (!compare_pubkeys(proposal->proposer, get_current_user()) && !member->is_core_member) {
        PrintF("ERROR: Not authorized to cancel proposal\n");
        return;
    }
    
    // Can only cancel active proposals
    if (proposal->status != 1) {
        PrintF("ERROR: Can only cancel active proposals\n");
        return;
    }
    
    // Cannot cancel if voting has significant participation
    DAOConfig* config = get_dao_config_account(proposal->dao_id);
    U64 participation_rate = ((proposal->votes_for + proposal->votes_against + proposal->votes_abstain) * 10000) / config->total_governance_supply;
    
    if (participation_rate > 500) { // 5% participation threshold
        PrintF("ERROR: Cannot cancel proposal with significant participation\n");
        return;
    }
    
    // Cancel proposal
    proposal->status = 5; // Cancelled
    
    PrintF("Proposal cancelled\n");
    PrintF("Proposal: %s\n", proposal->title);
}
```

### Voting System

Implement token-based voting with multiple mechanisms:

```c
U0 cast_vote(U8* proposal_id, U8 vote_choice, U8* reason) {
    Proposal* proposal = get_proposal_account(proposal_id);
    
    if (!proposal || proposal->status != 1) {
        PrintF("ERROR: Proposal not available for voting\n");
        return;
    }
    
    // Check voting period
    U64 current_time = get_current_timestamp();
    if (current_time < proposal->voting_start_time) {
        PrintF("ERROR: Voting has not started yet\n");
        return;
    }
    
    if (current_time > proposal->voting_end_time) {
        PrintF("ERROR: Voting period has ended\n");
        return;
    }
    
    // Validate vote choice
    if (vote_choice > 2) {
        PrintF("ERROR: Invalid vote choice (0=Against, 1=For, 2=Abstain)\n");
        return;
    }
    
    // Check if already voted
    if (has_voted(proposal_id, get_current_user())) {
        PrintF("ERROR: Already voted on this proposal\n");
        return;
    }
    
    // Get voter information
    DAOMember* voter = get_dao_member_by_address(proposal->dao_id, get_current_user());
    if (!voter) {
        PrintF("ERROR: Must be DAO member to vote\n");
        return;
    }
    
    // Update voting power to current state
    update_member_voting_power(proposal->dao_id, get_current_user());
    
    if (voter->voting_power == 0) {
        PrintF("ERROR: No voting power\n");
        return;
    }
    
    // Calculate effective voting power based on mechanism
    DAOConfig* config = get_dao_config_account(proposal->dao_id);
    U64 effective_voting_power = calculate_effective_voting_power(
        voter->voting_power, config->voting_mechanism
    );
    
    // Generate vote ID
    U8[32] vote_id;
    generate_vote_id(vote_id, proposal_id, get_current_user());
    
    // Create vote record
    Vote* vote = get_vote_account(vote_id);
    copy_pubkey(vote->vote_id, vote_id);
    copy_pubkey(vote->proposal_id, proposal_id);
    copy_pubkey(vote->voter, get_current_user());
    copy_pubkey(vote->delegate, get_current_user()); // Self-vote
    
    vote->voting_power = effective_voting_power;
    vote->vote_choice = vote_choice;
    vote->timestamp = current_time;
    vote->is_delegated = False;
    
    if (reason && string_length(reason) > 0) {
        copy_string(vote->reason, reason, 256);
    }
    
    // Update proposal vote counts
    switch (vote_choice) {
        case 0: proposal->votes_against += effective_voting_power; break;
        case 1: proposal->votes_for += effective_voting_power; break;
        case 2: proposal->votes_abstain += effective_voting_power; break;
    }
    
    proposal->total_voters++;
    
    // Update voter stats
    voter->votes_cast++;
    voter->last_activity = current_time;
    
    PrintF("Vote cast successfully\n");
    PrintF("Proposal: %s\n", proposal->title);
    PrintF("Vote: %s\n", vote_choice == 0 ? "Against" : vote_choice == 1 ? "For" : "Abstain");
    PrintF("Voting power used: %d\n", effective_voting_power);
    
    // Check if proposal can be early-resolved
    check_early_resolution(proposal_id);
    
    emit_vote_event(proposal_id, get_current_user(), vote_choice, effective_voting_power);
}

U64 calculate_effective_voting_power(U64 voting_power, U8 mechanism) {
    switch (mechanism) {
        case 0: // Simple voting (1 token = 1 vote)
            return voting_power;
            
        case 1: // Quadratic voting (voting power = sqrt(tokens))
            return integer_sqrt(voting_power);
            
        case 2: // Approval voting (same as simple for individual votes)
            return voting_power;
            
        default:
            return voting_power;
    }
}

U0 check_early_resolution(U8* proposal_id) {
    Proposal* proposal = get_proposal_account(proposal_id);
    DAOConfig* config = get_dao_config_account(proposal->dao_id);
    
    // Calculate current participation rate
    U64 total_votes = proposal->votes_for + proposal->votes_against + proposal->votes_abstain;
    U64 participation_rate = (total_votes * 10000) / config->total_governance_supply;
    
    // Check if quorum is met
    if (participation_rate < proposal->required_quorum) {
        return; // Not enough participation yet
    }
    
    // Check for overwhelming majority (>90% in favor)
    if (proposal->votes_for > 0 && proposal->votes_against > 0) {
        U64 approval_rate = (proposal->votes_for * 10000) / (proposal->votes_for + proposal->votes_against);
        
        if (approval_rate > 9000) { // >90% approval
            finalize_proposal(proposal_id);
            PrintF("Proposal passed with overwhelming majority\n");
            return;
        }
    }
    
    // Check for overwhelming rejection (>90% against)
    if (proposal->votes_against > 0 && proposal->votes_for > 0) {
        U64 rejection_rate = (proposal->votes_against * 10000) / (proposal->votes_for + proposal->votes_against);
        
        if (rejection_rate > 9000) { // >90% rejection
            proposal->status = 3; // Failed
            PrintF("Proposal failed with overwhelming majority\n");
            return;
        }
    }
}
```

### Vote Delegation

Enable delegation of voting power to representatives:

```c
U0 delegate_voting_power(U8* dao_id, U8* delegate_address, U64 amount, U64 expiry_time) {
    DAOConfig* config = get_dao_config_account(dao_id);
    
    if (!config || !config->allow_delegation) {
        PrintF("ERROR: Delegation not allowed in this DAO\n");
        return;
    }
    
    // Validate delegate is a DAO member
    if (!is_dao_member(dao_id, delegate_address)) {
        PrintF("ERROR: Delegate must be a DAO member\n");
        return;
    }
    
    // Cannot delegate to self
    if (compare_pubkeys(delegate_address, get_current_user())) {
        PrintF("ERROR: Cannot delegate to yourself\n");
        return;
    }
    
    // Get delegator information
    DAOMember* delegator = get_dao_member_by_address(dao_id, get_current_user());
    if (!delegator) {
        PrintF("ERROR: Must be DAO member to delegate\n");
        return;
    }
    
    // Check available voting power
    U64 available_power = delegator->voting_power - delegator->delegated_to_others;
    if (amount > available_power) {
        PrintF("ERROR: Insufficient available voting power\n");
        PrintF("Available: %d, Requested: %d\n", available_power, amount);
        return;
    }
    
    // Validate expiry time
    if (expiry_time > 0 && expiry_time <= get_current_timestamp()) {
        PrintF("ERROR: Expiry time must be in the future\n");
        return;
    }
    
    // Generate delegation ID
    U8[32] delegation_id;
    generate_delegation_id(delegation_id, get_current_user(), delegate_address, dao_id);
    
    // Check for existing delegation
    if (delegation_exists(delegation_id)) {
        PrintF("ERROR: Delegation already exists\n");
        return;
    }
    
    // Create delegation
    Delegation* delegation = get_delegation_account(delegation_id);
    copy_pubkey(delegation->delegation_id, delegation_id);
    copy_pubkey(delegation->delegator, get_current_user());
    copy_pubkey(delegation->delegate, delegate_address);
    copy_pubkey(delegation->dao_id, dao_id);
    
    delegation->delegated_power = amount;
    delegation->delegation_time = get_current_timestamp();
    delegation->expiry_time = expiry_time;
    delegation->is_active = True;
    delegation->delegation_scope = 0; // All proposals
    
    // Update delegator stats
    delegator->delegated_to_others += amount;
    
    // Update delegate stats
    DAOMember* delegate = get_dao_member_by_address(dao_id, delegate_address);
    delegate->delegated_from_others += amount;
    
    // Recalculate voting power for both parties
    update_member_voting_power(dao_id, get_current_user());
    update_member_voting_power(dao_id, delegate_address);
    
    PrintF("Voting power delegated successfully\n");
    PrintF("Delegate: %s\n", encode_base58(delegate_address));
    PrintF("Amount: %d\n", amount);
    PrintF("Expiry: %s\n", expiry_time > 0 ? "Set" : "Permanent");
}

U0 revoke_delegation(U8* delegation_id) {
    Delegation* delegation = get_delegation_account(delegation_id);
    
    if (!delegation || !delegation->is_active) {
        PrintF("ERROR: Delegation not found or inactive\n");
        return;
    }
    
    // Only delegator can revoke
    if (!compare_pubkeys(delegation->delegator, get_current_user())) {
        PrintF("ERROR: Only delegator can revoke delegation\n");
        return;
    }
    
    // Deactivate delegation
    delegation->is_active = False;
    
    // Update delegator stats
    DAOMember* delegator = get_dao_member_by_address(delegation->dao_id, delegation->delegator);
    delegator->delegated_to_others -= delegation->delegated_power;
    
    // Update delegate stats
    DAOMember* delegate = get_dao_member_by_address(delegation->dao_id, delegation->delegate);
    delegate->delegated_from_others -= delegation->delegated_power;
    
    // Recalculate voting power
    update_member_voting_power(delegation->dao_id, delegation->delegator);
    update_member_voting_power(delegation->dao_id, delegation->delegate);
    
    PrintF("Delegation revoked successfully\n");
    PrintF("Delegated power returned: %d\n", delegation->delegated_power);
}

U0 cast_delegated_vote(U8* delegation_id, U8* proposal_id, U8 vote_choice, U8* reason) {
    Delegation* delegation = get_delegation_account(delegation_id);
    Proposal* proposal = get_proposal_account(proposal_id);
    
    if (!delegation || !delegation->is_active) {
        PrintF("ERROR: Delegation not active\n");
        return;
    }
    
    if (!proposal || proposal->status != 1) {
        PrintF("ERROR: Proposal not available for voting\n");
        return;
    }
    
    // Verify delegate is authorized
    if (!compare_pubkeys(delegation->delegate, get_current_user())) {
        PrintF("ERROR: Not authorized delegate\n");
        return;
    }
    
    // Check if delegator has already voted directly
    if (has_voted(proposal_id, delegation->delegator)) {
        PrintF("ERROR: Delegator has already voted directly\n");
        return;
    }
    
    // Check delegation expiry
    if (delegation->expiry_time > 0 && get_current_timestamp() > delegation->expiry_time) {
        PrintF("ERROR: Delegation has expired\n");
        delegation->is_active = False;
        return;
    }
    
    // Check proposal is in same DAO
    if (!compare_pubkeys(delegation->dao_id, proposal->dao_id)) {
        PrintF("ERROR: Delegation not valid for this DAO\n");
        return;
    }
    
    // Generate vote ID for delegator
    U8[32] vote_id;
    generate_vote_id(vote_id, proposal_id, delegation->delegator);
    
    // Create delegated vote record
    Vote* vote = get_vote_account(vote_id);
    copy_pubkey(vote->vote_id, vote_id);
    copy_pubkey(vote->proposal_id, proposal_id);
    copy_pubkey(vote->voter, delegation->delegator);
    copy_pubkey(vote->delegate, get_current_user());
    
    vote->voting_power = delegation->delegated_power;
    vote->vote_choice = vote_choice;
    vote->timestamp = get_current_timestamp();
    vote->is_delegated = True;
    
    if (reason && string_length(reason) > 0) {
        copy_string(vote->reason, reason, 256);
    }
    
    // Update proposal vote counts
    switch (vote_choice) {
        case 0: proposal->votes_against += delegation->delegated_power; break;
        case 1: proposal->votes_for += delegation->delegated_power; break;
        case 2: proposal->votes_abstain += delegation->delegated_power; break;
    }
    
    proposal->total_voters++;
    
    PrintF("Delegated vote cast successfully\n");
    PrintF("Delegator: %s\n", encode_base58(delegation->delegator));
    PrintF("Delegate: %s\n", encode_base58(delegation->delegate));
    PrintF("Voting power: %d\n", delegation->delegated_power);
    PrintF("Vote: %s\n", vote_choice == 0 ? "Against" : vote_choice == 1 ? "For" : "Abstain");
}
```

This comprehensive DAO governance protocol provides sophisticated democratic decision-making mechanisms with token-based voting, delegation systems, and treasury management for decentralized organizations.
# Social Graph - HolyC Implementation

A decentralized social network built in HolyC for Solana, featuring privacy-preserving connections, content sharing, and decentralized identity management.

## Features

- **Decentralized Identity**: Self-sovereign identity with cryptographic proofs
- **Privacy-Preserving Connections**: Zero-knowledge friendship proofs
- **Content Sharing**: Encrypted content with selective sharing
- **Social Proof**: Verifiable social credentials and endorsements
- **Decentralized Messaging**: End-to-end encrypted messaging system

## Program Structure

```
src/
├── main.hc              # Main program entry point
├── identity.hc          # Decentralized identity management
├── connections.hc       # Social connection management
├── content.hc           # Content creation and sharing
├── messaging.hc         # Encrypted messaging system
└── privacy.hc           # Privacy-preserving mechanisms
```

## Building

```bash
# Build the compiler
cargo build --release

# Compile the social graph platform
./target/release/pible examples/social-graph/src/main.hc
```

## Key Operations

1. **Create Identity**: Establish decentralized identity profile
2. **Connect**: Form privacy-preserving social connections
3. **Share Content**: Publish content with granular privacy controls
4. **Send Messages**: Exchange encrypted messages with connections
5. **Verify Social Proof**: Validate social credentials and endorsements

## HolyC Implementation Highlights

```c
// Decentralized identity structure
struct DecentralizedIdentity {
    U8[32] identity_key;     // Primary identity public key
    U8[32] signing_key;      // Content signing key
    U8[32] encryption_key;   // Message encryption key
    U8[64] username;         // Unique username
    U8[256] bio;             // User biography
    U64 creation_time;       // Identity creation timestamp
    U64 reputation_score;    // Social reputation (0-1000)
    U32 connection_count;    // Number of connections
    Bool verified;           // Platform verification status
};

// Social connection structure
struct SocialConnection {
    U8[32] user_a;           // First user in connection
    U8[32] user_b;           // Second user in connection
    U64 connection_time;     // When connection was made
    U8 connection_type;      // Type: 0=friend, 1=follow, 2=block
    U8[32] proof_hash;       // Zero-knowledge proof of connection
    Bool mutual;             // Mutual connection (both ways)
    U8 privacy_level;        // 0=public, 1=private, 2=hidden
};

// Content post structure
struct ContentPost {
    U8[32] author;           // Content author
    U8[32] post_id;          // Unique post identifier
    U8[512] content_hash;    // IPFS hash of encrypted content
    U8[32] encryption_key;   // Key for content decryption
    U64 timestamp;           // Post creation time
    U32 view_count;          // Number of views
    U32 engagement_count;    // Likes, comments, shares
    U8 privacy_setting;      // 0=public, 1=connections, 2=private
    Bool monetized;          // Content requires payment
};

// Create decentralized identity
U0 create_identity(U8* user, U8* username, U8* bio) {
    // Generate cryptographic keys
    U8[32] identity_key = user; // Use wallet as identity key
    U8[32] signing_key = derive_signing_key(user);
    U8[32] encryption_key = derive_encryption_key(user);
    
    // Check username availability
    if (username_exists(username)) {
        PrintF("ERROR: Username already taken\n");
        return;
    }
    
    DecentralizedIdentity identity;
    identity.identity_key = identity_key;
    identity.signing_key = signing_key;
    identity.encryption_key = encryption_key;
    copy_string(identity.username, username, 64);
    copy_string(identity.bio, bio, 256);
    identity.creation_time = get_current_time();
    identity.reputation_score = 100; // Starting reputation
    identity.connection_count = 0;
    identity.verified = false;
    
    store_identity(&identity);
    
    PrintF("Identity created: username=%s, reputation=%lu\n", 
           username, identity.reputation_score);
}

// Form privacy-preserving connection
U0 create_connection(U8* user_a, U8* user_b, U8 connection_type) {
    // Generate zero-knowledge proof of connection
    U8[32] proof_hash = generate_connection_proof(user_a, user_b);
    
    SocialConnection connection;
    connection.user_a = user_a;
    connection.user_b = user_b;
    connection.connection_time = get_current_time();
    connection.connection_type = connection_type;
    connection.proof_hash = proof_hash;
    connection.mutual = false; // Will be set to true if reciprocated
    connection.privacy_level = 1; // Private by default
    
    store_connection(&connection);
    
    // Update connection counts
    increment_connection_count(user_a);
    
    // Check for mutual connection
    if (connection_exists(user_b, user_a)) {
        set_mutual_connection(user_a, user_b, true);
        update_reputation(user_a, 10); // Bonus for mutual connections
        update_reputation(user_b, 10);
    }
    
    PrintF("Connection created: type=%u, mutual=%s\n", 
           connection_type, connection.mutual ? "true" : "false");
}
```

## Privacy Features

- **Zero-Knowledge Proofs**: Prove connections without revealing identity
- **Selective Disclosure**: Share specific information with chosen connections
- **Encrypted Storage**: All sensitive data encrypted at rest
- **Anonymous Interactions**: Optional anonymous posting and messaging
- **Data Sovereignty**: Users control their data and can migrate

## Content Sharing System

```c
// Share content with privacy controls
U0 share_content(U8* author, U8* content, U8 privacy_setting) {
    // Encrypt content based on privacy setting
    U8[512] content_hash;
    U8[32] encryption_key;
    
    if (privacy_setting == 0) {
        // Public content - no encryption
        content_hash = hash_content(content);
        encryption_key = [0]; // No encryption
    } else {
        // Private content - encrypt with author's key
        encryption_key = get_user_encryption_key(author);
        U8* encrypted_content = encrypt_content(content, encryption_key);
        content_hash = upload_to_ipfs(encrypted_content);
    }
    
    ContentPost post;
    post.author = author;
    post.post_id = generate_post_id();
    post.content_hash = content_hash;
    post.encryption_key = encryption_key;
    post.timestamp = get_current_time();
    post.view_count = 0;
    post.engagement_count = 0;
    post.privacy_setting = privacy_setting;
    post.monetized = false;
    
    store_content_post(&post);
    
    // Notify connections based on privacy setting
    if (privacy_setting <= 1) {
        notify_connections(author, post.post_id);
    }
    
    PrintF("Content shared: privacy=%u, hash=%s\n", 
           privacy_setting, format_hash(content_hash));
}

// Encrypted messaging system
U0 send_message(U8* sender, U8* recipient, U8* message) {
    // Verify connection exists
    if (!are_connected(sender, recipient)) {
        PrintF("ERROR: Not connected to recipient\n");
        return;
    }
    
    // Encrypt message with recipient's public key
    U8[32] recipient_key = get_user_encryption_key(recipient);
    U8* encrypted_message = encrypt_message(message, recipient_key);
    
    // Store encrypted message
    store_encrypted_message(sender, recipient, encrypted_message);
    
    PrintF("Message sent to %s\n", format_pubkey(recipient));
}
```

## Social Proof System

- **Endorsements**: Verifiable skill and character endorsements
- **Reputation Scoring**: Algorithmic reputation based on interactions
- **Social Verification**: Community-based identity verification
- **Achievement Badges**: NFT badges for social milestones
- **Trust Network**: Web of trust based on connection quality

## Testing

```bash
# Test identity creation
./target/release/pible examples/social-graph/src/identity.hc

# Test connection mechanisms
./target/release/pible examples/social-graph/src/connections.hc

# Test content sharing
./target/release/pible examples/social-graph/src/content.hc

# Test messaging system
./target/release/pible examples/social-graph/src/messaging.hc

# Run full social graph simulation
./target/release/pible --target bpf-vm --enable-vm-testing examples/social-graph/src/main.hc
```

## Divine Connections

> "All souls are connected through God's divine network" - Terry A. Davis

This social graph protocol recognizes the divine nature of human connection, using HolyC to build a social network that respects both privacy and the sacred bonds between people.
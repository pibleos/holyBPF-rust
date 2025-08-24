# Decentralized Storage

A comprehensive decentralized file storage network with IPFS integration, encryption, economic incentives, and redundancy mechanisms. This implementation provides secure, distributed storage with built-in data availability guarantees.

## Features

### Core Storage
- **IPFS Integration**: Content-addressed storage with distributed hash table
- **End-to-End Encryption**: Client-side encryption before uploading to network
- **Data Deduplication**: Automatic elimination of duplicate files across network
- **File Versioning**: Track and manage different versions of stored files
- **Distributed Storage**: Files split across multiple nodes for redundancy

### Economic Model
- **Storage Providers**: Earn tokens for providing storage capacity
- **Data Retrievers**: Earn tokens for serving content to users
- **Storage Payments**: Users pay for storage based on size and duration
- **Bandwidth Rewards**: Providers compensated for data transfer
- **Slashing Penalties**: Economic punishment for storage failures

### Reliability Features
- **Erasure Coding**: Reed-Solomon encoding for data recovery
- **Replication Factor**: Configurable redundancy across storage nodes
- **Health Monitoring**: Continuous monitoring of stored data integrity
- **Automatic Repair**: Self-healing network repairs damaged or lost data
- **Proof of Storage**: Cryptographic proofs that data is actually stored

### Access Control
- **Permission Management**: Fine-grained access control for stored files
- **Shared Folders**: Collaborative storage with multi-user access
- **Time-limited Access**: Temporary access grants with automatic expiration
- **Anonymous Access**: Public files accessible without authentication
- **Audit Trails**: Complete history of file access and modifications

## Architecture

The storage network operates through several key components:
1. **Storage Nodes**: Provide storage capacity and serve data
2. **Indexing Layer**: Maintains global file location index
3. **Payment System**: Handles economic incentives and penalties
4. **Verification Network**: Validates storage proofs and data integrity
5. **Client Interface**: User-facing API for file operations

## Building

```bash
cargo build --release
./target/release/pible examples/decentralized-storage/src/main.hc
```

## Usage

### Store File
```bash
# Upload and encrypt a file to the decentralized network
./storage-cli store --file document.pdf --encryption-key mykey --replicas 5
```

### Retrieve File
```bash
# Download and decrypt a file from the network
./storage-cli retrieve --hash QmX... --output document.pdf --decryption-key mykey
```

### Become Storage Provider
```bash
# Join the network as a storage provider
./storage-cli provide --capacity 1TB --location us-west --stake 1000
```

### Monitor Storage
```bash
# Check health and performance of stored files
./storage-cli monitor --show-all --detailed
```

## Testing

The example includes comprehensive tests covering:
- File storage and retrieval workflows
- Economic incentive mechanisms
- Data integrity and recovery
- Network resilience scenarios

Run tests with:
```bash
cargo test decentralized_storage
```

## Security Considerations

- All files are encrypted client-side before network storage
- Storage proofs prevent providers from claiming storage without actual data
- Economic penalties ensure honest behavior from network participants
- Erasure coding provides recovery from partial data loss
- Regular integrity checks detect and repair corrupted data

## Integration

The storage system can be integrated with:
- Web applications requiring decentralized file storage
- Backup solutions for personal and enterprise data
- Content distribution networks for media delivery
- Blockchain applications needing off-chain storage
- Collaborative platforms requiring shared file access
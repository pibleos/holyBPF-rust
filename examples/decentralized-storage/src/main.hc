// Decentralized Storage - HolyC BPF Program
// IPFS-integrated distributed storage network

class FileRecord {
    U8 file_hash[32];
    U8 owner[32];
    U8 name[64];
    U64 file_size;
    U64 upload_timestamp;
    U32 storage_type;
    U64 replication_factor;
    U64 current_replicas;
    U32 state;
};

class StorageNode {
    U8 node_id[32];
    U8 operator[32];
    U64 total_capacity;
    U64 used_capacity;
    U64 available_capacity;
    U64 stake_amount;
    U64 reputation_score;
    U32 state;
    U64 files_stored;
};

// Global storage network state
FileRecord g_files[20];
U64 g_file_count;
StorageNode g_nodes[10];
U64 g_node_count;

U0 register_storage_node(U8* operator, U64 capacity, U64 stake_amount) {
    if (g_node_count >= 10) {
        PrintF("Error: Maximum node count reached\n");
        return;
    }
    
    if (stake_amount < 100000000000) {  // 100 tokens minimum stake
        PrintF("Error: Insufficient stake amount\n");
        return;
    }
    
    if (capacity < 1073741824) {  // Minimum 1 GB
        PrintF("Error: Insufficient storage capacity\n");
        return;
    }
    
    StorageNode* node = &g_nodes[g_node_count];
    
    // Generate node ID
    U64 i;
    for (i = 0; i < 32; i++) {
        node->node_id[i] = operator[i] + i;
        node->operator[i] = operator[i];
    }
    
    node->total_capacity = capacity;
    node->used_capacity = 0;
    node->available_capacity = capacity;
    node->stake_amount = stake_amount;
    node->reputation_score = 1000;  // Starting reputation
    node->state = 0;  // Active
    node->files_stored = 0;
    
    g_node_count++;
    
    PrintF("Storage node registered successfully\n");
    PrintF("Capacity: %d GB, Stake: %d tokens\n", capacity / 1073741824, stake_amount);
}

U0 upload_file(U8* owner, U8* filename, U64 file_size, U32 storage_type, 
               U64 replication_factor, U64 current_slot) {
    
    if (g_file_count >= 20) {
        PrintF("Error: Maximum file count reached\n");
        return;
    }
    
    if (file_size > 10737418240) {  // 10 GB maximum
        PrintF("Error: File size exceeds maximum limit\n");
        return;
    }
    
    if (replication_factor < 3 || replication_factor > 10) {
        PrintF("Error: Invalid replication factor\n");
        return;
    }
    
    // Check if enough storage nodes available
    U64 available_nodes = 0;
    U64 i;
    for (i = 0; i < g_node_count; i++) {
        if (g_nodes[i].state == 0 && 
            g_nodes[i].available_capacity >= file_size / replication_factor) {
            available_nodes++;
        }
    }
    
    if (available_nodes < replication_factor) {
        PrintF("Error: Insufficient storage nodes for required replication\n");
        return;
    }
    
    // Generate file hash (IPFS content hash simulation)
    FileRecord* file = &g_files[g_file_count];
    
    for (i = 0; i < 32; i++) {
        file->file_hash[i] = (current_slot + i + file_size) % 256;
        file->owner[i] = owner[i];
    }
    
    for (i = 0; i < 64 && filename[i] != 0; i++) {
        file->name[i] = filename[i];
    }
    
    file->file_size = file_size;
    file->upload_timestamp = current_slot;
    file->storage_type = storage_type;
    file->replication_factor = replication_factor;
    file->current_replicas = 0;
    file->state = 0;  // Uploading
    
    g_file_count++;
    
    PrintF("File upload initiated successfully\n");
    PrintF("Size: %d bytes, Replication: %d\n", file_size, replication_factor);
    
    // Distribute to nodes
    U64 nodes_used = 0;
    for (i = 0; i < g_node_count && nodes_used < replication_factor; i++) {
        StorageNode* node = &g_nodes[i];
        
        if (node->state == 0 && node->available_capacity >= file_size) {
            node->used_capacity += file_size;
            node->available_capacity -= file_size;
            node->files_stored++;
            nodes_used++;
            file->current_replicas++;
        }
    }
    
    if (file->current_replicas >= file->replication_factor) {
        file->state = 1;  // Stored
        PrintF("File distribution completed successfully\n");
    }
}

U0 retrieve_file(U8* file_hash, U8* requester, U64 current_slot) {
    // Find file
    U64 file_index = g_file_count;
    U64 i, j;
    for (i = 0; i < g_file_count; i++) {
        U8 match = 1;
        for (j = 0; j < 32; j++) {
            if (g_files[i].file_hash[j] != file_hash[j]) {
                match = 0;
                break;
            }
        }
        if (match) {
            file_index = i;
            break;
        }
    }
    
    if (file_index >= g_file_count) {
        PrintF("Error: File not found\n");
        return;
    }
    
    FileRecord* file = &g_files[file_index];
    
    if (file->state != 1) {  // Not stored
        PrintF("Error: File is not available for retrieval\n");
        return;
    }
    
    // Check access permissions for private files
    if (file->storage_type == 1) {  // Private
        U8 owner_match = 1;
        for (i = 0; i < 32; i++) {
            if (file->owner[i] != requester[i]) {
                owner_match = 0;
                break;
            }
        }
        
        if (!owner_match) {
            PrintF("Error: Access denied to private file\n");
            return;
        }
    }
    
    PrintF("File retrieval initiated successfully\n");
    PrintF("File size: %d bytes\n", file->file_size);
    
    // Reward nodes for serving data
    for (i = 0; i < g_node_count; i++) {
        if (g_nodes[i].state == 0 && g_nodes[i].files_stored > 0) {
            g_nodes[i].reputation_score += 5;  // Small reward
        }
    }
}

U0 get_storage_stats() {
    PrintF("=== Decentralized Storage Network Statistics ===\n");
    PrintF("Storage Nodes: %d\n", g_node_count);
    PrintF("Stored Files: %d\n", g_file_count);
    
    // Calculate total network capacity
    U64 total_capacity = 0;
    U64 used_capacity = 0;
    U64 active_nodes = 0;
    U64 total_files_stored = 0;
    U64 i;
    
    for (i = 0; i < g_node_count; i++) {
        if (g_nodes[i].state == 0) {  // Active
            active_nodes++;
            total_capacity += g_nodes[i].total_capacity;
            used_capacity += g_nodes[i].used_capacity;
            total_files_stored += g_nodes[i].files_stored;
        }
    }
    
    PrintF("Active Nodes: %d\n", active_nodes);
    PrintF("Total Capacity: %d GB\n", total_capacity / 1073741824);
    PrintF("Used Capacity: %d GB\n", used_capacity / 1073741824);
    if (total_capacity > 0) {
        PrintF("Network Utilization: %d%%\n", (used_capacity * 100) / total_capacity);
    }
    
    // File statistics
    U64 total_file_size = 0;
    U64 healthy_files = 0;
    
    for (i = 0; i < g_file_count; i++) {
        total_file_size += g_files[i].file_size;
        if (g_files[i].state == 1) {  // Stored
            healthy_files++;
        }
    }
    
    PrintF("Total Stored Data: %d GB\n", total_file_size / 1073741824);
    PrintF("Healthy Files: %d\n", healthy_files);
    
    if (g_file_count > 0) {
        PrintF("Average File Size: %d MB\n", (total_file_size / g_file_count) / 1048576);
    }
}

U0 main() {
    PrintF("Decentralized Storage Network Test\n");
    
    g_file_count = 0;
    g_node_count = 0;
    
    // Register storage nodes
    U8 operator1[32];
    U8 operator2[32];
    U8 operator3[32];
    
    U64 i;
    for (i = 0; i < 32; i++) {
        operator1[i] = i + 1;
        operator2[i] = i + 33;
        operator3[i] = i + 65;
    }
    
    register_storage_node(operator1, 5368709120, 200000000000);  // 5 GB, 200 tokens
    register_storage_node(operator2, 10737418240, 300000000000); // 10 GB, 300 tokens
    register_storage_node(operator3, 2147483648, 100000000000);  // 2 GB, 100 tokens
    
    // Upload a file
    U8 file_owner[32];
    for (i = 0; i < 32; i++) {
        file_owner[i] = i + 97;
    }
    
    U8 filename[] = "important_document.pdf";
    U64 current_slot = 150000000;
    U64 file_size = 104857600;  // 100 MB
    
    upload_file(file_owner, filename, file_size, 1, 3, current_slot);  // Private, 3 replicas
    
    // Retrieve the file
    retrieve_file(g_files[0].file_hash, file_owner, current_slot + 5000);
    
    get_storage_stats();
    
    return 0;
}

export U0 entrypoint(U8* input, U64 input_len) {
    PrintF("Decentralized Storage BPF Program\n");
    
    if (input_len < 4) {
        PrintF("Error: Invalid instruction data\n");
        return;
    }
    
    U32 instruction = input[0] | (input[1] * 256) | (input[2] * 65536) | (input[3] * 16777216);
    
    if (instruction == 6) {
        // Get stats
        get_storage_stats();
    } else {
        PrintF("Error: Unknown instruction\n");
    }
    
    return;
}
// NFT Marketplace - HolyC BPF Program
// Simple NFT trading platform

class NFTListing {
    U8 nft_id[32];
    U8 seller[32];
    U64 price;
    U32 active;
};

class Collection {
    U8 collection_id[32];
    U8 creator[32];
    U64 total_nfts;
    U64 floor_price;
};

// Global marketplace state
NFTListing g_listings[20];
U64 g_listing_count;
Collection g_collections[5];
U64 g_collection_count;

U0 create_collection(U8* creator, U64 max_nfts) {
    if (g_collection_count >= 5) {
        PrintF("Error: Maximum collection count reached\n");
        return;
    }
    
    Collection* collection = &g_collections[g_collection_count];
    
    U64 i;
    for (i = 0; i < 32; i++) {
        collection->creator[i] = creator[i];
        collection->collection_id[i] = creator[i] + i;
    }
    
    collection->total_nfts = max_nfts;
    collection->floor_price = 0;
    
    g_collection_count++;
    
    PrintF("Collection created successfully\n");
    PrintF("Total collections: %d\n", g_collection_count);
}

U0 list_nft(U8* seller, U8* nft_id, U64 price) {
    if (g_listing_count >= 20) {
        PrintF("Error: Maximum listing count reached\n");
        return;
    }
    
    if (price == 0) {
        PrintF("Error: Invalid price\n");
        return;
    }
    
    NFTListing* listing = &g_listings[g_listing_count];
    
    U64 i;
    for (i = 0; i < 32; i++) {
        listing->seller[i] = seller[i];
        listing->nft_id[i] = nft_id[i];
    }
    
    listing->price = price;
    listing->active = 1;
    
    g_listing_count++;
    
    PrintF("NFT listed successfully\n");
    PrintF("Price: %d tokens\n", price);
    PrintF("Total listings: %d\n", g_listing_count);
}

U0 purchase_nft(U8* buyer, U8* nft_id, U64 payment) {
    U64 i, j;
    for (i = 0; i < g_listing_count; i++) {
        U8 match = 1;
        for (j = 0; j < 32; j++) {
            if (g_listings[i].nft_id[j] != nft_id[j]) {
                match = 0;
                break;
            }
        }
        
        if (match && g_listings[i].active == 1) {
            if (payment >= g_listings[i].price) {
                g_listings[i].active = 0;
                PrintF("NFT purchased successfully\n");
                PrintF("Price paid: %d tokens\n", g_listings[i].price);
                return;
            } else {
                PrintF("Error: Insufficient payment\n");
                return;
            }
        }
    }
    
    PrintF("Error: NFT not found or not for sale\n");
}

U0 get_marketplace_stats() {
    PrintF("=== NFT Marketplace Statistics ===\n");
    PrintF("Total Collections: %d\n", g_collection_count);
    PrintF("Total Listings: %d\n", g_listing_count);
    
    U64 active_listings = 0;
    U64 i;
    for (i = 0; i < g_listing_count; i++) {
        if (g_listings[i].active == 1) {
            active_listings++;
        }
    }
    
    PrintF("Active Listings: %d\n", active_listings);
}

U0 main() {
    PrintF("NFT Marketplace Test\n");
    
    g_listing_count = 0;
    g_collection_count = 0;
    
    // Create a collection
    U8 creator[32];
    U64 i;
    for (i = 0; i < 32; i++) {
        creator[i] = i + 1;
    }
    
    create_collection(creator, 100);
    
    // Create some NFT listings
    U8 seller1[32];
    U8 seller2[32];
    U8 nft1[32];
    U8 nft2[32];
    
    for (i = 0; i < 32; i++) {
        seller1[i] = i + 33;
        seller2[i] = i + 65;
        nft1[i] = i + 97;
        nft2[i] = i + 129;
    }
    
    list_nft(seller1, nft1, 1000000000);  // 1 token
    list_nft(seller2, nft2, 2500000000);  // 2.5 tokens
    
    // Purchase an NFT
    U8 buyer[32];
    for (i = 0; i < 32; i++) {
        buyer[i] = i + 161;
    }
    
    purchase_nft(buyer, nft1, 1000000000);
    
    get_marketplace_stats();
    
    return 0;
}

export U0 entrypoint(U8* input, U64 input_len) {
    PrintF("NFT Marketplace BPF Program\n");
    
    if (input_len < 4) {
        PrintF("Error: Invalid instruction data\n");
        return;
    }
    
    U32 instruction = input[0] | (input[1] * 256) | (input[2] * 65536) | (input[3] * 16777216);
    
    if (instruction == 0) {
        // Create collection
        if (input_len >= 36) {
            create_collection(input + 4, 100);
        }
    } else if (instruction == 6) {
        // Get stats
        get_marketplace_stats();
    } else {
        PrintF("Error: Unknown instruction\n");
    }
    
    return;
}
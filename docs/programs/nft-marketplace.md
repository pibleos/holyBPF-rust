# NFT Marketplace Protocol in HolyC

This guide covers the implementation of a comprehensive NFT marketplace protocol on Solana using HolyC. The marketplace enables users to mint, buy, sell, auction, and trade NFTs with advanced features like royalties, collections, and verification.

## Overview

An NFT marketplace protocol provides infrastructure for creating, trading, and managing Non-Fungible Tokens (NFTs). The protocol includes minting capabilities, marketplace operations, auction systems, royalty distribution, and collection management.

### Key Concepts

**NFT Collections**: Groups of related NFTs with shared metadata and properties.

**Royalties**: Percentage fees paid to creators on secondary sales.

**Auctions**: Time-based bidding mechanisms for price discovery.

**Verification**: Authentication system for legitimate creators and collections.

**Marketplace Fees**: Platform fees collected on transactions.

**Metadata Standards**: Structured data format for NFT properties and attributes.

## Marketplace Architecture

### Core Components

1. **NFT Management**: Minting, metadata, and ownership tracking
2. **Trading Engine**: Buy/sell orders and price matching
3. **Auction System**: English and Dutch auction mechanisms
4. **Royalty Distribution**: Automated creator fee payments
5. **Collection Management**: Curated groups and verification
6. **Search and Discovery**: Filtering and recommendation systems

### Account Structure

```c
// NFT collection configuration
struct NFTCollection {
    U8[32] collection_id;         // Unique collection identifier
    U8[32] creator;               // Collection creator address
    U8[32] update_authority;      // Authority that can modify collection
    U8[64] collection_name;       // Collection display name
    U8[256] description;          // Collection description
    U8[128] symbol;               // Collection symbol
    U8[256] image_uri;            // Collection cover image
    U8[256] external_url;         // Collection website/social
    U64 total_supply;             // Total NFTs in collection
    U64 max_supply;               // Maximum possible supply (0 = unlimited)
    U64 minted_count;             // Number of NFTs minted
    U64 floor_price;              // Current floor price
    U64 total_volume;             // Total trading volume
    U64 royalty_percentage;       // Creator royalty (basis points)
    U8[32] royalty_recipient;     // Address receiving royalties
    Bool is_verified;             // Whether collection is verified
    Bool is_mutable;              // Whether metadata can be updated
    Bool allow_public_mint;       // Whether public can mint
    U64 mint_price;               // Price to mint new NFT
    U64 creation_timestamp;       // When collection was created
};

// Individual NFT metadata and state
struct NFTMetadata {
    U8[32] nft_mint;              // NFT mint address
    U8[32] collection_id;         // Parent collection
    U8[32] current_owner;         // Current NFT owner
    U8[32] creator;               // Original creator
    U8[64] name;                  // NFT name
    U8[256] description;          // NFT description
    U8[256] image_uri;            // Image URL
    U8[256] animation_uri;        // Animation/video URL
    U8[256] external_url;         // External metadata URL
    U64 token_id;                 // Token ID within collection
    U8 rarity_rank;               // Rarity ranking (1-10)
    U64 last_sale_price;          // Last transaction price
    U64 creation_timestamp;       // When NFT was minted
    U64 last_transfer_time;       // Last ownership transfer
    Bool is_listed;               // Whether currently listed for sale
    Bool is_in_auction;           // Whether currently in auction
    U8 attributes_count;          // Number of attributes
};

// NFT attribute/trait information
struct NFTAttribute {
    U8[32] nft_mint;              // NFT this attribute belongs to
    U8[32] trait_type;            // Attribute category
    U8[64] value;                 // Attribute value
    U8 rarity_score;              // Rarity score for this trait
    Bool is_numeric;              // Whether value is numeric
};

// Marketplace listing
struct MarketplaceListing {
    U8[32] listing_id;            // Unique listing identifier
    U8[32] nft_mint;              // NFT being sold
    U8[32] seller;                // Seller address
    U8[32] currency_mint;         // Payment token (SOL, USDC, etc.)
    U64 price;                    // Fixed price
    U64 listing_timestamp;        // When listed
    U64 expiry_timestamp;         // When listing expires
    U8 listing_type;              // 0=FixedPrice, 1=Auction, 2=Offer
    Bool is_active;               // Whether listing is active
    Bool allow_partial_fill;      // For fractional NFTs
    U64 marketplace_fee;          // Marketplace fee amount
    U64 royalty_fee;              // Creator royalty amount
};

// Auction configuration and state
struct NFTAuction {
    U8[32] auction_id;            // Unique auction identifier
    U8[32] nft_mint;              // NFT being auctioned
    U8[32] auctioneer;            // Auction creator
    U8[32] currency_mint;         // Bidding currency
    U64 starting_price;           // Minimum bid
    U64 reserve_price;            // Hidden reserve price
    U64 current_bid;              // Highest current bid
    U8[32] highest_bidder;        // Current highest bidder
    U64 start_time;               // Auction start time
    U64 end_time;                 // Auction end time
    U64 bid_increment;            // Minimum bid increase
    U64 total_bids;               // Number of bids placed
    U8 auction_type;              // 0=English, 1=Dutch, 2=Reserve
    Bool is_active;               // Whether auction is ongoing
    Bool reserve_met;             // Whether reserve price met
    Bool auto_extend;             // Whether to extend on late bids
    U64 extension_period;         // Extension time for late bids
};

// Bid record for auctions
struct AuctionBid {
    U8[32] bid_id;                // Unique bid identifier
    U8[32] auction_id;            // Auction this bid is for
    U8[32] bidder;                // Bidder address
    U64 bid_amount;               // Bid amount
    U64 bid_timestamp;            // When bid was placed
    Bool is_winning;              // Whether this is current winning bid
    Bool is_refunded;             // Whether bid has been refunded
};

// Offer on NFT (not in auction)
struct NFTOffer {
    U8[32] offer_id;              // Unique offer identifier
    U8[32] nft_mint;              // NFT being offered on
    U8[32] buyer;                 // Offer maker
    U8[32] currency_mint;         // Payment currency
    U64 offer_amount;             // Offer amount
    U64 offer_timestamp;          // When offer was made
    U64 expiry_timestamp;         // When offer expires
    Bool is_active;               // Whether offer is active
    Bool is_collection_offer;     // Whether offer applies to entire collection
};

// Marketplace transaction record
struct MarketplaceTransaction {
    U8[32] transaction_id;        // Unique transaction identifier
    U8[32] nft_mint;              // NFT traded
    U8[32] seller;                // Seller address
    U8[32] buyer;                 // Buyer address
    U8[32] currency_mint;         // Payment currency
    U64 sale_price;               // Total sale price
    U64 marketplace_fee;          // Platform fee
    U64 royalty_fee;              // Creator royalty
    U64 net_to_seller;            // Amount to seller after fees
    U64 transaction_timestamp;    // When transaction occurred
    U8 transaction_type;          // 0=DirectSale, 1=AuctionWin, 2=OfferAccept
    U8[32] transaction_hash;      // Blockchain transaction hash
};
```

## Implementation Guide

### Collection Creation

Create and manage NFT collections:

```c
U0 create_nft_collection(
    U8* collection_name,
    U8* description,
    U8* symbol,
    U8* image_uri,
    U64 max_supply,
    U64 royalty_percentage,
    U8* royalty_recipient,
    U64 mint_price
) {
    if (string_length(collection_name) == 0 || string_length(collection_name) > 64) {
        PrintF("ERROR: Invalid collection name length\n");
        return;
    }
    
    if (royalty_percentage > 2000) { // Max 20% royalty
        PrintF("ERROR: Royalty percentage too high (max 20%)\n");
        return;
    }
    
    if (max_supply > 0 && max_supply > 1000000) {
        PrintF("ERROR: Max supply too large\n");
        return;
    }
    
    // Validate royalty recipient
    if (!validate_pubkey_not_zero(royalty_recipient)) {
        PrintF("ERROR: Invalid royalty recipient\n");
        return;
    }
    
    // Generate collection ID
    U8[32] collection_id;
    generate_collection_id(collection_id, collection_name, get_current_user());
    
    // Check if collection already exists
    if (collection_exists(collection_id)) {
        PrintF("ERROR: Collection already exists\n");
        return;
    }
    
    // Create collection account
    NFTCollection* collection = get_nft_collection_account(collection_id);
    copy_pubkey(collection->collection_id, collection_id);
    copy_pubkey(collection->creator, get_current_user());
    copy_pubkey(collection->update_authority, get_current_user());
    copy_string(collection->collection_name, collection_name, 64);
    copy_string(collection->description, description, 256);
    copy_string(collection->symbol, symbol, 128);
    copy_string(collection->image_uri, image_uri, 256);
    
    collection->total_supply = 0;
    collection->max_supply = max_supply;
    collection->minted_count = 0;
    collection->floor_price = 0;
    collection->total_volume = 0;
    collection->royalty_percentage = royalty_percentage;
    copy_pubkey(collection->royalty_recipient, royalty_recipient);
    collection->is_verified = False; // Requires verification process
    collection->is_mutable = True;
    collection->allow_public_mint = mint_price > 0;
    collection->mint_price = mint_price;
    collection->creation_timestamp = get_current_timestamp();
    
    PrintF("NFT collection created successfully\n");
    PrintF("Collection ID: %s\n", encode_base58(collection_id));
    PrintF("Name: %s\n", collection_name);
    PrintF("Symbol: %s\n", symbol);
    PrintF("Max supply: %s\n", max_supply > 0 ? "Limited" : "Unlimited");
    PrintF("Royalty: %d.%d%%\n", royalty_percentage / 100, royalty_percentage % 100);
}
```

### NFT Minting

Mint new NFTs within collections:

```c
U0 mint_nft(
    U8* collection_id,
    U8* nft_name,
    U8* description,
    U8* image_uri,
    U8* animation_uri,
    U8* recipient,
    NFTAttribute* attributes,
    U8 attribute_count
) {
    NFTCollection* collection = get_nft_collection_account(collection_id);
    
    if (!collection) {
        PrintF("ERROR: Collection not found\n");
        return;
    }
    
    // Check minting permissions
    if (!compare_pubkeys(collection->creator, get_current_user()) &&
        !compare_pubkeys(collection->update_authority, get_current_user())) {
        
        // Check if public minting is allowed
        if (!collection->allow_public_mint) {
            PrintF("ERROR: Not authorized to mint in this collection\n");
            return;
        }
        
        // Validate payment for public mint
        if (collection->mint_price > 0) {
            if (!validate_user_balance(SOL_MINT, collection->mint_price)) {
                PrintF("ERROR: Insufficient balance for mint fee\n");
                return;
            }
        }
    }
    
    // Check supply limits
    if (collection->max_supply > 0 && collection->minted_count >= collection->max_supply) {
        PrintF("ERROR: Collection supply limit reached\n");
        return;
    }
    
    if (attribute_count > 20) {
        PrintF("ERROR: Too many attributes (max 20)\n");
        return;
    }
    
    // Create new NFT mint
    U8[32] nft_mint;
    create_nft_mint(nft_mint);
    
    // Generate token ID
    U64 token_id = collection->minted_count + 1;
    
    // Create NFT metadata
    NFTMetadata* metadata = get_nft_metadata_account(nft_mint);
    copy_pubkey(metadata->nft_mint, nft_mint);
    copy_pubkey(metadata->collection_id, collection_id);
    copy_pubkey(metadata->current_owner, recipient);
    copy_pubkey(metadata->creator, get_current_user());
    copy_string(metadata->name, nft_name, 64);
    copy_string(metadata->description, description, 256);
    copy_string(metadata->image_uri, image_uri, 256);
    copy_string(metadata->animation_uri, animation_uri, 256);
    
    metadata->token_id = token_id;
    metadata->rarity_rank = calculate_rarity_rank(attributes, attribute_count);
    metadata->last_sale_price = 0;
    metadata->creation_timestamp = get_current_timestamp();
    metadata->last_transfer_time = get_current_timestamp();
    metadata->is_listed = False;
    metadata->is_in_auction = False;
    metadata->attributes_count = attribute_count;
    
    // Store attributes
    for (U8 i = 0; i < attribute_count; i++) {
        store_nft_attribute(nft_mint, &attributes[i]);
    }
    
    // Mint NFT token to recipient
    mint_nft_token(nft_mint, recipient);
    
    // Collect mint payment if required
    if (collection->allow_public_mint && collection->mint_price > 0) {
        transfer_tokens_to_creator(SOL_MINT, collection->creator, collection->mint_price);
    }
    
    // Update collection stats
    collection->minted_count++;
    collection->total_supply++;
    
    PrintF("NFT minted successfully\n");
    PrintF("NFT: %s\n", nft_name);
    PrintF("Mint: %s\n", encode_base58(nft_mint));
    PrintF("Token ID: %d\n", token_id);
    PrintF("Recipient: %s\n", encode_base58(recipient));
    PrintF("Rarity rank: %d\n", metadata->rarity_rank);
    
    emit_mint_event(nft_mint, collection_id, recipient, token_id);
}

U8 calculate_rarity_rank(NFTAttribute* attributes, U8 count) {
    // Simple rarity calculation based on attribute uniqueness
    U64 rarity_score = 0;
    
    for (U8 i = 0; i < count; i++) {
        U64 trait_rarity = get_trait_rarity_score(attributes[i].trait_type, attributes[i].value);
        rarity_score += trait_rarity;
    }
    
    // Convert to 1-10 scale
    if (rarity_score > 1000) return 10; // Legendary
    if (rarity_score > 800) return 9;   // Epic
    if (rarity_score > 600) return 8;   // Rare
    if (rarity_score > 400) return 7;   // Uncommon
    if (rarity_score > 200) return 6;   // Common
    return 5; // Basic
}
```

### Marketplace Listings

Create and manage NFT listings:

```c
U0 list_nft_for_sale(
    U8* nft_mint,
    U8* currency_mint,
    U64 price,
    U64 duration_seconds
) {
    NFTMetadata* metadata = get_nft_metadata_account(nft_mint);
    
    if (!metadata) {
        PrintF("ERROR: NFT not found\n");
        return;
    }
    
    // Verify ownership
    if (!compare_pubkeys(metadata->current_owner, get_current_user())) {
        PrintF("ERROR: Not NFT owner\n");
        return;
    }
    
    // Check if already listed or in auction
    if (metadata->is_listed || metadata->is_in_auction) {
        PrintF("ERROR: NFT already listed or in auction\n");
        return;
    }
    
    if (price == 0) {
        PrintF("ERROR: Price must be positive\n");
        return;
    }
    
    if (duration_seconds < 3600 || duration_seconds > 2592000) { // 1 hour to 30 days
        PrintF("ERROR: Invalid listing duration\n");
        return;
    }
    
    // Validate currency is supported
    if (!is_supported_currency(currency_mint)) {
        PrintF("ERROR: Currency not supported\n");
        return;
    }
    
    // Generate listing ID
    U8[32] listing_id;
    generate_listing_id(listing_id, nft_mint, get_current_user(), get_current_timestamp());
    
    // Calculate fees
    U64 marketplace_fee = (price * get_marketplace_fee_rate()) / 10000;
    NFTCollection* collection = get_nft_collection_account(metadata->collection_id);
    U64 royalty_fee = (price * collection->royalty_percentage) / 10000;
    
    // Create listing
    MarketplaceListing* listing = get_marketplace_listing_account(listing_id);
    copy_pubkey(listing->listing_id, listing_id);
    copy_pubkey(listing->nft_mint, nft_mint);
    copy_pubkey(listing->seller, get_current_user());
    copy_pubkey(listing->currency_mint, currency_mint);
    
    listing->price = price;
    listing->listing_timestamp = get_current_timestamp();
    listing->expiry_timestamp = get_current_timestamp() + duration_seconds;
    listing->listing_type = 0; // Fixed price
    listing->is_active = True;
    listing->allow_partial_fill = False;
    listing->marketplace_fee = marketplace_fee;
    listing->royalty_fee = royalty_fee;
    
    // Update NFT status
    metadata->is_listed = True;
    
    // Escrow NFT (transfer to marketplace)
    escrow_nft(nft_mint, listing_id);
    
    PrintF("NFT listed for sale\n");
    PrintF("NFT: %s\n", metadata->name);
    PrintF("Price: %d %s\n", price, get_currency_symbol(currency_mint));
    PrintF("Marketplace fee: %d\n", marketplace_fee);
    PrintF("Creator royalty: %d\n", royalty_fee);
    PrintF("Expires: %d\n", listing->expiry_timestamp);
    
    emit_listing_event(listing_id, nft_mint, get_current_user(), price);
}

U0 buy_nft(U8* listing_id) {
    MarketplaceListing* listing = get_marketplace_listing_account(listing_id);
    
    if (!listing || !listing->is_active) {
        PrintF("ERROR: Listing not available\n");
        return;
    }
    
    // Check expiry
    if (get_current_timestamp() > listing->expiry_timestamp) {
        PrintF("ERROR: Listing has expired\n");
        listing->is_active = False;
        return;
    }
    
    // Cannot buy own listing
    if (compare_pubkeys(listing->seller, get_current_user())) {
        PrintF("ERROR: Cannot buy your own listing\n");
        return;
    }
    
    // Validate buyer has sufficient balance
    if (!validate_user_balance(listing->currency_mint, listing->price)) {
        PrintF("ERROR: Insufficient balance\n");
        return;
    }
    
    NFTMetadata* metadata = get_nft_metadata_account(listing->nft_mint);
    NFTCollection* collection = get_nft_collection_account(metadata->collection_id);
    
    // Calculate payment distribution
    U64 seller_amount = listing->price - listing->marketplace_fee - listing->royalty_fee;
    
    // Execute payment
    transfer_tokens_from_buyer(listing->currency_mint, get_current_user(), listing->price);
    
    // Distribute payments
    transfer_tokens_to_seller(listing->currency_mint, listing->seller, seller_amount);
    transfer_tokens_to_treasury(listing->currency_mint, listing->marketplace_fee);
    transfer_tokens_to_creator(listing->currency_mint, collection->royalty_recipient, listing->royalty_fee);
    
    // Transfer NFT to buyer
    transfer_nft_from_escrow(listing->nft_mint, get_current_user());
    
    // Update NFT metadata
    metadata->current_owner = get_current_user();
    metadata->last_sale_price = listing->price;
    metadata->last_transfer_time = get_current_timestamp();
    metadata->is_listed = False;
    
    // Update collection stats
    collection->total_volume += listing->price;
    update_collection_floor_price(metadata->collection_id);
    
    // Deactivate listing
    listing->is_active = False;
    
    // Record transaction
    record_marketplace_transaction(
        listing->nft_mint,
        listing->seller,
        get_current_user(),
        listing->currency_mint,
        listing->price,
        listing->marketplace_fee,
        listing->royalty_fee,
        0 // DirectSale
    );
    
    PrintF("NFT purchased successfully\n");
    PrintF("NFT: %s\n", metadata->name);
    PrintF("Price paid: %d\n", listing->price);
    PrintF("Seller received: %d\n", seller_amount);
    
    emit_sale_event(listing_id, listing->nft_mint, listing->seller, get_current_user(), listing->price);
}

U0 cancel_listing(U8* listing_id) {
    MarketplaceListing* listing = get_marketplace_listing_account(listing_id);
    
    if (!listing || !listing->is_active) {
        PrintF("ERROR: Listing not found or inactive\n");
        return;
    }
    
    // Only seller can cancel
    if (!compare_pubkeys(listing->seller, get_current_user())) {
        PrintF("ERROR: Only seller can cancel listing\n");
        return;
    }
    
    // Return NFT to seller
    transfer_nft_from_escrow(listing->nft_mint, listing->seller);
    
    // Update NFT status
    NFTMetadata* metadata = get_nft_metadata_account(listing->nft_mint);
    metadata->is_listed = False;
    
    // Deactivate listing
    listing->is_active = False;
    
    PrintF("Listing cancelled\n");
    PrintF("NFT returned to seller: %s\n", encode_base58(listing->seller));
}
```

### Auction System

Implement English and Dutch auction mechanisms:

```c
U0 create_auction(
    U8* nft_mint,
    U8* currency_mint,
    U64 starting_price,
    U64 reserve_price,
    U64 duration_seconds,
    U8 auction_type
) {
    NFTMetadata* metadata = get_nft_metadata_account(nft_mint);
    
    if (!metadata) {
        PrintF("ERROR: NFT not found\n");
        return;
    }
    
    // Verify ownership
    if (!compare_pubkeys(metadata->current_owner, get_current_user())) {
        PrintF("ERROR: Not NFT owner\n");
        return;
    }
    
    // Check if already listed or in auction
    if (metadata->is_listed || metadata->is_in_auction) {
        PrintF("ERROR: NFT already listed or in auction\n");
        return;
    }
    
    if (starting_price == 0) {
        PrintF("ERROR: Starting price must be positive\n");
        return;
    }
    
    if (reserve_price > 0 && reserve_price < starting_price) {
        PrintF("ERROR: Reserve price cannot be below starting price\n");
        return;
    }
    
    if (duration_seconds < 3600 || duration_seconds > 604800) { // 1 hour to 7 days
        PrintF("ERROR: Invalid auction duration\n");
        return;
    }
    
    if (auction_type > 2) {
        PrintF("ERROR: Invalid auction type (0=English, 1=Dutch, 2=Reserve)\n");
        return;
    }
    
    // Generate auction ID
    U8[32] auction_id;
    generate_auction_id(auction_id, nft_mint, get_current_user(), get_current_timestamp());
    
    // Create auction
    NFTAuction* auction = get_nft_auction_account(auction_id);
    copy_pubkey(auction->auction_id, auction_id);
    copy_pubkey(auction->nft_mint, nft_mint);
    copy_pubkey(auction->auctioneer, get_current_user());
    copy_pubkey(auction->currency_mint, currency_mint);
    
    auction->starting_price = starting_price;
    auction->reserve_price = reserve_price;
    auction->current_bid = 0;
    // Initialize highest_bidder to zero
    for (U8 i = 0; i < 32; i++) {
        auction->highest_bidder[i] = 0;
    }
    
    auction->start_time = get_current_timestamp();
    auction->end_time = get_current_timestamp() + duration_seconds;
    auction->bid_increment = starting_price / 20; // 5% minimum increment
    auction->total_bids = 0;
    auction->auction_type = auction_type;
    auction->is_active = True;
    auction->reserve_met = reserve_price == 0; // No reserve means always met
    auction->auto_extend = True;
    auction->extension_period = 600; // 10 minutes
    
    // Update NFT status
    metadata->is_in_auction = True;
    
    // Escrow NFT
    escrow_nft(nft_mint, auction_id);
    
    PrintF("Auction created successfully\n");
    PrintF("NFT: %s\n", metadata->name);
    PrintF("Starting price: %d\n", starting_price);
    PrintF("Reserve price: %s\n", reserve_price > 0 ? "Set" : "None");
    PrintF("Duration: %d seconds\n", duration_seconds);
    PrintF("Type: %s\n", auction_type == 0 ? "English" : auction_type == 1 ? "Dutch" : "Reserve");
    
    emit_auction_created_event(auction_id, nft_mint, get_current_user(), starting_price);
}

U0 place_bid(U8* auction_id, U64 bid_amount) {
    NFTAuction* auction = get_nft_auction_account(auction_id);
    
    if (!auction || !auction->is_active) {
        PrintF("ERROR: Auction not available\n");
        return;
    }
    
    // Check auction timing
    U64 current_time = get_current_timestamp();
    if (current_time < auction->start_time) {
        PrintF("ERROR: Auction has not started\n");
        return;
    }
    
    if (current_time > auction->end_time) {
        PrintF("ERROR: Auction has ended\n");
        finalize_auction(auction_id);
        return;
    }
    
    // Cannot bid on own auction
    if (compare_pubkeys(auction->auctioneer, get_current_user())) {
        PrintF("ERROR: Cannot bid on your own auction\n");
        return;
    }
    
    // Validate bid amount
    U64 minimum_bid = auction->current_bid > 0 ? 
                      auction->current_bid + auction->bid_increment : 
                      auction->starting_price;
    
    if (bid_amount < minimum_bid) {
        PrintF("ERROR: Bid too low\n");
        PrintF("Minimum bid: %d, Your bid: %d\n", minimum_bid, bid_amount);
        return;
    }
    
    // Validate bidder has sufficient balance
    if (!validate_user_balance(auction->currency_mint, bid_amount)) {
        PrintF("ERROR: Insufficient balance for bid\n");
        return;
    }
    
    // Generate bid ID
    U8[32] bid_id;
    generate_bid_id(bid_id, auction_id, get_current_user(), current_time);
    
    // Refund previous highest bidder if exists
    if (auction->current_bid > 0) {
        refund_previous_bidder(auction_id);
    }
    
    // Escrow new bid amount
    escrow_bid_amount(auction->currency_mint, get_current_user(), bid_amount);
    
    // Create bid record
    AuctionBid* bid = get_auction_bid_account(bid_id);
    copy_pubkey(bid->bid_id, bid_id);
    copy_pubkey(bid->auction_id, auction_id);
    copy_pubkey(bid->bidder, get_current_user());
    
    bid->bid_amount = bid_amount;
    bid->bid_timestamp = current_time;
    bid->is_winning = True;
    bid->is_refunded = False;
    
    // Update auction state
    auction->current_bid = bid_amount;
    copy_pubkey(auction->highest_bidder, get_current_user());
    auction->total_bids++;
    
    // Check if reserve price met
    if (!auction->reserve_met && bid_amount >= auction->reserve_price) {
        auction->reserve_met = True;
        PrintF("Reserve price met!\n");
    }
    
    // Auto-extend auction if bid placed near end
    if (auction->auto_extend && (auction->end_time - current_time) < auction->extension_period) {
        auction->end_time = current_time + auction->extension_period;
        PrintF("Auction extended by %d seconds\n", auction->extension_period);
    }
    
    PrintF("Bid placed successfully\n");
    PrintF("Bid amount: %d\n", bid_amount);
    PrintF("Current highest bid: %d\n", auction->current_bid);
    PrintF("Time remaining: %d seconds\n", auction->end_time - current_time);
    
    emit_bid_event(auction_id, get_current_user(), bid_amount);
}

U0 finalize_auction(U8* auction_id) {
    NFTAuction* auction = get_nft_auction_account(auction_id);
    
    if (!auction || !auction->is_active) {
        PrintF("ERROR: Auction not available\n");
        return;
    }
    
    // Check if auction has ended
    if (get_current_timestamp() <= auction->end_time) {
        PrintF("ERROR: Auction still ongoing\n");
        return;
    }
    
    NFTMetadata* metadata = get_nft_metadata_account(auction->nft_mint);
    NFTCollection* collection = get_nft_collection_account(metadata->collection_id);
    
    // Check if there were any bids and reserve met
    if (auction->current_bid > 0 && auction->reserve_met) {
        // Successful auction - transfer NFT to winner
        
        // Calculate fees
        U64 marketplace_fee = (auction->current_bid * get_marketplace_fee_rate()) / 10000;
        U64 royalty_fee = (auction->current_bid * collection->royalty_percentage) / 10000;
        U64 seller_amount = auction->current_bid - marketplace_fee - royalty_fee;
        
        // Transfer NFT to winning bidder
        transfer_nft_from_escrow(auction->nft_mint, auction->highest_bidder);
        
        // Distribute payments
        transfer_escrowed_bid_to_seller(auction_id, auction->auctioneer, seller_amount);
        transfer_escrowed_bid_to_treasury(auction_id, marketplace_fee);
        transfer_escrowed_bid_to_creator(auction_id, collection->royalty_recipient, royalty_fee);
        
        // Update NFT metadata
        metadata->current_owner = auction->highest_bidder;
        metadata->last_sale_price = auction->current_bid;
        metadata->last_transfer_time = get_current_timestamp();
        
        // Update collection stats
        collection->total_volume += auction->current_bid;
        update_collection_floor_price(metadata->collection_id);
        
        // Record transaction
        record_marketplace_transaction(
            auction->nft_mint,
            auction->auctioneer,
            auction->highest_bidder,
            auction->currency_mint,
            auction->current_bid,
            marketplace_fee,
            royalty_fee,
            1 // AuctionWin
        );
        
        PrintF("Auction completed successfully\n");
        PrintF("Winner: %s\n", encode_base58(auction->highest_bidder));
        PrintF("Final bid: %d\n", auction->current_bid);
        PrintF("Seller received: %d\n", seller_amount);
        
    } else {
        // No valid bids or reserve not met - return NFT to auctioneer
        transfer_nft_from_escrow(auction->nft_mint, auction->auctioneer);
        
        // Refund final bidder if exists
        if (auction->current_bid > 0) {
            refund_bidder(auction_id, auction->highest_bidder);
        }
        
        PrintF("Auction ended without sale\n");
        PrintF("Reason: %s\n", auction->current_bid == 0 ? "No bids" : "Reserve not met");
    }
    
    // Update NFT and auction status
    metadata->is_in_auction = False;
    auction->is_active = False;
    
    emit_auction_finalized_event(auction_id, auction->current_bid > 0 && auction->reserve_met);
}
```

## Advanced Features

### Collection Verification

Implement creator and collection verification system:

```c
U0 request_collection_verification(U8* collection_id, U8* verification_documents) {
    NFTCollection* collection = get_nft_collection_account(collection_id);
    
    if (!collection) {
        PrintF("ERROR: Collection not found\n");
        return;
    }
    
    // Only collection creator can request verification
    if (!compare_pubkeys(collection->creator, get_current_user())) {
        PrintF("ERROR: Only collection creator can request verification\n");
        return;
    }
    
    if (collection->is_verified) {
        PrintF("ERROR: Collection already verified\n");
        return;
    }
    
    // Submit verification request
    submit_verification_request(collection_id, verification_documents);
    
    PrintF("Verification request submitted\n");
    PrintF("Collection: %s\n", collection->collection_name);
    PrintF("Review process typically takes 3-5 business days\n");
}

U0 verify_collection(U8* collection_id, Bool approved) {
    // Only platform authority can verify collections
    if (!is_platform_authority(get_current_user())) {
        PrintF("ERROR: Not authorized to verify collections\n");
        return;
    }
    
    NFTCollection* collection = get_nft_collection_account(collection_id);
    
    if (!collection) {
        PrintF("ERROR: Collection not found\n");
        return;
    }
    
    if (approved) {
        collection->is_verified = True;
        PrintF("Collection verified successfully\n");
    } else {
        PrintF("Collection verification denied\n");
    }
    
    // Notify collection creator
    notify_verification_result(collection->creator, collection_id, approved);
}
```

This comprehensive NFT marketplace protocol provides sophisticated trading mechanisms with auctions, royalties, collections, and verification systems for a complete digital asset marketplace experience.
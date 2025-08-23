// HolyC Solana Lending Protocol - Divine DeFi Lending
// Professional implementation of decentralized lending and borrowing

// Constants
static const U64 EXCHANGE_RATE_PRECISION = 1000000;
static const U64 UTILIZATION_PRECISION = 10000;
static const U64 SLOTS_PER_YEAR = 63115200; // Approximate slots per year
static const U64 MAX_POSITIONS = 8;

// Lending market data structure
struct LendingMarket {
    U8[32] asset_mint;          // Underlying asset mint
    U8[32] market_authority;    // Market authority
    U64 total_supply;           // Total supplied amount (cTokens)
    U64 total_borrow;           // Total borrowed amount (underlying)
    U64 reserve_factor;         // Protocol reserve percentage (basis points)
    U64 collateral_factor;      // Collateral factor (basis points)
    U64 liquidation_threshold;  // Liquidation threshold (basis points)
    U64 liquidation_bonus;      // Liquidation bonus percentage (basis points)
    U64 supply_rate;            // Current supply APY (basis points)
    U64 borrow_rate;            // Current borrow APY (basis points)
    U64 exchange_rate;          // cToken to underlying exchange rate
    U64 last_update_slot;       // Last interest accrual slot
    U64 available_liquidity;    // Available liquidity for borrowing
    Bool is_active;             // Market active status
    Bool flash_loans_enabled;   // Flash loan availability
};

// User obligation tracking all positions
struct UserObligation {
    U8[32] owner;               // Obligation owner
    U64 borrowed_value_usd;     // Total borrowed value in USD
    U64 collateral_value_usd;   // Total collateral value in USD
    U64 health_factor;          // Position health factor (100 = 1.00)
    U64 position_count;         // Number of active positions
    LendingPosition positions[MAX_POSITIONS]; // User positions array
    U64 last_update_slot;       // Last position update
};

// Individual lending position
struct LendingPosition {
    U8[32] market;              // Market address
    U64 supply_amount;          // Supplied amount in cTokens
    U64 borrow_amount;          // Borrowed amount in underlying tokens
    Bool use_as_collateral;     // Whether position counts as collateral
    U64 last_interest_index;    // Last interest index for calculations
};

// Interest rate model parameters
struct InterestRateModel {
    U64 base_rate;              // Base interest rate (basis points)
    U64 multiplier;             // Interest rate multiplier
    U64 jump_multiplier;        // Jump multiplier above kink
    U64 kink;                   // Utilization rate kink point
};

// Global state
static LendingMarket markets[10];
static U64 market_count = 0;
static UserObligation current_obligation;
static Bool obligation_loaded = False;
static InterestRateModel default_rate_model = {200, 500, 10000, 8000}; // 2%, 5%, 100%, 80%

// Price oracle simulation
static U64 asset_prices[10] = {100000000, 200000000, 50000000, 300000000, 150000000, 0, 0, 0, 0, 0}; // USD prices with 6 decimals

// Divine main function
U0 main() {
    PrintF("=== Divine Lending Protocol Active ===\n");
    PrintF("Decentralized lending and borrowing in HolyC\n");
    PrintF("Interest-bearing collateralized lending system\n");
    
    // Initialize test markets
    test_market_initialization();
    test_supply_operations();
    test_borrow_operations();
    test_liquidation_system();
    test_flash_loans();
    
    PrintF("=== Lending Protocol Tests Completed ===\n");
    return 0;
}

// Solana program entrypoint
export U0 entrypoint(U8* input, U64 input_len) {
    PrintF("Lending protocol entrypoint called with length: %d\n", input_len);
    
    if (input_len < 1) {
        PrintF("ERROR: No instruction provided\n");
        return;
    }
    
    U8 instruction_type = *input;
    U8* instruction_data = input + 1;
    U64 data_len = input_len - 1;
    
    switch (instruction_type) {
        case 0:
            PrintF("Instruction: Initialize Market\n");
            process_init_market(instruction_data, data_len);
            break;
        case 1:
            PrintF("Instruction: Supply Asset\n");
            process_supply(instruction_data, data_len);
            break;
        case 2:
            PrintF("Instruction: Withdraw Asset\n");
            process_withdraw(instruction_data, data_len);
            break;
        case 3:
            PrintF("Instruction: Borrow Asset\n");
            process_borrow(instruction_data, data_len);
            break;
        case 4:
            PrintF("Instruction: Repay Asset\n");
            process_repay(instruction_data, data_len);
            break;
        case 5:
            PrintF("Instruction: Liquidate Position\n");
            process_liquidation(instruction_data, data_len);
            break;
        case 6:
            PrintF("Instruction: Flash Loan\n");
            process_flash_loan(instruction_data, data_len);
            break;
        case 7:
            PrintF("Instruction: Update Interest Rates\n");
            process_update_rates(instruction_data, data_len);
            break;
        default:
            PrintF("ERROR: Unknown instruction type: %d\n", instruction_type);
            break;
    }
    
    return;
}

// Initialize lending market
U0 process_init_market(U8* data, U64 data_len) {
    if (data_len < 80) { // 32 + 32 + 8 + 8 bytes minimum
        PrintF("ERROR: Insufficient data for market initialization\n");
        return;
    }
    
    if (market_count >= 10) {
        PrintF("ERROR: Maximum markets reached\n");
        return;
    }
    
    U8* asset_mint = data;
    U8* authority = data + 32;
    U64 collateral_factor = *(U64*)(data + 64);
    U64 liquidation_threshold = *(U64*)(data + 72);
    
    // Validate parameters
    if (collateral_factor > 9000) {
        PrintF("ERROR: Collateral factor too high (max 90%%)\n");
        return;
    }
    
    if (liquidation_threshold <= collateral_factor || liquidation_threshold > 9500) {
        PrintF("ERROR: Invalid liquidation threshold\n");
        return;
    }
    
    // Initialize market
    LendingMarket* market = &markets[market_count];
    copy_pubkey(market->asset_mint, asset_mint);
    copy_pubkey(market->market_authority, authority);
    
    market->total_supply = 0;
    market->total_borrow = 0;
    market->reserve_factor = 1000; // 10%
    market->collateral_factor = collateral_factor;
    market->liquidation_threshold = liquidation_threshold;
    market->liquidation_bonus = 500; // 5%
    market->supply_rate = 0;
    market->borrow_rate = 0;
    market->exchange_rate = EXCHANGE_RATE_PRECISION; // 1:1 initially
    market->last_update_slot = get_current_slot();
    market->available_liquidity = 0;
    market->is_active = True;
    market->flash_loans_enabled = True;
    
    market_count++;
    
    PrintF("Lending market initialized successfully\n");
    PrintF("Asset mint: %s\n", encode_base58(asset_mint));
    PrintF("Collateral factor: %d.%d%%\n", collateral_factor / 100, collateral_factor % 100);
    PrintF("Liquidation threshold: %d.%d%%\n", liquidation_threshold / 100, liquidation_threshold % 100);
}

// Supply assets to earn interest
U0 process_supply(U8* data, U64 data_len) {
    if (data_len < 40) { // 32 + 8 bytes
        PrintF("ERROR: Insufficient data for supply operation\n");
        return;
    }
    
    U8* asset_mint = data;
    U64 supply_amount = *(U64*)(data + 32);
    
    LendingMarket* market = find_market_by_mint(asset_mint);
    if (!market || !market->is_active) {
        PrintF("ERROR: Market not found or inactive\n");
        return;
    }
    
    if (supply_amount == 0) {
        PrintF("ERROR: Cannot supply zero amount\n");
        return;
    }
    
    // Accrue interest before supply
    accrue_interest(market);
    
    // Calculate cTokens to mint
    U64 ctokens_to_mint = (supply_amount * EXCHANGE_RATE_PRECISION) / market->exchange_rate;
    
    if (ctokens_to_mint == 0) {
        PrintF("ERROR: Supply amount too small\n");
        return;
    }
    
    // Update market state
    market->total_supply += ctokens_to_mint;
    market->available_liquidity += supply_amount;
    
    // Update user position
    ensure_obligation_loaded();
    update_user_supply_position(market, ctokens_to_mint);
    
    PrintF("Supply executed successfully\n");
    PrintF("Supplied: %d underlying tokens\n", supply_amount);
    PrintF("Received: %d cTokens\n", ctokens_to_mint);
    PrintF("Exchange rate: %d.%d\n", market->exchange_rate / 10000, market->exchange_rate % 10000);
    PrintF("New supply APY: %d.%d%%\n", market->supply_rate / 100, market->supply_rate % 100);
}

// Borrow assets against collateral
U0 process_borrow(U8* data, U64 data_len) {
    if (data_len < 40) { // 32 + 8 bytes
        PrintF("ERROR: Insufficient data for borrow operation\n");
        return;
    }
    
    U8* asset_mint = data;
    U64 borrow_amount = *(U64*)(data + 32);
    
    LendingMarket* market = find_market_by_mint(asset_mint);
    if (!market || !market->is_active) {
        PrintF("ERROR: Market not found or inactive\n");
        return;
    }
    
    if (borrow_amount == 0) {
        PrintF("ERROR: Cannot borrow zero amount\n");
        return;
    }
    
    // Check liquidity
    if (borrow_amount > market->available_liquidity) {
        PrintF("ERROR: Insufficient market liquidity\n");
        PrintF("Requested: %d, Available: %d\n", borrow_amount, market->available_liquidity);
        return;
    }
    
    // Accrue interest
    accrue_interest(market);
    
    // Load user obligation
    ensure_obligation_loaded();
    
    // Calculate borrowing power
    U64 borrowing_power = calculate_borrowing_power(&current_obligation);
    U64 asset_price = get_asset_price(asset_mint);
    U64 borrow_value = borrow_amount * asset_price / 1000000; // Convert to USD
    
    if (current_obligation.borrowed_value_usd + borrow_value > borrowing_power) {
        PrintF("ERROR: Insufficient collateral\n");
        PrintF("Borrowing power: $%d, Required: $%d\n", borrowing_power / 1000000, 
               (current_obligation.borrowed_value_usd + borrow_value) / 1000000);
        return;
    }
    
    // Execute borrow
    market->total_borrow += borrow_amount;
    market->available_liquidity -= borrow_amount;
    
    // Update user position
    update_user_borrow_position(market, borrow_amount);
    
    // Recalculate health factor
    current_obligation.health_factor = calculate_health_factor(&current_obligation);
    
    PrintF("Borrow executed successfully\n");
    PrintF("Borrowed: %d tokens\n", borrow_amount);
    PrintF("Borrow APY: %d.%d%%\n", market->borrow_rate / 100, market->borrow_rate % 100);
    PrintF("Health factor: %d.%d\n", current_obligation.health_factor / 100, current_obligation.health_factor % 100);
}

// Liquidate undercollateralized position
U0 process_liquidation(U8* data, U64 data_len) {
    if (data_len < 72) { // 32 + 32 + 8 bytes
        PrintF("ERROR: Insufficient data for liquidation\n");
        return;
    }
    
    U8* borrower_obligation = data;
    U8* repay_mint = data + 32;
    U64 repay_amount = *(U64*)(data + 64);
    
    // Load borrower obligation (simulated)
    UserObligation borrower;
    load_obligation(&borrower, borrower_obligation);
    
    // Check if liquidation is allowed
    U64 health_factor = calculate_health_factor(&borrower);
    if (health_factor >= 100) {
        PrintF("ERROR: Position is healthy, liquidation not allowed\n");
        PrintF("Health factor: %d.%d\n", health_factor / 100, health_factor % 100);
        return;
    }
    
    LendingMarket* repay_market = find_market_by_mint(repay_mint);
    if (!repay_market) {
        PrintF("ERROR: Repay market not found\n");
        return;
    }
    
    // Find borrow position
    LendingPosition* borrow_pos = find_borrow_position(&borrower, repay_market);
    if (!borrow_pos || borrow_pos->borrow_amount == 0) {
        PrintF("ERROR: No borrow position found\n");
        return;
    }
    
    // Calculate maximum liquidation (50% of position)
    U64 max_liquidation = borrow_pos->borrow_amount / 2;
    if (borrow_pos->borrow_amount < 100000) {
        max_liquidation = borrow_pos->borrow_amount; // Full liquidation for small positions
    }
    
    if (repay_amount > max_liquidation) {
        PrintF("ERROR: Liquidation amount exceeds maximum\n");
        return;
    }
    
    // Find best collateral to seize
    LendingPosition* collateral_pos = find_best_collateral(&borrower);
    if (!collateral_pos) {
        PrintF("ERROR: No collateral available for seizure\n");
        return;
    }
    
    LendingMarket* collateral_market = find_market_by_position(collateral_pos);
    
    // Calculate collateral seizure
    U64 repay_value = repay_amount * get_asset_price(repay_mint) / 1000000;
    U64 collateral_value = repay_value * (10000 + collateral_market->liquidation_bonus) / 10000;
    U64 collateral_price = get_asset_price(collateral_market->asset_mint);
    U64 collateral_amount = collateral_value * 1000000 / collateral_price;
    
    // Convert to cTokens
    U64 collateral_ctokens = (collateral_amount * EXCHANGE_RATE_PRECISION) / 
                            collateral_market->exchange_rate;
    
    if (collateral_ctokens > collateral_pos->supply_amount) {
        PrintF("ERROR: Insufficient collateral\n");
        return;
    }
    
    // Execute liquidation
    borrow_pos->borrow_amount -= repay_amount;
    collateral_pos->supply_amount -= collateral_ctokens;
    
    repay_market->total_borrow -= repay_amount;
    collateral_market->total_supply -= collateral_ctokens;
    
    PrintF("Liquidation executed successfully\n");
    PrintF("Repaid: %d %s\n", repay_amount, encode_base58(repay_mint));
    PrintF("Seized: %d cTokens\n", collateral_ctokens);
    PrintF("Liquidation bonus: %d.%d%%\n", 
           collateral_market->liquidation_bonus / 100, collateral_market->liquidation_bonus % 100);
}

// Flash loan execution
U0 process_flash_loan(U8* data, U64 data_len) {
    if (data_len < 40) {
        PrintF("ERROR: Insufficient data for flash loan\n");
        return;
    }
    
    U8* asset_mint = data;
    U64 loan_amount = *(U64*)(data + 32);
    
    LendingMarket* market = find_market_by_mint(asset_mint);
    if (!market || !market->flash_loans_enabled) {
        PrintF("ERROR: Flash loans not available for this market\n");
        return;
    }
    
    if (loan_amount > market->available_liquidity) {
        PrintF("ERROR: Insufficient liquidity for flash loan\n");
        return;
    }
    
    // Calculate fee (0.09%)
    U64 fee_amount = (loan_amount * 9) / 10000;
    U64 total_repay = loan_amount + fee_amount;
    
    // Record state before loan
    U64 initial_liquidity = market->available_liquidity;
    
    // Execute flash loan
    market->available_liquidity -= loan_amount;
    
    PrintF("Flash loan executed: %d tokens\n", loan_amount);
    PrintF("Fee required: %d tokens\n", fee_amount);
    
    // Simulate flash loan instructions execution
    execute_flash_loan_callback(asset_mint, loan_amount, fee_amount);
    
    // Verify repayment
    if (market->available_liquidity < initial_liquidity + fee_amount) {
        PrintF("ERROR: Flash loan not properly repaid\n");
        // In real implementation, this would revert the entire transaction
        return;
    }
    
    PrintF("Flash loan repaid successfully with fee\n");
}

// Accrue interest on market
U0 accrue_interest(LendingMarket* market) {
    U64 current_slot = get_current_slot();
    U64 slots_elapsed = current_slot - market->last_update_slot;
    
    if (slots_elapsed == 0) return;
    
    // Calculate utilization rate
    U64 total_underlying = (market->total_supply * market->exchange_rate) / EXCHANGE_RATE_PRECISION;
    U64 utilization_rate = 0;
    
    if (total_underlying > 0) {
        utilization_rate = (market->total_borrow * UTILIZATION_PRECISION) / total_underlying;
    }
    
    // Calculate borrow rate
    U64 borrow_rate = calculate_borrow_rate(utilization_rate);
    
    // Calculate supply rate
    U64 supply_rate = (borrow_rate * utilization_rate * (10000 - market->reserve_factor)) / 
                      (UTILIZATION_PRECISION * 10000);
    
    // Apply interest
    if (market->total_borrow > 0) {
        U64 borrow_interest = (borrow_rate * slots_elapsed) / SLOTS_PER_YEAR;
        market->total_borrow += (market->total_borrow * borrow_interest) / 10000;
    }
    
    // Update exchange rate
    if (market->total_supply > 0) {
        U64 supply_interest = (supply_rate * slots_elapsed) / SLOTS_PER_YEAR;
        market->exchange_rate += (market->exchange_rate * supply_interest) / 10000;
    }
    
    market->supply_rate = supply_rate;
    market->borrow_rate = borrow_rate;
    market->last_update_slot = current_slot;
    
    PrintF("Interest accrued - Utilization: %d.%d%%, Borrow: %d.%d%%, Supply: %d.%d%%\n",
           utilization_rate / 100, utilization_rate % 100,
           borrow_rate / 100, borrow_rate % 100,
           supply_rate / 100, supply_rate % 100);
}

// Calculate borrow rate using kinked model
U64 calculate_borrow_rate(U64 utilization_rate) {
    if (utilization_rate <= default_rate_model.kink) {
        return default_rate_model.base_rate + 
               (utilization_rate * default_rate_model.multiplier / UTILIZATION_PRECISION);
    } else {
        U64 normal_rate = default_rate_model.base_rate + 
                         (default_rate_model.kink * default_rate_model.multiplier / UTILIZATION_PRECISION);
        U64 excess_util = utilization_rate - default_rate_model.kink;
        return normal_rate + (excess_util * default_rate_model.jump_multiplier / UTILIZATION_PRECISION);
    }
}

// Calculate user's health factor
U64 calculate_health_factor(UserObligation* obligation) {
    if (obligation->borrowed_value_usd == 0) {
        return 1000; // 10.0 maximum health
    }
    
    U64 weighted_collateral = 0;
    
    for (U64 i = 0; i < obligation->position_count; i++) {
        LendingPosition* pos = &obligation->positions[i];
        
        if (pos->use_as_collateral && pos->supply_amount > 0) {
            LendingMarket* market = find_market_by_position(pos);
            if (market) {
                U64 underlying = (pos->supply_amount * market->exchange_rate) / EXCHANGE_RATE_PRECISION;
                U64 value = underlying * get_asset_price(market->asset_mint) / 1000000;
                weighted_collateral += (value * market->liquidation_threshold) / 10000;
            }
        }
    }
    
    return (weighted_collateral * 100) / obligation->borrowed_value_usd;
}

// Calculate borrowing power
U64 calculate_borrowing_power(UserObligation* obligation) {
    U64 borrowing_power = 0;
    
    for (U64 i = 0; i < obligation->position_count; i++) {
        LendingPosition* pos = &obligation->positions[i];
        
        if (pos->use_as_collateral && pos->supply_amount > 0) {
            LendingMarket* market = find_market_by_position(pos);
            if (market) {
                U64 underlying = (pos->supply_amount * market->exchange_rate) / EXCHANGE_RATE_PRECISION;
                U64 value = underlying * get_asset_price(market->asset_mint) / 1000000;
                borrowing_power += (value * market->collateral_factor) / 10000;
            }
        }
    }
    
    return borrowing_power;
}

// Utility functions
LendingMarket* find_market_by_mint(U8* mint) {
    for (U64 i = 0; i < market_count; i++) {
        if (compare_pubkeys(markets[i].asset_mint, mint)) {
            return &markets[i];
        }
    }
    return 0;
}

LendingMarket* find_market_by_position(LendingPosition* pos) {
    for (U64 i = 0; i < market_count; i++) {
        if (compare_pubkeys_array(markets[i].asset_mint, pos->market)) {
            return &markets[i];
        }
    }
    return 0;
}

U0 ensure_obligation_loaded() {
    if (!obligation_loaded) {
        // Initialize empty obligation
        current_obligation.borrowed_value_usd = 0;
        current_obligation.collateral_value_usd = 0;
        current_obligation.health_factor = 1000;
        current_obligation.position_count = 0;
        current_obligation.last_update_slot = get_current_slot();
        obligation_loaded = True;
    }
}

U0 update_user_supply_position(LendingMarket* market, U64 ctoken_amount) {
    // Find or create position
    LendingPosition* pos = 0;
    for (U64 i = 0; i < current_obligation.position_count; i++) {
        if (compare_pubkeys(current_obligation.positions[i].market, market->asset_mint)) {
            pos = &current_obligation.positions[i];
            break;
        }
    }
    
    if (!pos && current_obligation.position_count < MAX_POSITIONS) {
        pos = &current_obligation.positions[current_obligation.position_count];
        copy_pubkey(pos->market, market->asset_mint);
        pos->supply_amount = 0;
        pos->borrow_amount = 0;
        pos->use_as_collateral = True;
        current_obligation.position_count++;
    }
    
    if (pos) {
        pos->supply_amount += ctoken_amount;
        
        // Update collateral value
        U64 underlying = (pos->supply_amount * market->exchange_rate) / EXCHANGE_RATE_PRECISION;
        U64 value = underlying * get_asset_price(market->asset_mint) / 1000000;
        current_obligation.collateral_value_usd += value;
    }
}

U0 update_user_borrow_position(LendingMarket* market, U64 borrow_amount) {
    // Find or create position
    LendingPosition* pos = 0;
    for (U64 i = 0; i < current_obligation.position_count; i++) {
        if (compare_pubkeys(current_obligation.positions[i].market, market->asset_mint)) {
            pos = &current_obligation.positions[i];
            break;
        }
    }
    
    if (!pos && current_obligation.position_count < MAX_POSITIONS) {
        pos = &current_obligation.positions[current_obligation.position_count];
        copy_pubkey(pos->market, market->asset_mint);
        pos->supply_amount = 0;
        pos->borrow_amount = 0;
        pos->use_as_collateral = False;
        current_obligation.position_count++;
    }
    
    if (pos) {
        pos->borrow_amount += borrow_amount;
        
        // Update borrowed value
        U64 value = borrow_amount * get_asset_price(market->asset_mint) / 1000000;
        current_obligation.borrowed_value_usd += value;
    }
}

LendingPosition* find_borrow_position(UserObligation* obligation, LendingMarket* market) {
    for (U64 i = 0; i < obligation->position_count; i++) {
        if (compare_pubkeys(obligation->positions[i].market, market->asset_mint) &&
            obligation->positions[i].borrow_amount > 0) {
            return &obligation->positions[i];
        }
    }
    return 0;
}

LendingPosition* find_best_collateral(UserObligation* obligation) {
    LendingPosition* best = 0;
    U64 best_value = 0;
    
    for (U64 i = 0; i < obligation->position_count; i++) {
        LendingPosition* pos = &obligation->positions[i];
        if (pos->use_as_collateral && pos->supply_amount > 0) {
            LendingMarket* market = find_market_by_position(pos);
            if (market) {
                U64 underlying = (pos->supply_amount * market->exchange_rate) / EXCHANGE_RATE_PRECISION;
                U64 value = underlying * get_asset_price(market->asset_mint) / 1000000;
                if (value > best_value) {
                    best_value = value;
                    best = pos;
                }
            }
        }
    }
    
    return best;
}

U0 load_obligation(UserObligation* obligation, U8* obligation_address) {
    // Simulate loading obligation from account
    obligation->borrowed_value_usd = 5000000000; // $5000
    obligation->collateral_value_usd = 8000000000; // $8000
    obligation->health_factor = 95; // 0.95 (liquidatable)
    obligation->position_count = 2;
    obligation->last_update_slot = get_current_slot();
}

U0 execute_flash_loan_callback(U8* asset_mint, U64 loan_amount, U64 fee_amount) {
    PrintF("Executing flash loan callback...\n");
    PrintF("Available for arbitrage: %d tokens\n", loan_amount);
    
    // Simulate arbitrage or liquidation operations
    PrintF("Performing arbitrage operations...\n");
    
    // Simulate repayment
    LendingMarket* market = find_market_by_mint(asset_mint);
    if (market) {
        market->available_liquidity += loan_amount + fee_amount;
    }
    
    PrintF("Flash loan callback completed\n");
}

U64 get_asset_price(U8* mint) {
    // Simulate price oracle
    U64 hash = 0;
    for (U64 i = 0; i < 8; i++) {
        hash += mint[i];
    }
    return asset_prices[hash % 5];
}

U64 get_current_slot() {
    static U64 slot = 1000000;
    slot += 1;
    return slot;
}

// Test functions
U0 test_market_initialization() {
    PrintF("\n--- Testing Market Initialization ---\n");
    
    U8 usdc_mint[32] = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
    U8 sol_mint[32] = {2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2};
    U8 authority[32] = {0};
    
    U8 init_data[80];
    copy_array(init_data, usdc_mint, 32);
    copy_array(init_data + 32, authority, 32);
    *(U64*)(init_data + 64) = 8000; // 80% collateral factor
    *(U64*)(init_data + 72) = 8500; // 85% liquidation threshold
    
    process_init_market(init_data, 80);
    
    copy_array(init_data, sol_mint, 32);
    *(U64*)(init_data + 64) = 7000; // 70% collateral factor
    *(U64*)(init_data + 72) = 7500; // 75% liquidation threshold
    
    process_init_market(init_data, 80);
    
    PrintF("Market initialization tests completed\n");
}

U0 test_supply_operations() {
    PrintF("\n--- Testing Supply Operations ---\n");
    
    U8 usdc_mint[32] = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
    
    U8 supply_data[40];
    copy_array(supply_data, usdc_mint, 32);
    *(U64*)(supply_data + 32) = 1000000; // Supply 1M USDC
    
    process_supply(supply_data, 40);
    
    PrintF("Supply operations tests completed\n");
}

U0 test_borrow_operations() {
    PrintF("\n--- Testing Borrow Operations ---\n");
    
    U8 sol_mint[32] = {2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2};
    
    U8 borrow_data[40];
    copy_array(borrow_data, sol_mint, 32);
    *(U64*)(borrow_data + 32) = 1000; // Borrow 1000 SOL
    
    process_borrow(borrow_data, 40);
    
    PrintF("Borrow operations tests completed\n");
}

U0 test_liquidation_system() {
    PrintF("\n--- Testing Liquidation System ---\n");
    
    U8 borrower[32] = {9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9};
    U8 sol_mint[32] = {2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2};
    
    U8 liquidation_data[72];
    copy_array(liquidation_data, borrower, 32);
    copy_array(liquidation_data + 32, sol_mint, 32);
    *(U64*)(liquidation_data + 64) = 500; // Repay 500 SOL
    
    process_liquidation(liquidation_data, 72);
    
    PrintF("Liquidation system tests completed\n");
}

U0 test_flash_loans() {
    PrintF("\n--- Testing Flash Loans ---\n");
    
    U8 usdc_mint[32] = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
    
    U8 flash_data[40];
    copy_array(flash_data, usdc_mint, 32);
    *(U64*)(flash_data + 32) = 500000; // Flash loan 500K USDC
    
    process_flash_loan(flash_data, 40);
    
    PrintF("Flash loan tests completed\n");
}

// Utility functions
Bool compare_pubkeys(U8* key1, U8* key2) {
    for (U64 i = 0; i < 32; i++) {
        if (key1[i] != key2[i]) return False;
    }
    return True;
}

Bool compare_pubkeys_array(U8* key1, U8* key2) {
    return compare_pubkeys(key1, key2);
}

U0 copy_pubkey(U8* dest, U8* src) {
    for (U64 i = 0; i < 32; i++) {
        dest[i] = src[i];
    }
}

U0 copy_array(U8* dest, U8* src, U64 len) {
    for (U64 i = 0; i < len; i++) {
        dest[i] = src[i];
    }
}

U8* encode_base58(U8* pubkey) {
    static U8 encoded[45];
    for (U64 i = 0; i < 44; i++) {
        encoded[i] = 'A' + (pubkey[i % 32] % 26);
    }
    encoded[44] = 0;
    return encoded;
}

U0 process_update_rates(U8* data, U64 data_len) {
    PrintF("Updating interest rates for all markets\n");
    for (U64 i = 0; i < market_count; i++) {
        accrue_interest(&markets[i]);
    }
}

U0 process_withdraw(U8* data, U64 data_len) {
    PrintF("Withdraw operation - implementation pending\n");
}

U0 process_repay(U8* data, U64 data_len) {
    PrintF("Repay operation - implementation pending\n");
}
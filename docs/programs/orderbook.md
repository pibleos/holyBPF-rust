# Orderbook Systems in HolyC

This guide covers the implementation of decentralized orderbook exchanges on Solana using HolyC. Orderbook systems provide traditional trading mechanisms with bid/ask order matching for price discovery and liquidity provision.

## Overview

Orderbook exchanges organize trading through limit orders that specify exact prices and quantities. Unlike AMMs, orderbooks match buyers and sellers directly, providing precise price control and potentially better execution for large trades.

### Key Concepts

**Order Types**: Market orders (immediate execution) and limit orders (execution at specific price or better).

**Order Matching**: Algorithm that pairs buy and sell orders based on price-time priority.

**Bid/Ask Spread**: Difference between highest buy price (bid) and lowest sell price (ask).

**Market Depth**: Total quantity of orders at different price levels.

**Order Settlement**: Process of executing matched orders and transferring assets.

## Orderbook Architecture

### Core Components

1. **Order Management**: Create, modify, and cancel orders
2. **Matching Engine**: Match compatible buy and sell orders
3. **Price Discovery**: Determine market price through order interaction
4. **Settlement System**: Execute trades and transfer assets
5. **Market Data**: Provide real-time orderbook state and trade history

### Data Structures

```c
// Individual order in the orderbook
struct Order {
    U8[32] order_id;           // Unique order identifier
    U8[32] owner;              // Order owner public key
    U8[32] market;             // Trading market address
    U64 price;                 // Order price (in quote token units)
    U64 quantity;              // Order quantity (in base token units)
    U64 filled_quantity;       // Amount already filled
    U64 timestamp;             // Order creation time
    U8 side;                   // 0 = Buy, 1 = Sell
    U8 order_type;             // 0 = Limit, 1 = Market, 2 = Stop
    Bool is_active;            // Order active status
    U64 expiry_time;           // Order expiration (0 = Good Till Cancelled)
};

// Market configuration and state
struct Market {
    U8[32] market_id;          // Market identifier
    U8[32] base_mint;          // Base token mint
    U8[32] quote_mint;         // Quote token mint
    U8[32] authority;          // Market authority
    U64 tick_size;             // Minimum price increment
    U64 lot_size;              // Minimum quantity increment
    U64 maker_fee;             // Maker fee (basis points)
    U64 taker_fee;             // Taker fee (basis points)
    U64 total_volume_24h;      // 24-hour trading volume
    U64 last_trade_price;      // Last executed trade price
    U64 best_bid;              // Current highest buy price
    U64 best_ask;              // Current lowest sell price
    Bool is_active;            // Market active status
};

// Orderbook state with sorted price levels
struct Orderbook {
    U8[32] market;             // Associated market
    PriceLevel bids[MAX_PRICE_LEVELS];  // Buy orders by price (descending)
    PriceLevel asks[MAX_PRICE_LEVELS];  // Sell orders by price (ascending)
    U64 bid_count;             // Number of bid price levels
    U64 ask_count;             // Number of ask price levels
    U64 sequence_number;       // Orderbook update sequence
    U64 last_update_time;      // Last update timestamp
};

// Price level aggregating orders at same price
struct PriceLevel {
    U64 price;                 // Price level
    U64 total_quantity;        // Total quantity at this price
    U64 order_count;           // Number of orders at this price
    Order orders[MAX_ORDERS_PER_LEVEL]; // Orders at this price level
};
```

## Implementation Guide

### Market Initialization

Create a new trading market for a token pair:

```c
U0 initialize_market(U8* base_mint, U8* quote_mint, U64 tick_size, U64 lot_size) {
    // Validate token pair
    if (compare_pubkeys(base_mint, quote_mint)) {
        PrintF("ERROR: Base and quote tokens must be different\n");
        return;
    }
    
    if (tick_size == 0 || lot_size == 0) {
        PrintF("ERROR: Tick size and lot size must be positive\n");
        return;
    }
    
    // Generate market PDA
    U8[32] market_address;
    U8 bump_seed;
    find_program_address(&market_address, &bump_seed, base_mint, quote_mint);
    
    // Initialize market
    Market* market = get_account_data(market_address);
    copy_pubkey(market->market_id, market_address);
    copy_pubkey(market->base_mint, base_mint);
    copy_pubkey(market->quote_mint, quote_mint);
    
    market->tick_size = tick_size;
    market->lot_size = lot_size;
    market->maker_fee = 10;        // 0.1% maker fee
    market->taker_fee = 25;        // 0.25% taker fee
    market->total_volume_24h = 0;
    market->last_trade_price = 0;
    market->best_bid = 0;
    market->best_ask = 0;
    market->is_active = True;
    
    // Initialize empty orderbook
    Orderbook* orderbook = get_orderbook_account(market_address);
    copy_pubkey(orderbook->market, market_address);
    orderbook->bid_count = 0;
    orderbook->ask_count = 0;
    orderbook->sequence_number = 0;
    orderbook->last_update_time = get_current_timestamp();
    
    PrintF("Market initialized successfully\n");
    PrintF("Base mint: %s\n", encode_base58(base_mint));
    PrintF("Quote mint: %s\n", encode_base58(quote_mint));
    PrintF("Tick size: %d, Lot size: %d\n", tick_size, lot_size);
}
```

### Order Placement

Place limit and market orders:

```c
U0 place_order(U8* market_address, U64 price, U64 quantity, U8 side, U8 order_type) {
    Market* market = get_account_data(market_address);
    if (!market || !market->is_active) {
        PrintF("ERROR: Market not found or inactive\n");
        return;
    }
    
    // Validate order parameters
    if (quantity == 0) {
        PrintF("ERROR: Order quantity must be positive\n");
        return;
    }
    
    if (quantity % market->lot_size != 0) {
        PrintF("ERROR: Order quantity must be multiple of lot size\n");
        return;
    }
    
    if (order_type == 0 && price % market->tick_size != 0) { // Limit order
        PrintF("ERROR: Order price must be multiple of tick size\n");
        return;
    }
    
    // Generate unique order ID
    U8[32] order_id;
    generate_order_id(order_id, market_address, get_current_timestamp());
    
    // Create order
    Order order;
    copy_pubkey(order.order_id, order_id);
    copy_pubkey(order.owner, get_current_user());
    copy_pubkey(order.market, market_address);
    order.price = price;
    order.quantity = quantity;
    order.filled_quantity = 0;
    order.timestamp = get_current_timestamp();
    order.side = side;
    order.order_type = order_type;
    order.is_active = True;
    order.expiry_time = 0; // Good till cancelled
    
    // Validate user has sufficient balance
    U8* required_mint = side == 0 ? market->quote_mint : market->base_mint;
    U64 required_amount = side == 0 ? price * quantity : quantity;
    
    if (!validate_user_balance(required_mint, required_amount)) {
        PrintF("ERROR: Insufficient balance for order\n");
        return;
    }
    
    // Lock user funds
    lock_user_funds(required_mint, required_amount);
    
    // Process order based on type
    if (order_type == 1) { // Market order
        process_market_order(&order, market);
    } else { // Limit order
        process_limit_order(&order, market);
    }
    
    PrintF("Order placed successfully\n");
    PrintF("Order ID: %s\n", encode_base58(order_id));
    PrintF("Side: %s, Price: %d, Quantity: %d\n", 
           side == 0 ? "BUY" : "SELL", price, quantity);
}

U0 process_limit_order(Order* order, Market* market) {
    Orderbook* orderbook = get_orderbook_account(market->market_id);
    
    // Try to match against existing orders
    U64 remaining_quantity = order->quantity;
    
    if (order->side == 0) { // Buy order
        // Match against asks (sell orders) starting from lowest price
        for (U64 i = 0; i < orderbook->ask_count && remaining_quantity > 0; i++) {
            PriceLevel* ask_level = &orderbook->asks[i];
            
            if (ask_level->price <= order->price) {
                remaining_quantity = match_orders_at_level(order, ask_level, remaining_quantity, market);
                if (ask_level->total_quantity == 0) {
                    remove_price_level(orderbook->asks, &orderbook->ask_count, i);
                    i--; // Adjust for removed level
                }
            } else {
                break; // No more matching prices
            }
        }
    } else { // Sell order
        // Match against bids (buy orders) starting from highest price
        for (U64 i = 0; i < orderbook->bid_count && remaining_quantity > 0; i++) {
            PriceLevel* bid_level = &orderbook->bids[i];
            
            if (bid_level->price >= order->price) {
                remaining_quantity = match_orders_at_level(order, bid_level, remaining_quantity, market);
                if (bid_level->total_quantity == 0) {
                    remove_price_level(orderbook->bids, &orderbook->bid_count, i);
                    i--; // Adjust for removed level
                }
            } else {
                break; // No more matching prices
            }
        }
    }
    
    // Add remaining quantity to orderbook if any
    if (remaining_quantity > 0) {
        order->quantity = remaining_quantity;
        add_order_to_book(orderbook, order);
        update_best_prices(market, orderbook);
    }
    
    // Update orderbook sequence
    orderbook->sequence_number++;
    orderbook->last_update_time = get_current_timestamp();
}

U0 process_market_order(Order* order, Market* market) {
    Orderbook* orderbook = get_orderbook_account(market->market_id);
    
    U64 remaining_quantity = order->quantity;
    
    if (order->side == 0) { // Buy market order
        // Match against asks starting from best price
        for (U64 i = 0; i < orderbook->ask_count && remaining_quantity > 0; i++) {
            PriceLevel* ask_level = &orderbook->asks[i];
            remaining_quantity = match_orders_at_level(order, ask_level, remaining_quantity, market);
            
            if (ask_level->total_quantity == 0) {
                remove_price_level(orderbook->asks, &orderbook->ask_count, i);
                i--; // Adjust for removed level
            }
        }
    } else { // Sell market order
        // Match against bids starting from best price
        for (U64 i = 0; i < orderbook->bid_count && remaining_quantity > 0; i++) {
            PriceLevel* bid_level = &orderbook->bids[i];
            remaining_quantity = match_orders_at_level(order, bid_level, remaining_quantity, market);
            
            if (bid_level->total_quantity == 0) {
                remove_price_level(orderbook->bids, &orderbook->bid_count, i);
                i--; // Adjust for removed level
            }
        }
    }
    
    if (remaining_quantity > 0) {
        PrintF("WARNING: Market order partially filled due to insufficient liquidity\n");
        PrintF("Unfilled quantity: %d\n", remaining_quantity);
        
        // Refund unfilled portion
        U8* refund_mint = order->side == 0 ? market->quote_mint : market->base_mint;
        U64 refund_amount = order->side == 0 ? remaining_quantity * order->price : remaining_quantity;
        unlock_user_funds(refund_mint, refund_amount);
    }
    
    update_best_prices(market, orderbook);
    orderbook->sequence_number++;
    orderbook->last_update_time = get_current_timestamp();
}
```

### Order Matching Engine

Core matching logic for order execution:

```c
U64 match_orders_at_level(Order* incoming_order, PriceLevel* price_level, U64 remaining_quantity, Market* market) {
    U64 level_remaining = remaining_quantity;
    
    for (U64 i = 0; i < price_level->order_count && level_remaining > 0; i++) {
        Order* book_order = &price_level->orders[i];
        
        if (!book_order->is_active) continue;
        
        // Calculate trade quantity
        U64 available_quantity = book_order->quantity - book_order->filled_quantity;
        U64 trade_quantity = min_u64(level_remaining, available_quantity);
        
        if (trade_quantity > 0) {
            // Execute trade
            execute_trade(incoming_order, book_order, trade_quantity, price_level->price, market);
            
            // Update order states
            incoming_order->filled_quantity += trade_quantity;
            book_order->filled_quantity += trade_quantity;
            level_remaining -= trade_quantity;
            
            // Check if book order is completely filled
            if (book_order->filled_quantity >= book_order->quantity) {
                book_order->is_active = False;
                remove_order_from_level(price_level, i);
                i--; // Adjust for removed order
            }
        }
    }
    
    // Update price level quantity
    U64 total_filled = remaining_quantity - level_remaining;
    price_level->total_quantity -= total_filled;
    
    return level_remaining;
}

U0 execute_trade(Order* taker_order, Order* maker_order, U64 quantity, U64 price, Market* market) {
    // Calculate trade amounts
    U64 base_amount = quantity;
    U64 quote_amount = quantity * price;
    
    // Calculate fees
    U64 maker_fee_amount = (quote_amount * market->maker_fee) / 10000;
    U64 taker_fee_amount = (quote_amount * market->taker_fee) / 10000;
    
    // Determine asset flows based on trade direction
    U8* base_from, *base_to, *quote_from, *quote_to;
    
    if (taker_order->side == 0) { // Taker buying
        base_from = maker_order->owner;
        base_to = taker_order->owner;
        quote_from = taker_order->owner;
        quote_to = maker_order->owner;
    } else { // Taker selling
        base_from = taker_order->owner;
        base_to = maker_order->owner;
        quote_from = maker_order->owner;
        quote_to = taker_order->owner;
    }
    
    // Execute asset transfers
    transfer_tokens(market->base_mint, base_from, base_to, base_amount);
    transfer_tokens(market->quote_mint, quote_from, quote_to, quote_amount - maker_fee_amount);
    
    // Collect fees
    collect_trading_fee(market->quote_mint, quote_from, taker_fee_amount + maker_fee_amount);
    
    // Update market statistics
    market->last_trade_price = price;
    market->total_volume_24h += quote_amount;
    
    // Emit trade event
    emit_trade_event(market->market_id, taker_order->order_id, maker_order->order_id, 
                     price, quantity, base_amount, quote_amount);
    
    PrintF("Trade executed: %d @ %d (fees: maker=%d, taker=%d)\n", 
           quantity, price, maker_fee_amount, taker_fee_amount);
}
```

### Orderbook Management

Maintain sorted orderbook structure:

```c
U0 add_order_to_book(Orderbook* orderbook, Order* order) {
    if (order->side == 0) { // Buy order - add to bids
        insert_bid_order(orderbook, order);
    } else { // Sell order - add to asks
        insert_ask_order(orderbook, order);
    }
}

U0 insert_bid_order(Orderbook* orderbook, Order* order) {
    // Find or create price level (bids sorted descending by price)
    PriceLevel* target_level = 0;
    U64 insert_index = orderbook->bid_count;
    
    for (U64 i = 0; i < orderbook->bid_count; i++) {
        if (orderbook->bids[i].price == order->price) {
            target_level = &orderbook->bids[i];
            break;
        } else if (orderbook->bids[i].price < order->price) {
            insert_index = i;
            break;
        }
    }
    
    if (!target_level) {
        // Create new price level
        if (orderbook->bid_count >= MAX_PRICE_LEVELS) {
            PrintF("ERROR: Maximum price levels reached\n");
            return;
        }
        
        // Shift existing levels to make room
        for (U64 i = orderbook->bid_count; i > insert_index; i--) {
            orderbook->bids[i] = orderbook->bids[i - 1];
        }
        
        target_level = &orderbook->bids[insert_index];
        target_level->price = order->price;
        target_level->total_quantity = 0;
        target_level->order_count = 0;
        orderbook->bid_count++;
    }
    
    // Add order to price level
    if (target_level->order_count < MAX_ORDERS_PER_LEVEL) {
        target_level->orders[target_level->order_count] = *order;
        target_level->order_count++;
        target_level->total_quantity += order->quantity;
    } else {
        PrintF("ERROR: Maximum orders per price level reached\n");
    }
}

U0 insert_ask_order(Orderbook* orderbook, Order* order) {
    // Find or create price level (asks sorted ascending by price)
    PriceLevel* target_level = 0;
    U64 insert_index = orderbook->ask_count;
    
    for (U64 i = 0; i < orderbook->ask_count; i++) {
        if (orderbook->asks[i].price == order->price) {
            target_level = &orderbook->asks[i];
            break;
        } else if (orderbook->asks[i].price > order->price) {
            insert_index = i;
            break;
        }
    }
    
    if (!target_level) {
        // Create new price level
        if (orderbook->ask_count >= MAX_PRICE_LEVELS) {
            PrintF("ERROR: Maximum price levels reached\n");
            return;
        }
        
        // Shift existing levels to make room
        for (U64 i = orderbook->ask_count; i > insert_index; i--) {
            orderbook->asks[i] = orderbook->asks[i - 1];
        }
        
        target_level = &orderbook->asks[insert_index];
        target_level->price = order->price;
        target_level->total_quantity = 0;
        target_level->order_count = 0;
        orderbook->ask_count++;
    }
    
    // Add order to price level
    if (target_level->order_count < MAX_ORDERS_PER_LEVEL) {
        target_level->orders[target_level->order_count] = *order;
        target_level->order_count++;
        target_level->total_quantity += order->quantity;
    } else {
        PrintF("ERROR: Maximum orders per price level reached\n");
    }
}

U0 update_best_prices(Market* market, Orderbook* orderbook) {
    // Update best bid (highest buy price)
    if (orderbook->bid_count > 0) {
        market->best_bid = orderbook->bids[0].price;
    } else {
        market->best_bid = 0;
    }
    
    // Update best ask (lowest sell price)
    if (orderbook->ask_count > 0) {
        market->best_ask = orderbook->asks[0].price;
    } else {
        market->best_ask = 0;
    }
    
    PrintF("Updated best prices: bid=%d, ask=%d, spread=%d\n", 
           market->best_bid, market->best_ask, market->best_ask - market->best_bid);
}
```

### Order Cancellation

Allow users to cancel their active orders:

```c
U0 cancel_order(U8* order_id) {
    // Find order in orderbooks
    Order* order = find_order_by_id(order_id);
    
    if (!order) {
        PrintF("ERROR: Order not found\n");
        return;
    }
    
    if (!order->is_active) {
        PrintF("ERROR: Order is not active\n");
        return;
    }
    
    // Verify ownership
    if (!compare_pubkeys(order->owner, get_current_user())) {
        PrintF("ERROR: Not authorized to cancel this order\n");
        return;
    }
    
    Market* market = get_account_data(order->market);
    Orderbook* orderbook = get_orderbook_account(order->market);
    
    // Find and remove order from orderbook
    PriceLevel* price_levels = order->side == 0 ? orderbook->bids : orderbook->asks;
    U64 level_count = order->side == 0 ? orderbook->bid_count : orderbook->ask_count;
    
    for (U64 i = 0; i < level_count; i++) {
        PriceLevel* level = &price_levels[i];
        
        if (level->price == order->price) {
            for (U64 j = 0; j < level->order_count; j++) {
                if (compare_pubkeys(level->orders[j].order_id, order_id)) {
                    // Calculate unfilled quantity
                    U64 unfilled_quantity = order->quantity - order->filled_quantity;
                    
                    // Remove order from level
                    remove_order_from_level(level, j);
                    
                    // Remove price level if empty
                    if (level->total_quantity == 0) {
                        if (order->side == 0) {
                            remove_price_level(orderbook->bids, &orderbook->bid_count, i);
                        } else {
                            remove_price_level(orderbook->asks, &orderbook->ask_count, i);
                        }
                    }
                    
                    // Refund locked funds
                    U8* refund_mint = order->side == 0 ? market->quote_mint : market->base_mint;
                    U64 refund_amount = order->side == 0 ? unfilled_quantity * order->price : unfilled_quantity;
                    unlock_user_funds(refund_mint, refund_amount);
                    
                    // Update market state
                    update_best_prices(market, orderbook);
                    orderbook->sequence_number++;
                    orderbook->last_update_time = get_current_timestamp();
                    
                    PrintF("Order cancelled successfully\n");
                    PrintF("Order ID: %s\n", encode_base58(order_id));
                    PrintF("Unfilled quantity: %d\n", unfilled_quantity);
                    return;
                }
            }
        }
    }
    
    PrintF("ERROR: Order not found in orderbook\n");
}
```

## Advanced Features

### Stop Orders

Implement stop-loss and take-profit orders:

```c
struct StopOrder {
    U8[32] order_id;           // Stop order identifier
    U8[32] owner;              // Order owner
    U8[32] market;             // Market address
    U64 trigger_price;         // Price that triggers the order
    U64 limit_price;           // Limit price for triggered order (0 = market)
    U64 quantity;              // Order quantity
    U8 side;                   // Order side (0 = buy, 1 = sell)
    U8 condition;              // 0 = stop-loss, 1 = take-profit
    Bool is_active;            // Order active status
    U64 expiry_time;           // Order expiration
};

U0 place_stop_order(U8* market_address, U64 trigger_price, U64 limit_price, U64 quantity, U8 side, U8 condition) {
    Market* market = get_account_data(market_address);
    
    if (!market || !market->is_active) {
        PrintF("ERROR: Market not found or inactive\n");
        return;
    }
    
    // Validate stop order parameters
    if (condition == 0) { // Stop-loss
        if ((side == 0 && trigger_price >= market->last_trade_price) ||
            (side == 1 && trigger_price <= market->last_trade_price)) {
            PrintF("ERROR: Invalid stop-loss trigger price\n");
            return;
        }
    } else { // Take-profit
        if ((side == 0 && trigger_price <= market->last_trade_price) ||
            (side == 1 && trigger_price >= market->last_trade_price)) {
            PrintF("ERROR: Invalid take-profit trigger price\n");
            return;
        }
    }
    
    // Create stop order
    StopOrder stop_order;
    generate_order_id(stop_order.order_id, market_address, get_current_timestamp());
    copy_pubkey(stop_order.owner, get_current_user());
    copy_pubkey(stop_order.market, market_address);
    stop_order.trigger_price = trigger_price;
    stop_order.limit_price = limit_price;
    stop_order.quantity = quantity;
    stop_order.side = side;
    stop_order.condition = condition;
    stop_order.is_active = True;
    stop_order.expiry_time = 0;
    
    // Store stop order in system
    add_stop_order(&stop_order);
    
    PrintF("Stop order placed successfully\n");
    PrintF("Trigger price: %d, Limit price: %d\n", trigger_price, limit_price);
}

U0 check_stop_orders(Market* market) {
    StopOrder* stop_orders = get_market_stop_orders(market->market_id);
    
    for (U64 i = 0; i < get_stop_order_count(market->market_id); i++) {
        StopOrder* order = &stop_orders[i];
        
        if (!order->is_active) continue;
        
        Bool should_trigger = False;
        
        if (order->condition == 0) { // Stop-loss
            if ((order->side == 0 && market->last_trade_price <= order->trigger_price) ||
                (order->side == 1 && market->last_trade_price >= order->trigger_price)) {
                should_trigger = True;
            }
        } else { // Take-profit
            if ((order->side == 0 && market->last_trade_price >= order->trigger_price) ||
                (order->side == 1 && market->last_trade_price <= order->trigger_price)) {
                should_trigger = True;
            }
        }
        
        if (should_trigger) {
            // Convert stop order to market or limit order
            if (order->limit_price == 0) {
                place_order(market->market_id, 0, order->quantity, order->side, 1); // Market order
            } else {
                place_order(market->market_id, order->limit_price, order->quantity, order->side, 0); // Limit order
            }
            
            order->is_active = False;
            PrintF("Stop order triggered and executed\n");
        }
    }
}
```

### Market Data and Analytics

Provide real-time market information:

```c
struct MarketData {
    U64 last_price;            // Last trade price
    U64 price_change_24h;      // 24-hour price change
    U64 volume_24h;            // 24-hour volume
    U64 high_24h;              // 24-hour high
    U64 low_24h;               // 24-hour low
    U64 bid_volume;            // Total bid volume
    U64 ask_volume;            // Total ask volume
    U64 spread;                // Current bid-ask spread
    U64 timestamp;             // Data timestamp
};

U0 get_market_data(U8* market_address, MarketData* data) {
    Market* market = get_account_data(market_address);
    Orderbook* orderbook = get_orderbook_account(market_address);
    
    if (!market || !orderbook) {
        PrintF("ERROR: Market data not available\n");
        return;
    }
    
    data->last_price = market->last_trade_price;
    data->volume_24h = market->total_volume_24h;
    data->spread = market->best_ask - market->best_bid;
    
    // Calculate bid and ask volumes
    data->bid_volume = 0;
    for (U64 i = 0; i < orderbook->bid_count; i++) {
        data->bid_volume += orderbook->bids[i].total_quantity;
    }
    
    data->ask_volume = 0;
    for (U64 i = 0; i < orderbook->ask_count; i++) {
        data->ask_volume += orderbook->asks[i].total_quantity;
    }
    
    // Get 24-hour statistics (would need historical data storage)
    data->price_change_24h = 0; // Placeholder
    data->high_24h = market->last_trade_price; // Placeholder
    data->low_24h = market->last_trade_price;  // Placeholder
    data->timestamp = get_current_timestamp();
    
    PrintF("Market Data:\n");
    PrintF("  Last Price: %d\n", data->last_price);
    PrintF("  Volume 24h: %d\n", data->volume_24h);
    PrintF("  Bid Volume: %d\n", data->bid_volume);
    PrintF("  Ask Volume: %d\n", data->ask_volume);
    PrintF("  Spread: %d\n", data->spread);
}

U0 get_orderbook_depth(U8* market_address, U64 depth_levels) {
    Orderbook* orderbook = get_orderbook_account(market_address);
    
    if (!orderbook) {
        PrintF("ERROR: Orderbook not found\n");
        return;
    }
    
    PrintF("Orderbook Depth (Top %d levels):\n", depth_levels);
    PrintF("ASKS:\n");
    
    // Show asks (sell orders) from lowest to highest price
    U64 ask_levels = min_u64(depth_levels, orderbook->ask_count);
    for (U64 i = 0; i < ask_levels; i++) {
        PriceLevel* level = &orderbook->asks[i];
        PrintF("  %d: %d @ %d (%d orders)\n", 
               i + 1, level->total_quantity, level->price, level->order_count);
    }
    
    PrintF("BIDS:\n");
    
    // Show bids (buy orders) from highest to lowest price
    U64 bid_levels = min_u64(depth_levels, orderbook->bid_count);
    for (U64 i = 0; i < bid_levels; i++) {
        PriceLevel* level = &orderbook->bids[i];
        PrintF("  %d: %d @ %d (%d orders)\n", 
               i + 1, level->total_quantity, level->price, level->order_count);
    }
}
```

## Security and Risk Management

### Order Validation

Implement comprehensive order validation:

```c
Bool validate_order_parameters(Market* market, U64 price, U64 quantity, U8 side, U8 order_type) {
    // Basic parameter validation
    if (quantity == 0) {
        PrintF("ERROR: Zero quantity not allowed\n");
        return False;
    }
    
    if (quantity % market->lot_size != 0) {
        PrintF("ERROR: Quantity must be multiple of lot size\n");
        return False;
    }
    
    if (order_type == 0 && price % market->tick_size != 0) {
        PrintF("ERROR: Price must be multiple of tick size\n");
        return False;
    }
    
    // Market-specific limits
    const U64 MAX_ORDER_VALUE = 1000000000; // $1M limit
    const U64 MAX_ORDER_QUANTITY = 1000000; // 1M token limit
    
    if (quantity > MAX_ORDER_QUANTITY) {
        PrintF("ERROR: Order quantity exceeds maximum\n");
        return False;
    }
    
    if (order_type == 0 && price * quantity > MAX_ORDER_VALUE) {
        PrintF("ERROR: Order value exceeds maximum\n");
        return False;
    }
    
    // Price bounds validation
    if (order_type == 0) {
        U64 reference_price = market->last_trade_price > 0 ? market->last_trade_price : price;
        U64 max_deviation = reference_price / 2; // 50% price deviation limit
        
        if (price > reference_price + max_deviation || 
            price < reference_price - max_deviation) {
            PrintF("WARNING: Order price deviates significantly from market\n");
            // Could reject or require additional confirmation
        }
    }
    
    return True;
}
```

### Anti-Manipulation Measures

Protect against market manipulation:

```c
U0 detect_wash_trading(Order* order1, Order* order2) {
    // Check for wash trading patterns
    if (compare_pubkeys(order1->owner, order2->owner)) {
        PrintF("WARNING: Potential wash trading detected\n");
        // Could flag for review or block
    }
    
    // Check for coordinated trading patterns
    U64 time_diff = order1->timestamp > order2->timestamp ? 
                   order1->timestamp - order2->timestamp : 
                   order2->timestamp - order1->timestamp;
    
    if (time_diff < 1000 && order1->quantity == order2->quantity) { // Within 1 second
        PrintF("WARNING: Suspicious coordinated orders detected\n");
    }
}

U0 validate_price_movement(Market* market, U64 new_price) {
    if (market->last_trade_price == 0) return; // First trade
    
    U64 price_change = new_price > market->last_trade_price ? 
                      new_price - market->last_trade_price : 
                      market->last_trade_price - new_price;
    
    U64 change_percentage = (price_change * 100) / market->last_trade_price;
    
    // Circuit breaker for extreme price movements
    if (change_percentage > 20) { // 20% change
        PrintF("WARNING: Large price movement detected: %d%%\n", change_percentage);
        // Could trigger trading halt or additional validation
    }
}
```

This comprehensive orderbook implementation provides a robust foundation for decentralized exchange functionality with traditional order matching, advanced order types, and proper risk management features.
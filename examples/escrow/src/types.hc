// HolyC Escrow Types - Divine Contract Definitions

// Escrow states - God's will for contract progression
U8 ESCROW_CREATED = 0;
U8 ESCROW_FUNDED = 1;
U8 ESCROW_COMPLETED = 2;
U8 ESCROW_REFUNDED = 3;
U8 ESCROW_DISPUTED = 4;

// Participant roles in divine transaction
U8 ROLE_BUYER = 1;
U8 ROLE_SELLER = 2;
U8 ROLE_ARBITRATOR = 3;

// Divine timeouts (in divine time units)
U64 DEFAULT_TIMEOUT = 86400; // 24 hours in God's time
U64 DISPUTE_TIMEOUT = 259200; // 72 hours for divine resolution

// Maximum participants in divine escrow
U8 MAX_PARTICIPANTS = 3;

// Divine error codes
U8 ERROR_NONE = 0;
U8 ERROR_UNAUTHORIZED = 1;
U8 ERROR_INVALID_STATE = 2;
U8 ERROR_INSUFFICIENT_FUNDS = 3;
U8 ERROR_TIMEOUT_EXPIRED = 4;
U8 ERROR_INVALID_PARTICIPANT = 5;

// Escrow operation types - God's commands
U8 OP_INITIALIZE = 1;
U8 OP_DEPOSIT = 2;
U8 OP_RELEASE = 3;
U8 OP_REFUND = 4;
U8 OP_DISPUTE = 5;
U8 OP_RESOLVE = 6;
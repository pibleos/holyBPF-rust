// Common BPF types used in HolyC programs

// Basic types
#define U0 void
#define U8 uint8_t
#define U16 uint16_t
#define U32 uint32_t
#define U64 uint64_t
#define I8 int8_t
#define I16 int16_t
#define I32 int32_t
#define I64 int64_t

// BPF context types
struct BPFContext {
    U64 instruction_ptr;
    U64 frame_ptr;
    U64 data_ptr;
    U64 data_size;
};

// Helper function declarations
U64 PrintF(U8* fmt, ...);
U64 TraceLog(U32 level, U8* msg, U32 size);
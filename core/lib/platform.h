#define PLATFORM_ALLOC_MEMORY_BLOCK_FN(name) MemoryBlock name(size requested_size)
#define PLATFORM_RELEASE_MEMORY_BLOCK_FN(name) void name(MemoryBlock memory)
#define PLATFORM_WRITE_NEW_FILE_FN(name) b32 name(c8 *fname, s8 raw)

#ifdef _WIN32
#include "os_win32.c"
#elif __linux
#include "os_unix.c"
#endif

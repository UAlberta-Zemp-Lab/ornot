/* See LICENSE for license details. */
/* NOTE: inspired by nob: https://github.com/tsoding/nob.h */
#if defined(__linux__)
  #define OS_LINUX   1
#elif defined(__APPLE__)
  #define OS_MACOS   1
#elif defined(_WIN32)
  #define OS_WINDOWS 1
#else
  #error Unsupported Operating System
#endif

#if   defined(__clang__)
  #define COMPILER_CLANG 1
#elif defined(_MSC_VER)
  #define COMPILER_MSVC  1
#elif defined(__GNUC__)
  #define COMPILER_GCC   1
#else
  #error Unsupported Compiler
#endif

#if COMPILER_MSVC
  #if defined(_M_AMD64)
    #define ARCH_X64   1
  #elif defined(_M_ARM64)
    #define ARCH_ARM64 1
  #else
    #error Unsupported Architecture
  #endif
#else
  #if defined(__x86_64__)
    #define ARCH_X64   1
  #elif defined(__aarch64__)
    #define ARCH_ARM64 1
  #else
    #error Unsupported Architecture
  #endif
#endif

#if !defined(OS_WINDOWS)
  #define OS_WINDOWS 0
#endif
#if !defined(OS_LINUX)
  #define OS_LINUX   0
#endif
#if !defined(OS_MACOS)
  #define OS_MACOS   0
#endif
#if !defined(COMPILER_CLANG)
  #define COMPILER_CLANG 0
#endif
#if !defined(COMPILER_MSVC)
  #define COMPILER_MSVC  0
#endif
#if !defined(COMPILER_GCC)
  #define COMPILER_GCC   0
#endif
#if !defined(ARCH_X64)
  #define ARCH_X64   0
#endif
#if !defined(ARCH_ARM64)
  #define ARCH_ARM64 0
#endif

/* NOTE: glibc devs are actually buffoons who never write any real code
 * the following headers include a bunch of other headers which need this crap defined first */
#if OS_LINUX
  #ifndef _GNU_SOURCE
    #define _GNU_SOURCE
  #endif
#endif

#if   COMPILER_CLANG
  #pragma GCC diagnostic ignored "-Winitializer-overrides"
#elif COMPILER_GCC
  #pragma GCC diagnostic ignored "-Woverride-init"
#endif

#include <setjmp.h>
#include <stdarg.h>
#include <stdio.h>


#define META_NAMESPACE_UPPER "ZBP"
#define META_NAMESPACE_LOWER "zbp"

#define OUTDIR    "out"
#define OUTPUT(s) OUTDIR OS_PATH_SEPARATOR s

#if COMPILER_MSVC
  #define COMMON_FLAGS     "-nologo", "-std:c11", "-Fo:" OUTDIR "\\", "-Z7", "-Zo"
  #define DEBUG_FLAGS      "-Od", "-D_DEBUG"
  #define OPTIMIZED_FLAGS  "-O2"
  #define EXTRA_FLAGS      ""
#else
  #define COMMON_FLAGS     "-std=c11", "-pipe", "-Wall"
  #define DEBUG_FLAGS      "-O0", "-D_DEBUG", "-Wno-unused-function"
  #define OPTIMIZED_FLAGS  "-O3"
  #define EXTRA_FLAGS_BASE "-Werror", "-Wextra", "-Wno-unused-parameter", \
                           "-Wno-error=unused-function", "-fno-builtin"
  #if COMPILER_GCC
    #define EXTRA_FLAGS EXTRA_FLAGS_BASE, "-Wno-unused-variable"
  #else
    #define EXTRA_FLAGS EXTRA_FLAGS_BASE
  #endif
#endif

////////////////////////
// NOTE: Standard Types
#if COMPILER_MSVC
  typedef unsigned __int64  u64;
  typedef signed   __int64  s64;
  typedef unsigned __int32  u32;
  typedef signed   __int32  s32;
  typedef unsigned __int16  u16;
  typedef signed   __int16  s16;
  typedef unsigned __int8   u8;
  typedef signed   __int8   s8;
#else
  typedef __UINT64_TYPE__   u64;
  typedef __INT64_TYPE__    s64;
  typedef __UINT32_TYPE__   u32;
  typedef __INT32_TYPE__    s32;
  typedef __UINT16_TYPE__   u16;
  typedef __INT16_TYPE__    s16;
  typedef __UINT8_TYPE__    u8;
  typedef __INT8_TYPE__     s8;
#endif

typedef char     c8;
typedef u8       b8;
typedef u16      b16;
typedef u32      b32;
typedef _Float16 f16;
typedef float    f32;
typedef double   f64;
typedef s64      sptr;
typedef u64      uptr;

#define da_count  s32

#define U64_MAX (0xFFFFFFFFFFFFFFFFull)
#define U32_MAX (0xFFFFFFFFul)
#define U16_MAX (0xFFFFu)
#define U8_MAX  (0xFFu)

#define GB(a)   ((u64)(a) << 30ULL)
#define MB(a)   ((u64)(a) << 20ULL)
#define KB(a)   ((u64)(a) << 10ULL)

typedef struct {s64 length; u8 *data;} str8;
#define str8(s) (str8){.length = (s64)sizeof(s) - 1, .data = (u8 *)s}
#define str8_comp(s) {sizeof(s) - 1, (u8 *)s}

///////////////////
// NOTE: Intrisics

#if COMPILER_CLANG || COMPILER_GCC
  #define force_inline inline __attribute__((always_inline))
#elif COMPILER_MSVC
  #define force_inline __forceinline
#endif

#if COMPILER_MSVC || (COMPILER_CLANG && OS_WINDOWS)
  #pragma section(".rdata$", read)
  #define read_only __declspec(allocate(".rdata$"))
#elif COMPILER_CLANG && !OS_MACOS
  #define read_only __attribute__((section(".rodata")))
#else
  /* TODO(rnp): not supported on GCC, putting it in rodata causes warnings and writing to
   * it doesn't cause a fault.
   * The suggested methods on OS_MACOS give linker errors */
  #define read_only
#endif

#if COMPILER_MSVC
  #define alignas(n)     __declspec(align(n))
  #define no_return      __declspec(noreturn)

  #define print_format(f, va)

  #define debugbreak     __debugbreak
  #define unreachable()  __assume(0)
#else /* !COMPILER_MSVC */
  #define alignas(n)     __attribute__((aligned(n)))
  #define no_return      __attribute__((noreturn))

  #define print_format(f, va) __attribute__((format(printf, f, va)))

  #if ARCH_ARM64
    /* TODO(rnp)? debuggers just loop here forever and need a manual PC increment (step over) */
    #define debugbreak() asm volatile ("brk 0xf000")
  #else
    #define debugbreak() asm volatile ("int3; nop")
  #endif
  #define unreachable __builtin_unreachable
#endif /* !COMPILER_MSVC */

#if ARCH_ARM64
  #if COMPILER_MSVC
    #define cpu_yield __yield
  #else
    #define cpu_yield asm volatile ("yield")
  #endif
#elif ARCH_X64
  #define cpu_yield _mm_pause
#else
  #error Unsupported Architecture
#endif

/////////////////////////
// NOTE: Standard Macros
#define function      static
#define global        static
#define local_persist static

#ifndef asm
  #define asm __asm__
#endif

#ifndef typeof
  #define typeof __typeof__
#endif

#define countof(a) (sizeof(a) / sizeof(*a))

#define alignof       _Alignof
#define static_assert _Static_assert

#define InvalidHandle      (-1)
#define InvalidCodePath    assert(0)
#define InvalidDefaultCase default:{ assert(0); }break

#define is_aarch64 ARCH_ARM64
#define is_amd64   ARCH_X64
#define is_unix    (OS_LINUX || OS_MACOS)
#define is_w32     OS_WINDOWS
#define is_clang   COMPILER_CLANG
#define is_gcc     COMPILER_GCC
#define is_msvc    COMPILER_MSVC

#define arg_list(type, ...) (type []){__VA_ARGS__}, sizeof((type []){__VA_ARGS__}) / sizeof(type)

#define Abs(a)           ((a) < 0 ? (-a) : (a))
#define Between(x, a, b) ((x) >= (a) && (x) <= (b))
#define Clamp(x, a, b)   ((x) < (a) ? (a) : (x) > (b) ? (b) : (x))
#define Min(a, b)        ((a) < (b) ? (a) : (b))
#define Max(a, b)        ((a) > (b) ? (a) : (b))

#define IsPowerOfTwo(a)         (((a) & ((a) - 1)) == 0)
#define AlignUpPowerOfTwo(v, a) (((v) + (a) - 1) & (~((a) - 1)))

#define IsDigit(c)       (Between((c), '0', '9'))

#define swap(a, b)     do {typeof(a) __tmp = (a); (a) = (b); (b) = __tmp;} while(0)

#define DeferLoop(begin, end)          for (s32 _i_ = ((begin), 0); !_i_; _i_ += 1, (end))

#define EachBit(a, it)                 (u64 _##it = a, it = ctz_u64( _##it ); it != 64; _##it &= ~(1u << (it)), it = ctz_u64( _##it ))
#define EachElement(array, it)         (u64 it = 0; it < countof(array); it += 1)
#define EachEnumValue(type, it)        (type it = (type)0; it < type##_Count; it = (type)(it + 1))
#define EachNonZeroEnumValue(type, it) (type it = (type)1; it < type##_Count; it = (type)(it + 1))
#define EachIndex(count, it)           (u64 it = 0; it < count; it += 1)

#define SLLStackPush(list, n, next) ((n)->next = (list), (list) = (n))

#ifdef _DEBUG
  #define assert(c) do { if (!(c)) debugbreak(); } while (0)
#else  /* !_DEBUG */
  #define assert(c) ((void)(c))
#endif /* !_DEBUG */

typedef enum {
	ArenaFlag_NoChain = 1 << 0,

	ArenaFlag_CreationMask = ArenaFlag_NoChain,

	ArenaFlag_Sealed  = 1 << 31,
} ArenaFlags;

typedef struct {
	u64        reserve_size;
	u64        commit_size;
	ArenaFlags flags;

	void *optional_backing_store;

	char *name;
	char *allocation_site_file;
	s32   allocation_site_line;
} ArenaParameters;

typedef struct Arena Arena;
struct Arena {
	u64    position;
	u64    committed;
	u64    reserved;

	// NOTE(rnp): arena chain
	u64    base_position; // position relative to first arena in chain
	Arena *prev;
	Arena *current;

	u64        reserve_size;
	u64        commit_size;
	ArenaFlags flags;

	char *name;
	char *allocation_site_file;
	s32   allocation_site_line;
};
typedef struct { Arena *arena; u64 position; } Temp;

#define DA_STRUCT(kind, name) typedef struct { \
	kind     *data;     \
	da_count  count;    \
	da_count  capacity; \
} name ##List;

typedef struct {
	u8  *data;
	s32  count;
	s32  capacity;
	b32  errors;
} Stream;

typedef enum {
	NumberConversionResult_Invalid,
	NumberConversionResult_OutOfRange,
	NumberConversionResult_Success,
} NumberConversionResult;

typedef enum {
	NumberConversionKind_Invalid,
	NumberConversionKind_Integer,
	NumberConversionKind_Float,
} NumberConversionKind;

typedef struct {
	NumberConversionResult result;
	NumberConversionKind   kind;
	union {
		u64 U64;
		s64 S64;
		f64 F64;
	};
	str8 unparsed;
} NumberConversion;

global char *g_argv0;

#if OS_LINUX || OS_MACOS
  #include <dirent.h>
  #include <errno.h>
  #include <fcntl.h>
  #include <string.h>
  #include <sys/mman.h>
  #include <sys/select.h>
  #include <sys/stat.h>
  #include <sys/wait.h>
  #include <time.h>
  #include <unistd.h>

  #define W32_DECL(x)

  #if OS_LINUX
    #define OS_SHARED_LIB(s)      s ".so"
  #elif OS_MACOS
    #define OS_SHARED_LIB(s)      s ".dylib"
  #endif
  #define OS_STATIC_LIB(s)      s ".a"

  #define OS_PATH_SEPARATOR_CHAR '/'
  #define OS_PATH_SEPARATOR      "/"


#elif OS_WINDOWS

  #include <stdlib.h>
  #include <string.h>

  #define W32_DECL(x) x

  #define OS_SHARED_LIB(s)      s ".dll"
  #define OS_STATIC_LIB(s)      s ".lib"

  #define OS_PATH_SEPARATOR_CHAR '\\'
  #define OS_PATH_SEPARATOR      "\\"
#else
  #error Unsupported Platform
#endif

#if COMPILER_CLANG
  #define COMPILER     "clang"
  #define PREPROCESSOR "clang", "-E", "-P"
#elif COMPILER_MSVC
  #define COMPILER     "cl"
  #define PREPROCESSOR "cl", "/EP"
#else
  #define COMPILER     "cc"
  #define PREPROCESSOR "cc", "-E", "-P"
#endif

#if COMPILER_MSVC
  #define LINK_LIB(name)             name ".lib"
  #define OBJECT(name)               name ".obj"
  #define OUTPUT_DLL(name)           "/LD", "/Fe:", name
  #define OUTPUT_LIB(name)           "/out:" OUTPUT(name)
  #define OUTPUT_EXE(name)           "/Fe:", name
  #define COMPILER_OUTPUT            "/Fo:"
  #define STATIC_LIBRARY_BEGIN(name) "lib", "/nologo", name
#else
  #define LINK_LIB(name)             "-l" name
  #define OBJECT(name)               name ".o"
  #define OUTPUT_DLL(name)           "-fPIC", "-shared", "-o", name
  #define OUTPUT_LIB(name)           OUTPUT(name)
  #define OUTPUT_EXE(name)           "-o", name
  #define COMPILER_OUTPUT            "-o"
  #define STATIC_LIBRARY_BEGIN(name) "ar", "rc", name
#endif

#define shift(list, count) ((count)--, *(list)++)

#define cmd_append_count da_append_count
#define cmd_append(a, s, ...) da_append_count(a, s, ((char *[]){__VA_ARGS__}), \
                                              (s64)(sizeof((char *[]){__VA_ARGS__}) / sizeof(char *)))

DA_STRUCT(char *, Command);

typedef struct {
	b32   debug;
	b32   generic;
	b32   sanitize;
	b32   time;
} Options;

#define BUILD_LOG_KINDS \
	X(Error,    "\x1B[31m[ERROR]\x1B[0m    ") \
	X(Warning,  "\x1B[33m[WARNING]\x1B[0m  ") \
	X(Generate, "\x1B[32m[GENERATE]\x1B[0m ") \
	X(Info,     "\x1B[33m[INFO]\x1B[0m     ") \
	X(Command,  "\x1B[36m[COMMAND]\x1B[0m  ")
#define X(t, ...) BuildLogKind_##t,
typedef enum {BUILD_LOG_KINDS BuildLogKind_Count} BuildLogKind;
#undef X

#define OSInvalidHandleValue ((u64)-1)
typedef struct { u64 value[1]; } OSBarrier;
typedef struct { u64 value[1]; } OSHandle;
typedef struct { u64 value[1]; } OSLibrary;
typedef struct { u64 value[1]; } OSThread;
typedef struct { u64 value[1]; } OSWindow;
typedef struct { u64 value[1]; } OSW32Semaphore;

typedef u64 os_thread_entry_point_fn(void *user_context);

typedef struct {
	u64 timer_frequency;

	u32 logical_processor_count;
	u32 page_size;

	u8  path_separator_byte;
} OSSystemInfo;

function OSSystemInfo * os_system_info(void);

function void no_return os_exit(s32 code);

function void *         os_memory_reserve(u64 size);
function void           os_memory_release(void *base, u64 size);
function u32            os_memory_commit(void *base, u64 size);
function void           os_memory_uncommit(void *base, u64 size);

function u64            os_timer_count(void);

function str8           os_read_entire_file(Arena *arena, const char *file);

#define zero_struct(s) memory_clear(s, 0, sizeof(*s))
function void *
memory_clear(void *restrict p_, u8 c, u64 size)
{
	u8 *p = p_;
	while (size > 0) p[--size] = c;
	return p;
}

function void
memory_copy(void *restrict dest, void *restrict src, u64 n)
{
	u8 *s = src, *d = dest;
	for (; n; n--) *d++ = *s++;
}

/* NOTE(rnp): returns < 0 if byte is not found */
function void *
memory_scan_backwards(void *memory, u8 byte, s64 n)
{
	void *result = 0;
	u8   *s      = memory;
	if (n > 0) while (n) if (s[--n] == byte) { result = s + n; break; }
	return result;
}

function force_inline s64
round_up_to(s64 value, s64 multiple)
{
	s64 result = value;
	if (value % multiple != 0)
		result += multiple - value % multiple;
	return result;
}

typedef enum {
	ArenaAllocateFlags_NoZero = 1 << 0,
} ArenaAllocateFlags;

typedef struct {
	s64 size;
	u64 align;
	s64 count;
	ArenaAllocateFlags flags;
} ArenaAllocateInfo;

function u8 *
arena_commit(Arena *a, s64 size)
{
	Arena *current = a->current;
	assert(current->committed - current->position >= (u64)size);
	u8 *result = (u8 *)current + current->position;
	current->position += size;
	return result;
}

#define arena_create(...) arena_create_((ArenaParameters){\
	.reserve_size = MB(64),\
	.commit_size  = KB(64),\
	.flags        = 0,\
	.allocation_site_file = __FILE__,\
	.allocation_site_line = __LINE__,\
	__VA_ARGS__})

function Arena *
arena_create_(ArenaParameters ap)
{
	void *base = ap.optional_backing_store;
	if (base == 0) {
		ap.commit_size  = round_up_to(ap.commit_size,  os_system_info()->page_size);
		ap.reserve_size = round_up_to(ap.reserve_size, os_system_info()->page_size);

		base = os_memory_reserve(ap.reserve_size);
		os_memory_commit(base, ap.commit_size);
	}

	Arena *result     = base;
	result->current   = result;
	result->position  = sizeof(*result);
	result->reserved  = ap.reserve_size;
	result->committed = ap.commit_size;
	result->flags     = ap.flags;

	result->reserve_size = ap.reserve_size;
	result->commit_size  = ap.commit_size;

	result->name                 = ap.name;
	result->allocation_site_file = ap.allocation_site_file;
	result->allocation_site_line = ap.allocation_site_line;

	return result;
}

function void
arena_destroy(Arena *arena)
{
	for (Arena *a = arena->current, *prev = 0; a; a = prev) {
		prev = a->prev;
		os_memory_release(a, a->reserved);
	}
}

#define arena_alloc(a, ...)              arena_alloc_(a, (ArenaAllocateInfo){.align = 8, .count = 1, __VA_ARGS__})
#define push_array(a, t, n, ...)         (t *)arena_alloc(a, .size = sizeof(t), .align = alignof(t), .count = n, __VA_ARGS__)
#define push_array_no_zero(a, t, n, ...) (t *)arena_alloc(a, .size = sizeof(t), .align = alignof(t), .count = n, .flags = ArenaAllocateFlags_NoZero, __VA_ARGS__)
#define push_struct(a, t, ...)           push_array(a, t, 1, __VA_ARGS__)
#define push_struct_no_zero(a, t, ...)   push_array_no_zero(a, t, 1, __VA_ARGS__)

function void *
arena_alloc_(Arena *arena, ArenaAllocateInfo info)
{
	Arena *current = arena->current;
	u64 size          = info.count * info.size;
	u64 pre_position  = AlignUpPowerOfTwo(current->position, info.align);
	u64 post_position = pre_position + size;
	u64 zero_size     = Min(current->committed, post_position) - pre_position;

	if (current->reserved < post_position && (current->flags & ArenaFlag_NoChain) == 0) {
		u64 reserve_size = current->reserve_size;
		u64 commit_size  = current->commit_size;
		if (size + AlignUpPowerOfTwo(sizeof(*arena), info.align) > reserve_size) {
			reserve_size = size + AlignUpPowerOfTwo(sizeof(*arena), info.align);
			commit_size  = size + AlignUpPowerOfTwo(sizeof(*arena), info.align);
		}
		Arena *new_arena = arena_create(.reserve_size         = reserve_size,
		                                .commit_size          = commit_size,
		                                .flags                = current->flags,
		                                .allocation_site_file = current->allocation_site_file,
		                                .allocation_site_line = current->allocation_site_line,
		                                .name                 = current->name);
		zero_size = 0;

		new_arena->base_position = current->base_position + current->reserved;
		SLLStackPush(arena->current, new_arena, prev);
		current = new_arena;
		pre_position  = AlignUpPowerOfTwo(current->position, info.align);
		post_position = pre_position + size;
	}

	if (current->committed < post_position) {
		u64 commit_post = post_position + current->commit_size - 1;
		commit_post -= commit_post % current->commit_size;
		commit_post  = Min(commit_post, current->reserved);
		os_memory_commit((u8 *)current + current->committed, commit_post - current->committed);
		current->committed = commit_post;
	}

	void *result = 0;
	if (current->committed >= post_position) {
		result = (u8 *)current + pre_position;
		current->position = post_position;
		if ((info.flags & ArenaAllocateFlags_NoZero) == 0)
			result = memory_clear(result, 0, zero_size);
	}

	assert(result);

	return result;
}

function u64
arena_position(Arena *arena)
{
	Arena *current = arena->current;
	u64 result = current->base_position + current->position;
	return result;
}

function void
arena_pop_to(Arena *arena, u64 position)
{
	position = Max(position, sizeof(*arena));
	Arena *current = arena->current;
	for (Arena *prev = 0; current->base_position >= position; current = prev) {
		prev = current->prev;
		os_memory_release(current, current->reserved);
	}
	arena->current = current;
	u64 new_position = position - current->base_position;
	assert(new_position <= current->position);
	current->position = new_position;
}

function void
arena_pop(Arena *arena, u64 size)
{
	u64 old_position = arena_position(arena);
	u64 new_position = old_position;
	if (size < old_position)
		new_position = old_position - size;
	arena_pop_to(arena, new_position);
}

function void
arena_clear(Arena *arena)
{
	arena_pop_to(arena, 0);
}

function void
arena_pre_align(Arena *arena, u64 align)
{
	assert(IsPowerOfTwo(align));
	Arena *current = arena->current;
	u8 *start = (u8 *)current + current->position;
	u8 *desired_start = (u8 *)AlignUpPowerOfTwo((u64)start, align);
	current->position += (u64)(desired_start - start);
}

function Temp
temp_begin(Arena *arena)
{
	Temp result = {.arena = arena, .position = arena_position(arena)};
	return result;
}

function void
temp_end(Temp t)
{
	arena_pop_to(t.arena, t.position);
}

enum { DA_INITIAL_CAP = 16 };

#define da_index(it, s) ((it) - (s)->data)
#define da_reserve(a, s, n) \
  (s)->data = da_reserve_((a), (s)->data, &(s)->capacity, (s)->count + n, \
                          _Alignof(typeof(*(s)->data)), sizeof(*(s)->data))

#define da_append_count(a, s, items, item_count) do { \
	da_reserve((a), (s), (item_count)); \
	memory_copy((s)->data + (s)->count, (items), sizeof(*(items)) * (u64)(item_count)); \
	(s)->count += (item_count); \
} while (0)

#define da_push(a, s) \
  ((typeof((s)->data))memory_clear((s)->count == (s)->capacity  \
    ? da_reserve(a, s, 1),      \
      (s)->data + (s)->count++  \
    : (s)->data + (s)->count++, 0, sizeof(*(s)->data)))

/* NOTE(rnp): handles both 0 initialized DAs and DAs that need to be moved (they started
 * on the stack or someone allocated something in the middle of the arena during usage) */
function void *
da_reserve_(Arena *a, void *data, da_count *capacity, da_count needed, u64 align, s64 size)
{
	da_count cap = *capacity;
	if (!cap) cap = DA_INITIAL_CAP;
	while (cap < needed) cap *= 2;

	Arena *current = a->current;
	u64 needed_size = cap * size;
	u64 old_size    = *capacity * size;
	b32 can_extend  = data && (u8 *)current + current->position == (u8 *)data + old_size &&
	                  (current->reserved - current->position) >= (needed_size - old_size);
	b32 needs_copy  = data && !can_extend;

	u64 alloc_cap = cap;
	if (can_extend) alloc_cap -= *capacity;

	void *new = arena_alloc(a, .size = size, .align = align, .count = alloc_cap);

	if (needs_copy)
		memory_copy(new, data, (u64)(*capacity * size));

	if (!can_extend)
		data = new;

	*capacity = cap;

	return data;
}

function str8
str8_from_c_str(char *c_str)
{
	str8 result = {.data = (u8 *)c_str};
	if (c_str) while (*c_str) c_str++;
	result.length = (u8 *)c_str - result.data;
	return result;
}

function b32
str8_equal(str8 a, str8 b)
{
	b32 result = a.length == b.length;
	for (s64 i = 0; result && i < a.length; i++)
		result = a.data[i] == b.data[i];
	return result;
}

function b32
str8_contains(str8 s, u8 byte)
{
	b32 result = 0;
	for (s64 i = 0 ; !result && i < s.length; i++)
		result |= s.data[i] == byte;
	return result;
}

/* NOTE(rnp): returns < 0 if byte is not found */
function s64
str8_scan_backwards(str8 s, u8 byte)
{
	u8 *found = memory_scan_backwards(s.data, byte, s.length);
	s64 result = found - s.data;
	return result;
}

function str8
str8_cut_head(str8 s, s64 cut)
{
	str8 result = s;
	if (cut > 0) {
		result.data   += cut;
		result.length -= cut;
	}
	return result;
}

function str8
str8_alloc(Arena *a, s64 length)
{
	str8 result = {.data = push_array(a, u8, length), .length = length};
	return result;
}

#define push_str8_from_parts(a, j, ...) push_str8_from_parts_((a), (j), arg_list(str8, __VA_ARGS__))
function str8
push_str8_from_parts_(Arena *arena, str8 joiner, str8 *parts, s64 count)
{
	s64 length = joiner.length * (count - 1);
	for (s64 i = 0; i < count; i++)
		length += parts[i].length;

	str8 result = {.length = length, .data = push_array_no_zero(arena, u8, length + 1)};

	s64 offset = 0;
	for (s64 i = 0; i < count; i++) {
		if (i != 0) {
			memory_copy(result.data + offset, joiner.data, (u64)joiner.length);
			offset += joiner.length;
		}
		memory_copy(result.data + offset, parts[i].data, (u64)parts[i].length);
		offset += parts[i].length;
	}
	result.data[result.length] = 0;

	return result;
}

function str8
push_str8(Arena *a, str8 str)
{
	str8 result    = str8_alloc(a, str.length + 1);
	result.length -= 1;
	memory_copy(result.data, str.data, (u64)result.length);
	return result;
}

read_only global u8 meta_integer_print_digits[] = {16, 8, 4, 2};
read_only global str8 meta_integer_print_c_suffix[] = {
	str8_comp("ULL"),
	str8_comp("UL"),
	str8_comp("U"),
	str8_comp("U"),
};
read_only global str8 meta_integer_print_matlab_kind[] = {
	str8_comp("uint64"),
	str8_comp("uint32"),
	str8_comp("uint16"),
	str8_comp("uint8"),
};

function u64 integer_width_index(u64 n)
{
	if (n <= 0x000000FFul) return 3;
	if (n <= 0x0000FFFFul) return 2;
	if (n <= 0xFFFFFFFFul) return 1;
	return 0;
}

function NumberConversion
integer_from_str8(str8 raw)
{
	read_only local_persist alignas(64) s8 lut[64] = {
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, -1, -1, -1, -1, -1, -1,
		-1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1,
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
		-1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	};

	NumberConversion result = {.unparsed = raw};

	s64 i     = 0;
	s64 scale = 1;
	if (raw.length > 0 && raw.data[0] == '-') {
		scale = -1;
		i     =  1;
	}

	b32 hex = 0;
	if (raw.length - i > 2 && raw.data[i] == '0' && (raw.data[1] == 'x' || raw.data[1] == 'X')) {
		hex = 1;
		i += 2;
	}

	#define integer_conversion_body(radix, clamp) do {\
		for (; i < raw.length; i++) {\
			s64 value = lut[Min((u8)(raw.data[i] - (u8)'0'), clamp)];\
			if (value >= 0) {\
				if (result.U64 > (U64_MAX - (u64)value) / radix) {\
					result.result = NumberConversionResult_OutOfRange;\
					result.U64    = U64_MAX;\
					return result;\
				} else {\
					result.U64 = radix * result.U64 + (u64)value;\
				}\
			} else {\
				break;\
			}\
		}\
	} while (0)

	if (hex) integer_conversion_body(16u, 63u);
	else     integer_conversion_body(10u, 15u);

	#undef integer_conversion_body

	result.unparsed = (str8){.length = raw.length - i, .data = raw.data + i};
	result.result   = i > 0 ? NumberConversionResult_Success : NumberConversionResult_Invalid;
	result.kind     = NumberConversionKind_Integer;
	if (scale < 0) result.U64 = 0 - result.U64;

	return result;
}

function NumberConversion
number_from_str8(str8 s)
{
	NumberConversion result  = {.unparsed = s};
	NumberConversion integer = integer_from_str8(s);
	if (integer.result == NumberConversionResult_Success) {
		if (integer.unparsed.length != 0 && integer.unparsed.data[0] == '.') {
			s = integer.unparsed;
			s.data++;
			s.length--;

			while (s.length > 0 && s.data[s.length - 1] == '0') s.length--;

			NumberConversion fractional = integer_from_str8(s);
			if (fractional.result == NumberConversionResult_Success || s.length == 0) {
				result.F64 = (f64)fractional.U64;

				u64 divisor = (u64)(fractional.unparsed.data - s.data);
				while (divisor > 0) { result.F64 /= 10.0; divisor--; }

				result.F64 += (f64)integer.S64;

				result.result   = NumberConversionResult_Success;
				result.kind     = NumberConversionKind_Float;
				result.unparsed = fractional.unparsed;
			}
		} else {
			result = integer;
		}
	}
	return result;
}

function void
build_log_base(BuildLogKind kind, char *format, va_list args)
{
	#define X(t, pre) pre,
	read_only local_persist char *prefixes[BuildLogKind_Count + 1] = {BUILD_LOG_KINDS "[INVALID] "};
	#undef X
	FILE *out = kind == BuildLogKind_Error? stderr : stdout;
	fputs(prefixes[Min(kind, BuildLogKind_Count)], out);
	vfprintf(out, format, args);
	fputc('\n', out);
}

#define build_log_failure(format, ...) build_log(BuildLogKind_Error, \
                                                 "failed to build: " format, ##__VA_ARGS__)
#define build_log_error(...)    build_log(BuildLogKind_Error,    ##__VA_ARGS__)
#define build_log_generate(...) build_log(BuildLogKind_Generate, ##__VA_ARGS__)
#define build_log_info(...)     build_log(BuildLogKind_Info,     ##__VA_ARGS__)
#define build_log_command(...)  build_log(BuildLogKind_Command,  ##__VA_ARGS__)
#define build_log_warning(...)  build_log(BuildLogKind_Warning,  ##__VA_ARGS__)

function print_format(2, 3) void
build_log(BuildLogKind kind, char *format, ...)
{
	va_list ap;
	va_start(ap, format);
	build_log_base(kind, format, ap);
	va_end(ap);
}

#define build_fatal(fmt, ...) build_fatal_("%s: " fmt, __FUNCTION__, ##__VA_ARGS__)
function no_return print_format(1, 2) void
build_fatal_(char *format, ...)
{
	va_list ap;
	va_start(ap, format);
	build_log_base(BuildLogKind_Error, format, ap);
	va_end(ap);
	os_exit(1);
}

function str8
stream_to_str8(Stream *s)
{
	str8 result = str8("");
	if (!s->errors) result = (str8){.length = s->count, .data = s->data};
	return result;
}

function void
stream_append(Stream *s, void *data, s64 count)
{
	s->errors |= (s->capacity - s->count) < count;
	if (!s->errors) {
		memory_copy(s->data + s->count, data, (u64)count);
		s->count += count;
	}
}

function void
stream_append_byte(Stream *s, u8 b)
{
	stream_append(s, &b, 1);
}

function void
stream_pad(Stream *s, u8 b, s32 n)
{
	while (n > 0) stream_append_byte(s, b), n--;
}

function void
stream_append_str8(Stream *s, str8 str)
{
	stream_append(s, str.data, str.length);
}

#define stream_append_str8s(s, ...) stream_append_str8s_(s, arg_list(str8, ##__VA_ARGS__))
function void
stream_append_str8s_(Stream *s, str8 *strs, s64 count)
{
	for (s64 i = 0; i < count; i++)
		stream_append(s, strs[i].data, strs[i].length);
}

function void
stream_push_command(Stream *s, CommandList *c)
{
	if (!s->errors) {
		for (s64 i = 0; i < c->count; i++) {
			str8 item = str8_from_c_str(c->data[i]);
			if (item.length) {
				b32 escape = str8_contains(item, ' ') || str8_contains(item, '"');
				if (escape) stream_append_byte(s, '\'');
				stream_append_str8(s, item);
				if (escape) stream_append_byte(s, '\'');
				if (i != c->count - 1) stream_append_byte(s, ' ');
			}
		}
	}
}

function void
stream_append_u64_width(Stream *s, u64 n, u64 min_width)
{
	u8 tmp[64];
	u8 *end = tmp + sizeof(tmp);
	u8 *beg = end;
	min_width = Min(sizeof(tmp), min_width);

	do { *--beg = (u8)('0' + (n % 10)); } while (n /= 10);
	while (end - beg > 0 && (u64)(end - beg) < min_width)
		*--beg = '0';

	stream_append(s, beg, end - beg);
}

function void
stream_append_u64(Stream *s, u64 n)
{
	stream_append_u64_width(s, n, 0);
}

function void
stream_append_hex_u64_width(Stream *s, u64 n, s64 width)
{
	assert(width <= 16);
	if (!s->errors) {
		u8  buf[16];
		u8 *end = buf + sizeof(buf);
		u8 *beg = end;
		while (n) {
			*--beg = (u8)"0123456789abcdef"[n & 0x0F];
			n >>= 4;
		}
		while (end - beg < width)
			*--beg = '0';
		stream_append(s, beg, end - beg);
	}
}

function void
stream_append_hex_u64(Stream *s, u64 n)
{
	stream_append_hex_u64_width(s, n, 2);
}

function void
stream_append_s64(Stream *s, s64 n)
{
	if (n < 0) {
		stream_append_byte(s, '-');
		n *= -1;
	}
	stream_append_u64(s, (u64)n);
}

function void
stream_append_f64(Stream *s, f64 f, u64 prec)
{
	if (f < 0) {
		stream_append_byte(s, '-');
		f *= -1;
	}

	/* NOTE: round last digit */
	f += 0.5f / (f64)prec;

	if (f >= (f64)(-1UL >> 1)) {
		stream_append_str8(s, str8("inf"));
	} else {
		u64 integral = (u64)f;
		u64 fraction = (u64)((f - (f64)integral) * (f64)prec);
		stream_append_u64(s, integral);
		stream_append_byte(s, '.');
		for (u64 i = prec / 10; i > 1; i /= 10) {
			if (i > fraction)
				stream_append_byte(s, '0');
		}
		stream_append_u64(s, fraction);
	}
}

function Stream
arena_stream(Arena *a)
{
	Arena *current  = a->current;
	Stream result   = {0};
	result.data     = (u8 *)current + current->position;
	result.capacity = (s32)(current->committed - current->position);
	return result;
}

function str8
arena_stream_commit(Arena *a, Stream *s)
{
	Arena *current = a->current;
	assert(s->data == (u8 *)current + current->position);
	str8 result = stream_to_str8(s);
	arena_commit(a, result.length);
	return result;
}

function str8
arena_stream_commit_zero(Arena *a, Stream *s)
{
	b32 error = s->errors || s->count == s->capacity;
	if (!error)
		s->data[s->count] = 0;
	str8 result = stream_to_str8(s);
	arena_commit(a, result.length + 1);
	return result;
}

function str8
arena_stream_commit_and_reset(Arena *arena, Stream *s)
{
	str8 result = arena_stream_commit_zero(arena, s);
	*s = arena_stream(arena);
	return result;
}

function print_format(1, 2) char *
temp_sprintf(char *format, ...)
{
	local_persist char buffer[4096];
	va_list ap;
	va_start(ap, format);
	vsnprintf(buffer, countof(buffer), format, ap);
	va_end(ap);
	return buffer;
}

#if OS_LINUX || OS_MACOS

typedef struct {
	OSSystemInfo system_info;
} OS_LinuxContext;
global OS_LinuxContext os_linux_context;

function no_return void
os_exit(s32 code)
{
	_exit(code);
	unreachable();
}

function b32
os_write_file(sptr file, str8 raw)
{
	while (raw.length > 0) {
		s64 r = write((s32)file, raw.data, (u64)raw.length);
		if (r < 0) return 0;
		raw = str8_cut_head(raw, r);
	}
	return 1;
}

function no_return void
os_fatal(str8 msg)
{
	os_write_file(STDERR_FILENO, msg);
	os_exit(1);
	unreachable();
}

function OSSystemInfo *
os_system_info(void)
{
	return &os_linux_context.system_info;
}

function void
os_common_init(void)
{
	os_linux_context.system_info.logical_processor_count = (u32)sysconf(_SC_NPROCESSORS_ONLN);
	os_linux_context.system_info.page_size               = (u32)getpagesize();
}

function u64
os_timer_frequency(void)
{
	return 1000000000ULL;
}

function u64
os_timer_counter(void)
{
	struct timespec time = {0};
	clock_gettime(CLOCK_MONOTONIC, &time);
	u64 result = (u64)time.tv_sec * 1000000000ULL + (u64)time.tv_nsec;
	return result;
}

function b32
os_rename_file(char *name, char *new)
{
	b32 result = rename(name, new) != -1;
	return result;
}

function b32
os_remove_file(char *name)
{
	b32 result = remove(name) != -1;
	return result;
}

function b32
os_write_new_file(char *fname, str8 raw)
{
	b32 result = 0;
	s32 fd = open(fname, O_WRONLY|O_TRUNC|O_CREAT, 0600);
	if (fd != InvalidHandle) {
		result = os_write_file(fd, raw);
		close(fd);
	}
	return result;
}

function void *
os_memory_reserve(u64 size)
{
	void *result = mmap(0, size, PROT_NONE, MAP_ANONYMOUS|MAP_PRIVATE, -1, 0);
	if (result == MAP_FAILED)
		result = 0;
	return result;
}

function void
os_memory_release(void *base, u64 size)
{
	munmap(base, size);
}

function b32
os_memory_commit(void *base, u64 size)
{
	mprotect(base, size, PROT_READ|PROT_WRITE);
	return 1;
}

function void
os_memory_uncommit(void *base, u64 size)
{
	madvise(base, size, MADV_DONTNEED);
	mprotect(base, size, PROT_NONE);
}

function str8
os_read_entire_file(Arena *arena, const char *file)
{
	str8 result = {0};
	struct stat sb;
	s32 fd = open(file, O_RDONLY);
	if (fd >= 0 && fstat(fd, &sb) >= 0) {
		result.data = push_array(arena, u8, sb.st_size);
		do {
			s64 rlen = read(fd, result.data + result.length, (u64)(sb.st_size - result.length));
			if (rlen > 0) result.length += rlen;
		} while (result.length != sb.st_size && errno != EINTR);
		if (result.length != sb.st_size) {
			arena_pop(arena, sb.st_size);
			zero_struct(&result);
		}
	}
	if (fd >= 0) close(fd);

	return result;
}

/* NOTE: complete garbage because there is no standarized copyfile() in POSix */
function b32
os_copy_file(char *name, char *new)
{
	b32 result = 0;
	struct stat sb;
	if (stat(name, &sb) == 0) {
		s32 fd_old = open(name, O_RDONLY);
		s32 fd_new = open(new,  O_WRONLY|O_CREAT, sb.st_mode);
		if (fd_old >= 0 && fd_new >= 0) {
			u8 buf[4096];
			s64 copied = 0;
			while (copied != sb.st_size) {
				s64 r = read(fd_old, buf, countof(buf));
				if (r < 0) break;
				s64 w = write(fd_new, buf, (u64)r);
				if (w < 0) break;
				copied += w;
			}
			result = copied == sb.st_size;
		}
		if (fd_old != -1) close(fd_old);
		if (fd_new != -1) close(fd_new);
	}
	return result;
}

function b32
os_file_exists(char *path)
{
	struct stat st;
	b32 result = stat(path, &st) == 0;
	return result;
}

function void
os_make_directory(char *name)
{
	mkdir(name, 0770);
}

#define os_remove_directory(f) os_remove_directory_(AT_FDCWD, (f))
function b32
os_remove_directory_(s32 base_fd, char *name)
{
	/* POSix sucks */
	#ifndef DT_DIR
	enum {DT_DIR = 4, DT_REG = 8, DT_LNK = 10};
	#endif

	s32 dir_fd = openat(base_fd, name, O_DIRECTORY);
	b32 result = dir_fd != -1 || errno == ENOTDIR || errno == ENOENT;
	DIR *dir;
	if (dir_fd != -1 && (dir = fdopendir(dir_fd))) {
		struct dirent *dp;
		while ((dp = readdir(dir))) {
			switch (dp->d_type) {
			case DT_LNK:
			case DT_REG:
			{
				unlinkat(dir_fd, dp->d_name, 0);
			}break;
			case DT_DIR:{
				str8 dir_name = str8_from_c_str(dp->d_name);
				if (!str8_equal(str8("."), dir_name) && !str8_equal(str8(".."), dir_name))
					os_remove_directory_(dir_fd, dp->d_name);
			}break;
			default:{
				build_log_warning("\"%s\": unknown directory entry kind: %d", dp->d_name, dp->d_type);
			}break;
			}
		}

		closedir(dir);
		result = unlinkat(base_fd, name, AT_REMOVEDIR) == 0;
	}
	return result;
}

function u64
os_get_filetime(char *file)
{
	struct stat sb;
	u64 result = (u64)-1;
	if (stat(file, &sb) != -1) {
		#if OS_MACOS
			result = (u64)sb.st_mtimespec.tv_sec;
		#else
			result = (u64)sb.st_mtim.tv_sec;
		#endif
	}
	return result;
}

function sptr
os_spawn_process(CommandList *cmd, Stream sb)
{
	pid_t result = fork();
	switch (result) {
	case -1: build_fatal("failed to fork command: %s: %s", cmd->data[0], strerror(errno)); break;
	case  0: {
		if (execvp(cmd->data[0], cmd->data) == -1)
			build_fatal("failed to exec command: %s: %s", cmd->data[0], strerror(errno));
		unreachable();
	} break;
	}
	return (sptr)result;
}

function b32
os_wait_close_process(sptr handle)
{
	b32 result = 0;
	for (;;) {
		s32   status;
		sptr wait_pid = (sptr)waitpid((s32)handle, &status, 0);
		if (wait_pid == -1)
			build_fatal("failed to wait on child process: %s", strerror(errno));
		if (wait_pid == handle) {
			if (WIFEXITED(status)) {
				status = WEXITSTATUS(status);
				/* TODO(rnp): logging */
				result = status == 0;
				break;
			}
			if (WIFSIGNALED(status)) {
				/* TODO(rnp): logging */
				result = 0;
				break;
			}
		} else {
			/* TODO(rnp): handle multiple children */
			InvalidCodePath;
		}
	}
	return result;
}

#elif OS_WINDOWS

enum {
	MOVEFILE_REPLACE_EXISTING = 0x01,

	FILE_ATTRIBUTE_DIRECTORY  = 0x10,

	FILE_FLAG_BACKUP_SEMANTICS = 0x02000000,

	ERROR_FILE_NOT_FOUND = 0x02,
	ERROR_PATH_NOT_FOUND = 0x03,

	GENERIC_WRITE = 0x40000000,
	GENERIC_READ  = 0x80000000,

	CREATE_ALWAYS = 2,
	OPEN_EXISTING = 3,

	PAGE_READWRITE = 0x04,
	MEM_COMMIT     = 0x1000,
	MEM_RESERVE    = 0x2000,
	MEM_DECOMMIT   = 0x4000,
	MEM_RELEASE    = 0x8000,

	STD_INPUT_HANDLE  = -10,
	STD_OUTPUT_HANDLE = -11,
	STD_ERROR_HANDLE  = -12,
};

typedef struct {
	u64          timer_frequency;
	OSSystemInfo system_info;
} OS_W32Context;
global OS_W32Context os_w32_context;

#pragma pack(push, 1)
typedef struct {
  u32 file_attributes;
  u64 creation_time;
  u64 last_access_time;
  u64 last_write_time;
  u64 file_size;
  u64 reserved;
  c8  file_name[260];
  c8  alternate_file_name[14];
  u32 file_type;
  u32 creator_type;
  u16 finder_flag;
} w32_find_data;
#pragma pack(pop)

typedef struct {
	u16  architecture;
	u16  _pad1;
	u32  page_size;
	s64  minimum_application_address;
	s64  maximum_application_address;
	u64  active_processor_mask;
	u32  number_of_processors;
	u32  processor_type;
	u32  allocation_granularity;
	u16  processor_level;
	u16  processor_revision;
} w32_system_info;

#define W32(r) __declspec(dllimport) r __stdcall
W32(b32)    CloseHandle(sptr);
W32(b32)    CopyFileA(c8 *, c8 *, b32);
W32(b32)    CreateDirectoryA(c8 *, void *);
W32(sptr)   CreateFileA(c8 *, u32, u32, void *, u32, u32, void *);
W32(b32)    CreateProcessA(u8 *, u8 *, sptr, sptr, b32, u32, sptr, u8 *, sptr, sptr);
W32(b32)    DeleteFileA(c8 *);
W32(void)   ExitProcess(s32);
W32(b32)    FindClose(sptr);
W32(sptr)   FindFirstFileA(c8 *, w32_find_data *);
W32(b32)    FindNextFileA(sptr, w32_find_data *);
W32(b32)    GetExitCodeProcess(sptr, u32 *);
W32(s32)    GetFileAttributesA(c8 *);
W32(b32)    GetFileInformationByHandle(sptr, void *);
W32(b32)    GetFileTime(sptr, sptr, sptr, sptr);
W32(s32)    GetLastError(void);
W32(sptr)   GetStdHandle(s32);
W32(void)   GetSystemInfo(w32_system_info *);
W32(b32)    MoveFileExA(c8 *, c8 *, u32);
W32(b32)    QueryPerformanceCounter(u64 *);
W32(b32)    QueryPerformanceFrequency(u64 *);
W32(b32)    ReadFile(sptr, u8 *, s32, s32 *, void *);
W32(b32)    RemoveDirectoryA(c8 *);
W32(u32)    WaitForSingleObject(sptr, u32);
W32(b32)    WriteFile(sptr, u8 *, s32, s32 *, void *);
W32(void *) VirtualAlloc(u8 *, s64, u32, u32);
W32(b32)    VirtualFree(void *, u64, u32);

#pragma pack(push, 1)
typedef struct {
	u32 dwFileAttributes;
	u64 ftCreationTime;
	u64 ftLastAccessTime;
	u64 ftLastWriteTime;
	u32 dwVolumeSerialNumber;
	u32 nFileSizeHigh;
	u32 nFileSizeLow;
	u32 nNumberOfLinks;
	u32 nFileIndexHigh;
	u32 nFileIndexLow;
} w32_file_info;
#pragma pack(pop)

function no_return void
os_exit(s32 code)
{
	ExitProcess(1);
	unreachable();
}

function b32
os_write_file(sptr file, str8 raw)
{
	s32 wlen = 0;
	if (raw.length > 0 && raw.length <= U32_MAX) WriteFile(file, raw.data, (s32)raw.length, &wlen, 0);
	return raw.length == wlen;
}

function no_return void
os_fatal(str8 msg)
{
	os_write_file(GetStdHandle(STD_ERROR_HANDLE), msg);
	os_exit(1);
	unreachable();
}

function OSSystemInfo *
os_system_info(void)
{
	return &os_w32_context.system_info;
}

function void
os_common_init(void)
{
	w32_system_info info = {0};
	GetSystemInfo(&info);

  os_w32_context.system_info.page_size = info.page_size;
	os_w32_context.system_info.logical_processor_count = info.number_of_processors;

	QueryPerformanceFrequency(&os_w32_context.timer_frequency);
}

function u64
os_timer_frequency(void)
{
	u64 result = os_w32_context.timer_frequency;
	return result;
}

function u64
os_timer_counter(void)
{
	u64 result;
	QueryPerformanceCounter(&result);
	return result;
}

function b32
os_file_exists(char *path)
{
	b32 result = GetFileAttributesA(path) != -1;
	return result;
}

function void
os_make_directory(char *name)
{
	CreateDirectoryA(name, 0);
}

function b32
os_remove_directory(char *name)
{
	w32_find_data find_data[1];
	char *search = temp_sprintf(".\\%s\\*", name);
	sptr  handle = FindFirstFileA(search, find_data);
	b32   result = 1;
	if (handle != InvalidHandle) {
		do {
			str8 file_name = str8_from_c_str(find_data->file_name);
			if (!str8_equal(str8("."), file_name) && !str8_equal(str8(".."), file_name)) {
				char *full_path = temp_sprintf("%s" OS_PATH_SEPARATOR "%s", name, find_data->file_name);
				if (find_data->file_attributes & FILE_ATTRIBUTE_DIRECTORY) {
					char *wow_w32_is_even_worse_than_POSix = strdup(full_path);
					os_remove_directory(wow_w32_is_even_worse_than_POSix);
					free(wow_w32_is_even_worse_than_POSix);
				} else {
					DeleteFileA(full_path);
				}
			}
		} while (FindNextFileA(handle, find_data));
		FindClose(handle);
	} else {
		s32 error = GetLastError();
		result = error == ERROR_FILE_NOT_FOUND || error == ERROR_PATH_NOT_FOUND;
	}
	RemoveDirectoryA(name);
	return result;
}

function b32
os_rename_file(char *name, char *new)
{
	b32 result = MoveFileExA(name, new, MOVEFILE_REPLACE_EXISTING) != 0;
	return result;
}

function b32
os_copy_file(char *name, char *new)
{
	return CopyFileA(name, new, 0);
}

function b32
os_remove_file(char *name)
{
	b32 result = DeleteFileA(name);
	return result;
}

function void *
os_memory_reserve(u64 size)
{
	void *result = VirtualAlloc(0, size, MEM_RESERVE, PAGE_READWRITE);
	return result;
}

function void
os_memory_release(void *base, u64 size)
{
	// NOTE(rnp): size must be 0 on w32, no partial releasing
	VirtualFree(base, 0, MEM_RELEASE);
}

function b32
os_memory_commit(void *base, u64 size)
{
	b32 result = VirtualAlloc(base, size, MEM_COMMIT, PAGE_READWRITE) != 0;
	return result;
}

function void
os_memory_uncommit(void *base, u64 size)
{
	VirtualFree(base, size, MEM_DECOMMIT);
}

function str8
os_read_entire_file(Arena *arena, const char *file)
{
	str8 result = {0};
	w32_file_info fileinfo;
	sptr h = CreateFileA((c8 *)file, GENERIC_READ, 0, 0, OPEN_EXISTING, 0, 0);
	if (h >= 0 && GetFileInformationByHandle(h, &fileinfo)) {
		s64 filesize  = (s64)fileinfo.nFileSizeHigh << 32;
		filesize     |= (s64)fileinfo.nFileSizeLow;
		result.data   = push_array(arena, u8, filesize);
		result.length = filesize;
		s32 rlen;
		if (!ReadFile(h, result.data, (s32)filesize, &rlen, 0) || rlen != filesize) {
			arena_pop(arena, filesize);
			zero_struct(&result);
		}
	}
	if (h >= 0) CloseHandle(h);

	return result;
}

function b32
os_write_new_file(char *fname, str8 raw)
{
	b32 result = 0;
	sptr h = CreateFileA(fname, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, 0, 0);
	if (h >= 0) {
		while (raw.length > 0) {
			str8 chunk = raw;
			chunk.length = Min(chunk.length, (s64)GB(2));
			result       = os_write_file(h, chunk);
			if (!result) break;
			raw = str8_cut_head(raw, chunk.length);
		}
		CloseHandle(h);
	}
	return result;
}

function u64
os_get_filetime(char *file)
{
	u64 result = (u64)-1;
	sptr h = CreateFileA(file, 0, 0, 0, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);
	if (h != InvalidHandle) {
		union { struct { u32 low, high; }; u64 U64; } w32_filetime;
		GetFileTime(h, 0, 0, (sptr)&w32_filetime);
		result = w32_filetime.U64;
		CloseHandle(h);
	}
	return result;
}

function sptr
os_spawn_process(CommandList *cmd, Stream sb)
{
	struct {
		u32 cb;
		u8 *reserved, *desktop, *title;
		u32 x, y, x_size, y_size, x_count_chars, y_count_chars;
		u32 fill_attr, flags;
		u16 show_window, reserved_2;
		u8 *reserved_3;
		sptr std_input, std_output, std_error;
	} w32_startup_info = {
		.cb = sizeof(w32_startup_info),
		.flags = 0x100,
		.std_input  = GetStdHandle(STD_INPUT_HANDLE),
		.std_output = GetStdHandle(STD_OUTPUT_HANDLE),
		.std_error  = GetStdHandle(STD_ERROR_HANDLE),
	};

	struct {
		sptr phandle, thandle;
		u32  pid, tid;
	} w32_process_info = {0};

	/* TODO(rnp): warn if we need to clamp last string */
	sb.count = Min(sb.count, (s32)(KB(32) - 1));
	if (sb.count< sb.capacity) sb.data[sb.count]     = 0;
	else                       sb.data[sb.count - 1] = 0;

	sptr result = InvalidHandle;
	if (CreateProcessA(0, sb.data, 0, 0, 1, 0, 0, 0, (sptr)&w32_startup_info,
	                   (sptr)&w32_process_info))
	{
		CloseHandle(w32_process_info.thandle);
		result = w32_process_info.phandle;
	}
	return result;
}

function b32
os_wait_close_process(sptr handle)
{
	b32 result = WaitForSingleObject(handle, (u32)-1) != 0xFFFFFFFFUL;
	if (result) {
		u32 status;
		GetExitCodeProcess(handle, &status);
		result = status == 0;
	}
	CloseHandle(handle);
	return result;
}

#endif

#define needs_rebuild(b, ...) needs_rebuild_(b, ((char *[]){__VA_ARGS__}), \
                                             (sizeof((char *[]){__VA_ARGS__}) / sizeof(char *)))
function b32
needs_rebuild_(char *binary, char *deps[], s64 deps_count)
{
	u64 binary_filetime = os_get_filetime(binary);
	u64 argv0_filetime  = os_get_filetime(g_argv0);
	b32 result = (binary_filetime == (u64)-1) | (argv0_filetime > binary_filetime);
	for (s64 i = 0; i < deps_count; i++) {
		u64 filetime = os_get_filetime(deps[i]);
		result |= (filetime == (u64)-1) | (filetime > binary_filetime);
	}
	return result;
}

function b32
run_synchronous(Arena *a, CommandList *command)
{
	Stream sb = arena_stream(a);
	stream_push_command(&sb, command);
	build_log_command("%.*s", (s32)sb.count, sb.data);
	return os_wait_close_process(os_spawn_process(command, sb));
}

function CommandList
cmd_base(Arena *a, Options *o)
{
	CommandList result = {0};
	cmd_append(a, &result, COMPILER);

	if (!is_msvc) {
		/* TODO(rnp): support cross compiling with clang */
		if (!o->generic)     cmd_append(a, &result, "-march=native");
		else if (is_amd64)   cmd_append(a, &result, "-march=x86-64-v3");
		else if (is_aarch64) cmd_append(a, &result, "-march=armv8");
	}

	cmd_append(a, &result, COMMON_FLAGS);
	if (o->debug) cmd_append(a, &result, DEBUG_FLAGS);
	else          cmd_append(a, &result, OPTIMIZED_FLAGS);

	/* NOTE: ancient gcc bug: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=80454 */
	if (is_gcc) cmd_append(a, &result, "-Wno-missing-braces");

	if (!is_msvc) cmd_append(a, &result, "-fms-extensions");

	if (o->debug && is_unix) cmd_append(a, &result, "-gdwarf-4");

	/* NOTE(rnp): need to avoid w32-gcc for ci */
	b32 sanitize = o->sanitize && !is_msvc && !(is_w32 && is_gcc);
	if (sanitize) cmd_append(a, &result, "-fsanitize=address,undefined");
	if (!sanitize && o->sanitize) build_log_warning("santizers not supported with this compiler");

	return result;
}

function void
check_rebuild_self(Arena *arena, s32 argc, char *argv[])
{
	char *binary = shift(argv, argc);
	if (needs_rebuild(binary, __FILE__)) {
		Stream name_buffer = arena_stream(arena);
		stream_append_str8s(&name_buffer, str8_from_c_str(binary), str8(".old"));
		char *old_name = (char *)arena_stream_commit_zero(arena, &name_buffer).data;

		if (!os_rename_file(binary, old_name))
			build_fatal("failed to move: %s -> %s", binary, old_name);

		Options options = {0};
		CommandList c = cmd_base(arena, &options);
		cmd_append(arena, &c, EXTRA_FLAGS);
		if (!is_msvc) cmd_append(arena, &c, "-Wno-unused-function");
		cmd_append(arena, &c, __FILE__, OUTPUT_EXE(binary));
		if (is_msvc) cmd_append(arena, &c, "/link", "-incremental:no", "-opt:ref");
		cmd_append(arena, &c, (void *)0);
		if (!run_synchronous(arena, &c)) {
			os_rename_file(old_name, binary);
			build_fatal("failed to rebuild self");
		}
		os_remove_file(old_name);

		c.count = 0;
		cmd_append(arena, &c, binary);
		cmd_append_count(arena, &c, argv, argc);
		cmd_append(arena, &c, (void *)0);
		if (!run_synchronous(arena, &c))
			os_exit(1);

		os_exit(0);
	}
}

function void
usage(char *argv0)
{
	printf("%s [--bake-shaders] [--debug] [--sanitize] [--time]\n"
	       "    --debug:       dynamically link and build with debug symbols\n"
	       "    --generic:     compile for a generic target (x86-64-v3 or armv8 with NEON)\n"
	       "    --sanitize:    build with ASAN and UBSAN\n"
	       "    --time:        print build time\n"
	       , argv0);
	os_exit(0);
}

function Options
parse_options(s32 argc, char *argv[])
{
	Options result = {0};

	char *argv0 = shift(argv, argc);
	while (argc > 0) {
		char *arg = shift(argv, argc);
		str8 str    = str8_from_c_str(arg);
		if (str8_equal(str, str8("--debug"))) {
			result.debug = 1;
		} else if (str8_equal(str, str8("--generic"))) {
			result.generic = 1;
		} else if (str8_equal(str, str8("--sanitize"))) {
			result.sanitize = 1;
		} else if (str8_equal(str, str8("--time"))) {
			result.time = 1;
		} else {
			usage(argv0);
		}
	}

	return result;
}

/* NOTE(rnp): produce pdbs on w32 */
function void
cmd_pdb(Arena *a, CommandList *cmd, char *name)
{
	if (is_w32 && is_clang) {
		cmd_append(a, cmd, "-fuse-ld=lld", "-g", "-gcodeview", "-Wl,--pdb=");
	} else if (is_msvc) {
		Stream sb = arena_stream(a);
		stream_append_str8s(&sb, str8("-PDB:"), str8_from_c_str(name), str8(".pdb"));
		char *pdb = (char *)arena_stream_commit_zero(a, &sb).data;
		cmd_append(a, cmd, "/link", "-incremental:no", "-opt:ref", "-DEBUG", pdb);
	}
}

function void
git_submodule_update(Arena *a, char *name)
{
	Stream sb = arena_stream(a);
	stream_append_str8s(&sb, str8_from_c_str(name), str8(OS_PATH_SEPARATOR), str8(".git"));
	arena_stream_commit_zero(a, &sb);

	CommandList git = {0};
	/* NOTE(rnp): cryptic bs needed to get a simple exit code if name is dirty */
	cmd_append(a, &git, "git", "diff-index", "--quiet", "HEAD", "--", name, (void *)0);
	if (!os_file_exists((c8 *)sb.data) || !run_synchronous(a, &git)) {
		git.count = 1;
		cmd_append(a, &git, "submodule", "update", "--init", "--depth=1", name, (void *)0);
		if (!run_synchronous(a, &git))
			build_fatal("failed to clone required module: %s", name);
	}
}

function b32
build_shared_library(Arena *a, CommandList cc, char *name, char *output, char **libs, s64 libs_count, char **srcs, s64 srcs_count)
{
	cmd_append_count(a, &cc, srcs, srcs_count);
	cmd_append(a, &cc, OUTPUT_DLL(output));
	cmd_pdb(a, &cc, name);
	cmd_append_count(a, &cc, libs, libs_count);
	cmd_append(a, &cc, (void *)0);
	b32 result = run_synchronous(a, &cc);
	if (!result) build_log_failure("%s", output);
	return result;
}

function b32
cc_single_file(Arena *a, CommandList cc, char *exe, char *src, char *dest, char **tail, s64 tail_count)
{
	char *executable[] = {src, is_msvc? "/Fe:" : "-o", dest};
	char *object[]     = {is_msvc? "/c" : "-c", src, is_msvc? "/Fo:" : "-o", dest};


	cmd_append_count(a, &cc, exe? executable : object,
	                 exe? countof(executable) : countof(object));
	if (exe) cmd_pdb(a, &cc, exe);
	cmd_append_count(a, &cc, tail, tail_count);
	cmd_append(a, &cc, (void *)0);
	b32 result = run_synchronous(a, &cc);
	if (!result) build_log_failure("%s", dest);
	return result;
}

function b32
build_static_library_from_objects(Arena *a, char *name, char **flags, s64 flags_count, char **objects, s64 count)
{
	CommandList ar = {0};
	cmd_append(a, &ar, STATIC_LIBRARY_BEGIN(name));
	cmd_append_count(a, &ar, flags, flags_count);
	cmd_append_count(a, &ar, objects, count);
	cmd_append(a, &ar, (void *)0);
	b32 result = run_synchronous(a, &ar);
	if (!result) build_log_failure("%s", name);
	return result;
}

function b32
build_static_library(Arena *a, CommandList cc, char *name, char **deps, char **outputs, s64 count)
{
	/* TODO(rnp): refactor to not need outputs */
	b32 result = 1;
	for (s64 i = 0; i < count; i++)
		result &= cc_single_file(a, cc, 0, deps[i], outputs[i], 0, 0);
	if (result) result = build_static_library_from_objects(a, name, 0, 0, outputs, count);
	return result;
}

typedef struct {
	str8     *data;
	da_count  count;
	da_count  capacity;
} str8_list;

function str8
str8_chop(str8 *in, s64 count)
{
	count = Clamp(count, 0, in->length);
	str8 result = {.data = in->data, .length = count};
	in->data   += count;
	in->length -= count;
	return result;
}

function str8
str8_trim(str8 in)
{
	str8 result = in;
	for (s64 i = 0; i < in.length && *result.data == ' '; i++) result.data++;
	result.length -= result.data - in.data;
	for (; result.length > 0 && result.data[result.length - 1] == ' '; result.length--);
	return result;
}

typedef struct {
	Stream  stream;
	Arena  *scratch;
	s32     indentation_level;
} MetaprogramContext;

function b32
meta_write_and_reset(MetaprogramContext *m, char *file)
{
	b32 result = os_write_new_file(file, stream_to_str8(&m->stream));
	if (!result) build_log_failure("%s", file);
	m->stream.count      = 0;
	m->indentation_level = 0;
	return result;
}

#define meta_push(m, ...) meta_push_(m, arg_list(str8, __VA_ARGS__))
function void
meta_push_(MetaprogramContext *m, str8 *items, s64 count)
{
	stream_append_str8s_(&m->stream, items, count);
}

#define meta_pad(m, b, n)                stream_pad(&(m)->stream, (b), (n))
#define meta_indent(m)                   meta_pad((m), '\t', (m)->indentation_level)
#define meta_begin_line(m, ...)          meta_indent(m), meta_push(m, __VA_ARGS__)
#define meta_end_line(m, ...)                            meta_push(m, ##__VA_ARGS__, str8("\n"))
#define meta_push_line(m, ...)           meta_indent(m), meta_push(m, ##__VA_ARGS__, str8("\n"))
#define meta_begin_scope(m, ...)         meta_push_line(m, __VA_ARGS__), (m)->indentation_level++
#define meta_end_scope(m, ...)           (m)->indentation_level--, meta_push_line(m, __VA_ARGS__)
#define meta_push_f64(m, n)              stream_append_f64(&(m)->stream, (n), 1000000)
#define meta_push_u64(m, n)              stream_append_u64(&(m)->stream, (n))
#define meta_push_s64(m, n)              stream_append_s64(&(m)->stream, (n))
#define meta_push_u64_hex(m, n)          stream_append_hex_u64(&(m)->stream, (n))
#define meta_push_u64_hex_width(m, n, w) stream_append_hex_u64_width(&(m)->stream, (n), (w))

#define meta_begin_matlab_class_cracker(_1, _2, FN, ...) FN
#define meta_begin_matlab_class_1(m, name) meta_begin_scope(m, str8("classdef " name))
#define meta_begin_matlab_class_2(m, name, type) \
  meta_begin_scope(m, str8("classdef " name " < " type))

#define meta_begin_matlab_class(m, ...) \
  meta_begin_matlab_class_cracker(__VA_ARGS__, \
                                  meta_begin_matlab_class_2, \
                                  meta_begin_matlab_class_1)(m, __VA_ARGS__)

function b32
meta_end_and_write_matlab(MetaprogramContext *m, char *path)
{
	while (m->indentation_level > 0) meta_end_scope(m, str8("end"));
	b32 result = meta_write_and_reset(m, path);
	return result;
}

#define META_ENTRY_KIND_LIST \
	X(Invalid) \
	X(Array) \
	X(BeginScope) \
	X(Constant) \
	X(EndScope) \
	X(Enumeration) \
	X(Expand) \
	X(Flags) \
	X(String) \
	X(Struct) \
	X(Table) \
	X(Union) \

typedef enum {
	#define X(k, ...) MetaEntryKind_## k,
	META_ENTRY_KIND_LIST
	#undef X
	MetaEntryKind_Count,
} MetaEntryKind;

#define X(k, ...) #k,
read_only global char *meta_entry_kind_strings[] = {META_ENTRY_KIND_LIST};
#undef X

#define META_KIND_LIST \
	X(M4,  float,    single, f, 64, 16) \
	X(SV4, int32_t,  int32,  l, 16,  4) \
	X(UV4, uint32_t, uint32, L, 16,  4) \
	X(UV2, uint32_t, uint32, L,  8,  2) \
	X(V3,  float,    single, f, 12,  3) \
	X(V2,  float,    single, f,  8,  2) \
	X(F32, float,    single, f,  4,  1) \
	X(S32, int32_t,  int32,  l,  4,  1) \
	X(S16, int16_t,  int16,  h,  2,  1) \
	X(S8,  int8_t,   int8,   b,  1,  1) \
	X(U64, uint64_t, uint64, Q,  8,  1) \
	X(U32, uint32_t, uint32, L,  4,  1) \
	X(U16, uint16_t, uint16, H,  2,  1) \
	X(U8,  uint8_t,  uint8,  B,  1,  1) \

typedef enum {
	#define X(k, ...) MetaKind_## k,
	META_KIND_LIST
	#undef X
	MetaKind_Count,
} MetaKind;

read_only global u8 meta_kind_elements[] = {
	#define X(_k, _b, _m, _pys, _by, elements, ...) elements,
	META_KIND_LIST
	#undef X
};

read_only global u8 meta_kind_byte_sizes[] = {
	#define X(_k, _b, _m, _pys, bytes, ...) bytes,
	META_KIND_LIST
	#undef X
};

read_only global str8 meta_kind_meta_types[] = {
	#define X(k, ...) str8_comp(#k),
	META_KIND_LIST
	#undef X
};

read_only global str8 meta_kind_base_c_types[] = {
	#define X(_k, base, ...) str8_comp(#base),
	META_KIND_LIST
	#undef X
};

read_only global str8 meta_kind_matlab_types[] = {
	#define X(_k, _b, m, ...) str8_comp(#m),
	META_KIND_LIST
	#undef X
};

read_only global str8 meta_kind_python_struct_types[] = {
	#define X(_k, _b, _m, pys, ...) str8_comp(#pys),
	META_KIND_LIST
	#undef X
};

typedef enum {
	MetaStructMemberFlag_ReferenceType = 1 << 0,
} MetaStructMemberFlags;

typedef enum {
	MetaStructFlag_Union         = 1 << 0,
	MetaStructFlag_ContainsUnion = 1 << 1,
} MetaStructFlags;

typedef struct {
	u32 type_id;
	u32 offset;
	u32 elements;
	u32 flags;
} MetaStructMember;

typedef struct {
	str8            name;
	u32             member_count;
	u32             size;
	MetaStructFlags flags;
} MetaStructInfo;

#define META_CURRENT_LOCATION (MetaLocation){__LINE__, 0}
typedef struct { u32 line, column; } MetaLocation;

#define META_ENTRY_ARGUMENT_KIND_LIST \
	X(None)   \
	X(String) \
	X(Array)

#define X(k, ...) MetaEntryArgumentKind_## k,
typedef enum {META_ENTRY_ARGUMENT_KIND_LIST} MetaEntryArgumentKind;
#undef X

typedef struct {
	MetaEntryArgumentKind kind;
	MetaLocation          location;
	union {
		str8 string;
		struct {
			str8 *strings;
			u64   count;
		};
	};
} MetaEntryArgument;

typedef struct {
	MetaEntryKind      kind;
	u32                argument_count;
	MetaEntryArgument *arguments;
	str8               name;
	MetaLocation       location;
} MetaEntry;

typedef struct {
	MetaEntry *data;
	da_count   count;
	da_count   capacity;
	str8       raw;
} MetaEntryStack;

#define META_PARSE_TOKEN_LIST \
	X('@', Entry)      \
	X('`', RawString)  \
	X('(', BeginArgs)  \
	X(')', EndArgs)    \
	X('[', BeginArray) \
	X(']', EndArray)   \
	X('{', BeginScope) \
	X('}', EndScope)

typedef enum {
	MetaParseToken_EOF,
	MetaParseToken_String,
	#define X(__1, kind, ...) MetaParseToken_## kind,
	META_PARSE_TOKEN_LIST
	#undef X
	MetaParseToken_Count,
} MetaParseToken;

typedef union {
	MetaEntryKind kind;
	str8          string;
} MetaParseUnion;

typedef struct {
	str8 s;
	MetaLocation location;
} MetaParsePoint;

typedef struct {
	MetaParsePoint p;
	MetaParseUnion u;
	MetaParsePoint save_point;
} MetaParser;

global char    *compiler_file;
global jmp_buf  compiler_jmp_buf;

#define meta_parser_save(v)    (v)->save_point = (v)->p
#define meta_parser_restore(v) swap((v)->p, (v)->save_point)
#define meta_parser_commit(v)  meta_parser_restore(v)

#define meta_compiler_message(format, ...) \
	fprintf(stderr, format, ##__VA_ARGS__)

#define meta_compiler_error_message(loc, format, ...) \
	fprintf(stderr, "%s:%u:%u: error: "format, compiler_file, \
	        loc.line + 1, loc.column + 1, ##__VA_ARGS__)

#define meta_compiler_error(loc, format, ...) do { \
	meta_compiler_error_message(loc, format, ##__VA_ARGS__); \
	meta_error(); \
} while (0)

#define meta_entry_error(e, ...) meta_entry_error_column((e), (s32)(e)->location.column, __VA_ARGS__)
#define meta_entry_error_column(e, column, ...) do { \
	meta_compiler_error_message((e)->location, __VA_ARGS__); \
	meta_entry_print((e), 2 * (column), 0); \
	meta_error(); \
} while(0)

#define meta_entry_pair_error(e, prefix, base_kind) \
	meta_entry_error(e, prefix"@%s() in @%s()\n", \
	                 meta_entry_kind_strings[(e)->kind], \
	                 meta_entry_kind_strings[(base_kind)])

#define meta_entry_nesting_error(e, base_kind) meta_entry_pair_error(e, "invalid nesting: ", base_kind)

#define meta_entry_error_location(e, loc, ...) do { \
	meta_compiler_error_message((loc), __VA_ARGS__); \
	meta_entry_print((e), 1, (s32)(loc).column); \
	meta_error(); \
} while (0)

function no_return void
meta_error(void)
{
	assert(0);
	longjmp(compiler_jmp_buf, 1);
}

function void
meta_entry_print(MetaEntry *e, s32 indent, s32 caret)
{
	char *kind = meta_entry_kind_strings[e->kind];
	if (e->kind == MetaEntryKind_BeginScope) kind = "{";
	if (e->kind == MetaEntryKind_EndScope)   kind = "}";

	fprintf(stderr, "%*s@%s", indent, "", kind);

	if (e->argument_count) {
		fprintf(stderr, "(");
		for (u32 i = 0; i < e->argument_count; i++) {
			MetaEntryArgument *a = e->arguments + i;
			if (i != 0) fprintf(stderr, " ");
			if (a->kind == MetaEntryArgumentKind_Array) {
				fprintf(stderr, "[");
				for (u64 j = 0; j < a->count; j++) {
					if (j != 0) fprintf(stderr, " ");
					fprintf(stderr, "%.*s", (s32)a->strings[j].length, a->strings[j].data);
				}
				fprintf(stderr, "]");
			} else {
				fprintf(stderr, "%.*s", (s32)a->string.length, a->string.data);
			}
		}
		fprintf(stderr, ")");
	}
	if (e->name.length) fprintf(stderr, " %.*s", (s32)e->name.length, e->name.data);

	if (caret >= 0) fprintf(stderr, "\n%*s^", indent + caret, "");

	fprintf(stderr, "\n");
}

function s64
meta_lookup_string_slow(str8 *strings, s64 string_count, str8 s)
{
	// TODO(rnp): obviously this is slow
	s64 result = -1;
	for (s64 i = 0; i < string_count; i++) {
		if (str8_equal(s, strings[i])) {
			result = i;
			break;
		}
	}
	return result;
}

function MetaEntryKind
meta_entry_kind_from_string(str8 s)
{
	#define X(k, ...) str8_comp(#k),
	read_only local_persist str8 kinds[] = {META_ENTRY_KIND_LIST};
	#undef X
	MetaEntryKind result = MetaEntryKind_Invalid;
	s64 id = meta_lookup_string_slow(kinds + 1, countof(kinds) - 1, s);
	if (id > 0) result = (MetaEntryKind)(id + 1);
	return result;
}

function void
meta_parser_trim(MetaParser *p)
{
	u8 *s, *end = p->p.s.data + p->p.s.length;
	b32 done    = 0;
	b32 comment = 0;
	for (s = p->p.s.data; !done && s != end;) {
		switch (*s) {
		case '\r': case '\t': case ' ':
		{
			p->p.location.column++;
		}break;
		case '\n':{ p->p.location.line++; p->p.location.column = 0; comment = 0; }break;
		case '/':{
			comment |= ((s + 1) != end && s[1] == '/');
			if (comment) s++;
		} /* FALLTHROUGH */
		default:{done = !comment;}break;
		}
		if (!done) s++;
	}
	p->p.s.data   = s;
	p->p.s.length = end - s;
}

function str8
meta_parser_extract_raw_string(MetaParser *p)
{
	str8 result = {.data = p->p.s.data};
	for (; result.length < p->p.s.length; result.length++) {
		u8 byte = p->p.s.data[result.length];
		p->p.location.column++;
		if (byte == '`') {
			break;
		} else if (byte == '\n') {
			p->p.location.column = 0;
			p->p.location.line++;
		}
	}
	p->p.s.data   += (result.length + 1);
	p->p.s.length -= (result.length + 1);
	return result;
}

function str8
meta_parser_extract_string(MetaParser *p)
{
	str8 result = {.data = p->p.s.data};
	for (; result.length < p->p.s.length; result.length++) {
		b32 done = 0;
		switch (p->p.s.data[result.length]) {
		#define X(t, ...) case t:
		META_PARSE_TOKEN_LIST
		#undef X
		case ' ': case '\n': case '\r': case '\t':
		{done = 1;}break;
		case '/':{
			done = (result.length + 1 < p->p.s.length) && (p->p.s.data[result.length + 1] == '/');
		}break;
		default:{}break;
		}
		if (done) break;
	}
	p->p.location.column += (u32)result.length;
	p->p.s.data          += result.length;
	p->p.s.length        -= result.length;
	return result;
}

function str8
meta_parser_token_name(MetaParser *p, MetaParseToken t)
{
	str8 result = str8("\"invalid\"");
	read_only local_persist str8 names[MetaParseToken_Count] = {
		[MetaParseToken_EOF] = str8_comp("\"EOF\""),
		#define X(k, v, ...) [MetaParseToken_## v] = str8_comp(#k),
		META_PARSE_TOKEN_LIST
		#undef X
	};
	if (t >= 0 && t < countof(names))  result = names[t];
	if (t == MetaParseToken_String)    result = p->u.string;
	if (t == MetaParseToken_RawString) result = (str8){.data = p->u.string.data - 1, .length = p->u.string.length + 1};
	return result;
}

function MetaParseToken
meta_parser_token(MetaParser *p)
{
	MetaParseToken result = MetaParseToken_EOF;
	meta_parser_save(p);
	if (p->p.s.length > 0) {
		b32 chop = 1;
		switch (p->p.s.data[0]) {
		#define X(t, kind, ...) case t:{ result = MetaParseToken_## kind; }break;
		META_PARSE_TOKEN_LIST
		#undef X
		default:{ result = MetaParseToken_String; chop = 0; }break;
		}
		if (chop) { str8_chop(&p->p.s, 1); p->p.location.column++; }

		if (result != MetaParseToken_RawString) meta_parser_trim(p);
		switch (result) {
		case MetaParseToken_RawString:{ p->u.string = meta_parser_extract_raw_string(p); }break;
		case MetaParseToken_String:{    p->u.string = meta_parser_extract_string(p);     }break;

		/* NOTE(rnp): '{' and '}' are shorthand for @BeginScope and @EndScope */
		case MetaParseToken_BeginScope:{ p->u.kind = MetaEntryKind_BeginScope; }break;
		case MetaParseToken_EndScope:{   p->u.kind = MetaEntryKind_EndScope;   }break;

		/* NOTE(rnp): loose '[' implies implicit @Array() */
		case MetaParseToken_BeginArray:{ p->u.kind = MetaEntryKind_Array; }break;

		case MetaParseToken_Entry:{
			str8 kind = meta_parser_extract_string(p);
			p->u.kind = meta_entry_kind_from_string(kind);
			if (p->u.kind == MetaEntryKind_Invalid) {
				meta_compiler_error(p->p.location, "invalid keyword: @%.*s\n", (s32)kind.length, kind.data);
			}
		}break;
		default:{}break;
		}
		meta_parser_trim(p);
	}

	return result;
}

function MetaParseToken
meta_parser_peek_token(MetaParser *p)
{
	MetaParseToken result = meta_parser_token(p);
	meta_parser_restore(p);
	return result;
}

function void
meta_parser_unexpected_token(MetaParser *p, MetaParseToken t)
{
	meta_parser_restore(p);
	str8 token_name = meta_parser_token_name(p, t);
	meta_compiler_error(p->p.location, "unexpected token: %.*s\n", (s32)token_name.length, token_name.data);
}

function void
meta_parser_fill_argument_array(MetaParser *p, MetaEntryArgument *array, Arena *arena)
{
	str8_list strings = {0};
	array->kind     = MetaEntryArgumentKind_Array;
	array->location = p->p.location;
	for (MetaParseToken token = meta_parser_token(p);
	     token != MetaParseToken_EndArray;
	     token = meta_parser_token(p))
	{
		switch (token) {
		case MetaParseToken_RawString:
		case MetaParseToken_String:
		{
			*da_push(arena, &strings) = p->u.string;
		}break;
		default:{ meta_parser_unexpected_token(p, token); }break;
		}
	}
	array->strings = strings.data;
	array->count   = strings.count;
	arena_pop(arena, (strings.capacity - strings.count) * sizeof(*strings.data));
}

function void
meta_parser_arguments(MetaParser *p, MetaEntry *e, Arena *arena)
{
	if (meta_parser_peek_token(p) == MetaParseToken_BeginArgs) {
		meta_parser_commit(p);

		struct {
			MetaEntryArgument *data;
			da_count count;
			da_count capacity;
		} arguments = {0};

		for (MetaParseToken token = meta_parser_token(p);
		     token != MetaParseToken_EndArgs;
		     token = meta_parser_token(p))
		{
			MetaEntryArgument *arg = da_push(arena, &arguments);
			switch (token) {
			case MetaParseToken_RawString:
			case MetaParseToken_String:
			{
				arg->kind     = MetaEntryArgumentKind_String;
				arg->string   = p->u.string;
				arg->location = p->p.location;
			}break;
			case MetaParseToken_BeginArray:{
				meta_parser_fill_argument_array(p, arg, arena);
			}break;
			default:{ meta_parser_unexpected_token(p, token); }break;
			}
		}
		e->arguments      = arguments.data;
		e->argument_count = arguments.count;
		// TODO(rnp): we should count arguments first so that we don't need to leave a hole
		//arena_pop(arena, (arguments.capacity - arguments.count) * sizeof(*arguments.data));
	}
}

typedef struct {
	MetaEntry *start;
	MetaEntry *one_past_last;
	s64 consumed;
} MetaEntryScope;

function MetaEntryScope
meta_entry_extract_scope(MetaEntry *base, s64 entry_count)
{
	assert(base->kind != MetaEntryKind_BeginScope && base->kind != MetaEntryKind_EndScope);
	assert(entry_count > 0);

	MetaEntryScope result = {.start = base + 1, .consumed = 1};
	s64 sub_scope = 0;
	for (MetaEntry *e = result.start; result.consumed < entry_count; result.consumed++, e++) {
		switch (e->kind) {
		case MetaEntryKind_BeginScope:{ sub_scope++; }break;
		case MetaEntryKind_EndScope:{   sub_scope--; }break;
		default:{}break;
		}
		if (sub_scope == 0) break;
	}

	if (sub_scope != 0)
		meta_entry_error(base, "unclosed scope for entry\n");

	result.one_past_last = base + result.consumed;
	if (result.start->kind == MetaEntryKind_BeginScope) result.start++;
	if (result.one_past_last == result.start) result.one_past_last++;

	return result;
}

function MetaEntryStack
meta_entry_stack_from_file(Arena *arena, char *file)
{
	MetaParser     parser = {.p.s = os_read_entire_file(arena, file)};
	MetaEntryStack result = {.raw = parser.p.s};

	compiler_file = file;

	meta_parser_trim(&parser);

	for (MetaParseToken token = meta_parser_token(&parser);
	     token != MetaParseToken_EOF;
	     token = meta_parser_token(&parser))
	{
		MetaEntry *e = da_push(arena, &result);
		switch (token) {
		case MetaParseToken_String:
		case MetaParseToken_RawString:
		{
			e->kind     = MetaEntryKind_String;
			e->location = parser.save_point.location;
			e->name     = parser.u.string;
		}break;

		case MetaParseToken_BeginScope:
		case MetaParseToken_EndScope:
		{
			e->kind     = parser.u.kind;
			e->location = parser.save_point.location;
		}break;

		case MetaParseToken_BeginArray:
		case MetaParseToken_Entry:
		{
			e->kind     = parser.u.kind;
			e->location = parser.save_point.location;

			if (token == MetaParseToken_Entry)
				meta_parser_arguments(&parser, e, arena);

			if (token == MetaParseToken_BeginArray) {
				MetaEntryArgument *a = e->arguments = push_struct(arena, MetaEntryArgument);
				e->argument_count = 1;
				meta_parser_fill_argument_array(&parser, a, arena);
			}

			if (meta_parser_peek_token(&parser) == MetaParseToken_String) {
				meta_parser_commit(&parser);
				e->name = parser.u.string;
			}
		}break;

		default:{ meta_parser_unexpected_token(&parser, token); }break;
		}
	}

	return result;
}

#define meta_entry_argument_expected(e, ...) \
	meta_entry_argument_expected_((e), arg_list(str8, __VA_ARGS__))
function void
meta_entry_argument_expected_(MetaEntry *e, str8 *args, u64 count)
{
	if (e->argument_count != count) {
		meta_compiler_error_message(e->location, "incorrect argument count for entry %s() got: %u expected: %u\n",
		                            meta_entry_kind_strings[e->kind], e->argument_count, (u32)count);
		fprintf(stderr, "  format: @%s(", meta_entry_kind_strings[e->kind]);
		for EachIndex(count, it) {
			if (it != 0) fprintf(stderr, ", ");
			fprintf(stderr, "%.*s", (s32)args[it].length, args[it].data);
		}
		fprintf(stderr, ")\n");
		meta_error();
	}
}

function MetaEntryArgument
meta_entry_argument_expect(MetaEntry *e, u32 index, MetaEntryArgumentKind kind)
{
	#define X(k, ...) #k,
	read_only local_persist char *kinds[] = {META_ENTRY_ARGUMENT_KIND_LIST};
	#undef X

	assert(e->argument_count > index);
	MetaEntryArgument result = e->arguments[index];

	if (result.kind != kind) {
		meta_entry_error_location(e, result.location, "unexpected argument kind: expected %s but got: %s\n",
		                          kinds[kind], kinds[result.kind]);
	}

	if (kind == MetaEntryArgumentKind_Array && result.count == 0)
		meta_entry_error_location(e, result.location, "array arguments must have at least 1 element\n");

	return result;
}

typedef struct { da_count value; } MetaEntityID;

typedef struct {
	da_count *data;
	da_count  count;
	da_count  capacity;
} MetaIDList;

typedef enum {
	MetaExpansionPartKind_Alignment,
	MetaExpansionPartKind_Conditional,
	MetaExpansionPartKind_EvalKind,
	MetaExpansionPartKind_EvalKindCount,
	MetaExpansionPartKind_Reference,
	MetaExpansionPartKind_String,
} MetaExpansionPartKind;

typedef enum {
	MetaExpansionConditionalArgumentKind_Invalid,
	MetaExpansionConditionalArgumentKind_Number,
	MetaExpansionConditionalArgumentKind_Evaluation,
	MetaExpansionConditionalArgumentKind_Reference,
} MetaExpansionConditionalArgumentKind;

typedef struct {
	MetaExpansionConditionalArgumentKind kind;
	union {
		str8 *strings;
		s64   number;
	};
} MetaExpansionConditionalArgument;

typedef enum {
	MetaExpansionOperation_Invalid,
	MetaExpansionOperation_LessThan,
	MetaExpansionOperation_GreaterThan,
} MetaExpansionOperation;

typedef struct {
	MetaExpansionConditionalArgument lhs;
	MetaExpansionConditionalArgument rhs;
	MetaExpansionOperation           op;
	u32 instruction_skip;
} MetaExpansionConditional;

typedef struct {
	MetaExpansionPartKind kind;
	union {
		str8  string;
		str8 *strings;
		MetaExpansionConditional conditional;
	};
} MetaExpansionPart;
DA_STRUCT(MetaExpansionPart, MetaExpansionPart);

typedef enum {
	MetaEmitOperationKind_Expand,
	MetaEmitOperationKind_FileBytes,
	MetaEmitOperationKind_String,
} MetaEmitOperationKind;

typedef struct {
	MetaExpansionPart *parts;
	u32      part_count;
	da_count table_entity_id;
} MetaEmitOperationExpansion;

typedef struct {
	union {
		str8 string;
		MetaEmitOperationExpansion expansion_operation;
	};
	MetaEmitOperationKind kind;
	MetaLocation          location;
} MetaEmitOperation;

typedef struct {
	MetaEmitOperation *data;
	da_count count;
	da_count capacity;

	str8 filename;
} MetaEmitOperationList;

typedef struct {
	MetaEmitOperationList *data;
	da_count count;
	da_count capacity;
} MetaEmitOperationListSet;

#define META_STRUCT_FIELDS \
	X(Name,     name) \
	X(Type,     type) \
	X(Elements, elements) \

#define X(id, ...) MetaStructField_##id,
typedef enum {META_STRUCT_FIELDS} MetaStructFields;
#undef X

typedef struct {
	str8  *fields;
	str8 **entries;
	u32    field_count;
	u32    entry_count;
	union {
		s32 struct_info_id;
	};
} MetaTable;

typedef enum {
	MetaConstantKind_Integer,
	MetaConstantKind_Float,
	MetaConstantKind_Count,
} MetaConstantKind;

typedef struct {
	MetaConstantKind kind;
	u32 name_id;
	union {
		u64 U64;
		f64 F64;
	};
} MetaConstant;

typedef struct {
	str8         reference_name;
	MetaEntityID resolved_id;
	da_count     reference_count;

	// NOTE: only used for namespacing MATLAB unions
	str8         scope_name;
} MetaEntityReference;

// X(name, is_table, is_struct, struct_reference_target)
#define META_ENTITY_KIND_LIST \
	X(Nil,                0, 0, 0) \
	X(List,               0, 0, 0) \
	X(Constant,           0, 0, 0) \
	X(Enumeration,        1, 0, 1) \
	X(Flags,              1, 0, 1) \
	X(Reference,          0, 0, 0) \
	X(ReferenceReference, 0, 0, 0) \
	X(Struct,             1, 1, 1) \
	X(Table,              1, 0, 0) \
	X(Union,              1, 1, 1) \

// X(EntityKind, AllowReferences, Emit)
#define META_STRUCT_MAP_LIST \
	X(Struct, 1, 1) \
	X(Union,  1, 0) \

typedef enum {
	#define X(name, ...) MetaEntityKind_ ##name,
	META_ENTITY_KIND_LIST
	#undef X
	MetaEntityKind_Count,
} MetaEntityKind;

typedef struct {
	MetaEntityKind kind;
	MetaEntityID   parent;
	MetaEntityID   first_child;
	MetaEntityID   next_sibling;
	MetaEntityID   previous_sibling;
	MetaLocation   location;
	union {
		MetaConstant        constant;
		MetaEntityReference reference;
		MetaTable           table;
	};
} MetaEntity;
DA_STRUCT(MetaEntity, MetaEntity);

#define X(name, ...) str8_comp(#name),
read_only global str8 meta_entity_kind_names[] = {META_ENTITY_KIND_LIST};
#undef X
#define X(_n, table, ...) table,
read_only global b8 meta_entity_kind_is_table[] = {META_ENTITY_KIND_LIST};
#undef X
#define X(_n, _t, s, ...) s,
read_only global b8 meta_entity_kind_is_struct[] = {META_ENTITY_KIND_LIST};
#undef X
#define X(_n, _t, _s, srt, ...) srt,
read_only global b8 meta_entity_kind_struct_reference_target[] = {META_ENTITY_KIND_LIST};
#undef X

#define X(k, ...) MetaEntityKind_##k,
read_only global MetaEntityKind meta_struct_entity_kinds[] = {META_STRUCT_MAP_LIST};
#undef X
#define X(_k, allow, ...) allow,
read_only global b8 meta_struct_allow_references[] = {META_STRUCT_MAP_LIST};
#undef X
#define X(_k, _a, emit, ...) emit,
read_only global b8 meta_struct_emit[] = {META_STRUCT_MAP_LIST};
#undef X

typedef enum {
	MetaBuildStructMemberFlag_ReferenceType     = 1 << 0,
	MetaBuildStructMemberFlag_ReferenceElements = 1 << 1,
	MetaBuildStructMemberFlag_EnumerationCount  = 1 << 2,
} MetaBuildStructMemberFlags;

typedef struct {
	MetaStructInfo info;

	str8 *members;
	s32  *type_ids;
	s32  *elements;

	MetaBuildStructMemberFlags *member_flags;

	MetaEntityID entity;
	MetaLocation location;
} MetaStruct;

typedef struct {
	Arena *arena, *scratch;

	str8 filename;
	str8 directory;
	str8 fullpath;

	// NOTE(rnp): arrays of entity ids sorted by kind and counted by entity_kind_counts
	da_count                    *entity_kind_ids[MetaEntityKind_Count];

	da_count                     entity_kind_counts[MetaEntityKind_Count];
	str8_list                    entity_names;
	MetaEntityList               entities;

	// NOTE(rnp): fully resolved structs
	MetaStruct                  *struct_infos;
	u32                          struct_infos_count;
} MetaContext;

function da_count
meta_lookup_id_slow(da_count *v, da_count count, da_count id)
{
	// TODO(rnp): obviously this is slow
	da_count result = -1;
	for (da_count i = 0; i < count; i++) {
		if (id == v[i]) {
			result = i;
			break;
		}
	}
	return result;
}

function da_count
meta_intern_string(MetaContext *ctx, str8_list *sv, str8 s)
{
	da_count result = meta_lookup_string_slow(sv->data, sv->count, s);
	if (result < 0) {
		*da_push(ctx->arena, sv) = s;
		result = sv->count - 1;
	}
	return result;
}

function da_count
meta_intern_id(MetaContext *ctx, MetaIDList *v, da_count id)
{
	da_count result = meta_lookup_id_slow(v->data, v->count, id);
	if (result < 0) {
		*da_push(ctx->arena, v) = id;
		result = v->count - 1;
	}
	return result;
}

function da_count
meta_entity_children_count(MetaContext *ctx, MetaEntityID entity_id)
{
	MetaEntityID child = ctx->entities.data[entity_id.value].first_child;
	da_count result = 0;
	if (child.value != 0) {
		do {
			result++;
			child = ctx->entities.data[child.value].next_sibling;
		} while (child.value != ctx->entities.data[entity_id.value].first_child.value);
	}
	return result;
}

function da_count *
meta_entity_extract_children(MetaContext *ctx, MetaEntityID entity_id, da_count *children_count, Arena *arena)
{
	*children_count  = meta_entity_children_count(ctx, entity_id);
	da_count *result = push_array_no_zero(arena, da_count, *children_count);

	// NOTE(rnp): children are pushed in LIFO order
	MetaEntity *e = ctx->entities.data + entity_id.value;
	da_count index = 0;
	MetaEntityID child = e->first_child;
	do {
		child = ctx->entities.data[child.value].previous_sibling;
		result[index++] = child.value;
	} while (child.value != e->first_child.value);

	return result;
}

function MetaEntity *
meta_entity(MetaContext *ctx, MetaEntityID id)
{
	assert(id.value != 0 && id.value < ctx->entities.count);
	MetaEntity *result = ctx->entities.data + id.value;
	return result;
}

function MetaEntityID
meta_root_entity_id(MetaContext *ctx)
{
	MetaEntityID result = {0};
	return result;
}

function MetaEntityID
meta_intern_entity(MetaContext *ctx, str8 name, MetaEntityKind kind, MetaEntityID parent,
                   MetaLocation location, b32 allow_existing)
{
	MetaEntityID result = {0};
	assert(ctx->entities.data[0].kind == MetaEntityKind_Nil);
	assert(Between(kind, MetaEntityKind_Nil + 1, MetaEntityKind_Count - 1));

	da_count name_id = meta_intern_string(ctx, &ctx->entity_names, name);
	if (name_id < ctx->entities.count && ctx->entities.data[name_id].kind != kind) {
		str8 old_kind = meta_entity_kind_names[ctx->entities.data[name_id].kind];
		str8 new_kind = meta_entity_kind_names[kind];
		meta_compiler_error_message(location, "attempting to redefine %.*s as kind %.*s\n",
		                            (s32)name.length, name.data, (s32)new_kind.length, new_kind.data);
		meta_compiler_error_message(ctx->entities.data[name_id].location, "previously defined as kind %.*s\n",
		                            (s32)old_kind.length, old_kind.data);
		meta_error();
	} else if (name_id < ctx->entities.count && !allow_existing) {
		meta_compiler_error_message(location, "redefinition of %.*s\n", (s32)name.length, name.data);
		meta_compiler_error_message(ctx->entities.data[name_id].location, "previously defined here\n");
		meta_error();
	} else {
		if (name_id < ctx->entities.count) {
			result.value = name_id;
		} else {
			ctx->entity_kind_counts[kind]++;
			MetaEntity *new = da_push(ctx->arena, &ctx->entities);
			new->location = location;
			result.value = da_index(new, &ctx->entities);
		}

		MetaEntity *e = ctx->entities.data + result.value;
		e->kind       = kind;
		e->parent     = parent;

		MetaEntity *p = ctx->entities.data + parent.value;
		e->next_sibling = p->first_child;
		p->first_child = result;

		if (e->next_sibling.value == 0)
			e->next_sibling = p->first_child;

		e->previous_sibling = ctx->entities.data[e->next_sibling.value].previous_sibling;
		ctx->entities.data[e->next_sibling.value].previous_sibling = result;
		ctx->entities.data[e->previous_sibling.value].next_sibling = result;
	}

	return result;
}

function MetaEntityID
meta_entity_reference(MetaContext *ctx, str8 name, MetaLocation location)
{
	MetaEntityID result = {0};
	Temp scratch;
	DeferLoop(scratch = temp_begin(ctx->scratch), temp_end(scratch)) {
		str8 ref_name = push_str8_from_parts(ctx->scratch, str8(""), str8("R"), name);
		result = meta_intern_entity(ctx, ref_name, MetaEntityKind_Reference,
		                            meta_root_entity_id(ctx), location, 1);
		MetaEntity *r = meta_entity(ctx, result);
		if (r->reference.reference_count == 0)
			ctx->entity_names.data[result.value] = push_str8(ctx->arena, ref_name);
		r->reference.reference_count++;
		r->reference.reference_name = name;
	}
	return result;
}

function MetaEntityID
meta_entity_reference_reference(MetaContext *ctx, str8 name, str8 scope_name, MetaLocation location,
                                MetaEntityID parent, str8 prefix)
{
	MetaEntityID result = {0};
	// NOTE(rnp): base reference
	MetaEntityID ref_id = meta_entity_reference(ctx, name, location);

	Temp scratch;
	DeferLoop(scratch = temp_begin(ctx->scratch), temp_end(scratch)) {
		str8 refref_name = push_str8_from_parts(ctx->scratch, str8(""), prefix, str8("RR"), name);
		result = meta_intern_entity(ctx, refref_name, MetaEntityKind_ReferenceReference,
		                            parent, location, 1);

		MetaEntity *rr = meta_entity(ctx, result);
		if (rr->reference.reference_count == 0)
			ctx->entity_names.data[result.value] = push_str8(ctx->arena, refref_name);
		rr->reference.reference_count++;
		rr->reference.reference_name = name;
		rr->reference.resolved_id    = ref_id;
		rr->reference.scope_name     = scope_name;
	}
	return result;
}

function MetaEntityID
meta_entity_first_child_of_kind(MetaContext *ctx, MetaEntity *e, MetaEntityKind kind)
{
	MetaEntityID result = {0};
	MetaEntityID child  = e->first_child;
	if (child.value) do {
		if (ctx->entities.data[child.value].kind == kind) {
			result = child;
			break;
		}
		child = ctx->entities.data[child.value].next_sibling;
	} while (child.value != e->first_child.value);
	return result;
}

function void
meta_expansion_string_split(str8 string, str8 *left, str8 *inner, str8 *remainder, MetaLocation loc)
{
	b32 found = 0;
	for (u8 *s = string.data, *e = s + string.length; (s + 1) != e; s++) {
		u32 val  = (u32)'$'  << 8u | (u32)'(';
		u32 test = (u32)s[0] << 8u | s[1];
		if (test == val) {
			if (left) {
				left->data   = string.data;
				left->length = s - string.data;
			}

			u8 *start = s + 2;
			while (s != e && *s != ')') s++;
			if (s == e) {
				meta_compiler_error_message(loc, "unterminated expansion in raw string:\n  %.*s\n",
				                            (s32)string.length, string.data);
				fprintf(stderr, "  %.*s^\n", (s32)(start - string.data), "");
				meta_error();
			}

			if (inner) {
				inner->data   = start;
				inner->length = s - start;
			}

			if (remainder) {
				remainder->data   = s + 1;
				remainder->length = string.length - (remainder->data - string.data);
			}
			found = 1;
			break;
		}
	}
	if (!found) {
		if (left)      *left      = string;
		if (inner)     *inner     = (str8){0};
		if (remainder) *remainder = (str8){0};
	}
}

function MetaExpansionPart *
meta_push_expansion_part(MetaContext *ctx, Arena *arena, MetaExpansionPartList *parts,
                         MetaExpansionPartKind kind, str8 string, MetaEntity *table, MetaLocation loc)
{
	MetaExpansionPart *result = da_push(arena, parts);

	result->kind = kind;
	switch (kind) {
	case MetaExpansionPartKind_Alignment:
	case MetaExpansionPartKind_Conditional:
	{}break;

	case MetaExpansionPartKind_EvalKind:
	case MetaExpansionPartKind_EvalKindCount:
	case MetaExpansionPartKind_Reference:
	{
		assert(meta_entity_kind_is_table[table->kind]);
		MetaTable *t = &table->table;

		da_count index = meta_lookup_string_slow(t->fields, t->field_count, string);
		result->strings = t->entries[index];
		if (index < 0) {
			/* TODO(rnp): fix this location to point directly at the field in the string */
			str8 table_name = ctx->entity_names.data[da_index(table, &ctx->entities)];
			meta_compiler_error(loc, "table \"%.*s\" does not contain member: %.*s\n",
			                    (s32)table_name.length, table_name.data, (s32)string.length, string.data);
		}
	}break;

	case MetaExpansionPartKind_String:{ result->string = string; }break;
	InvalidDefaultCase;
	}
	return result;
}

#define META_EXPANSION_TOKEN_LIST \
	X('|', Alignment) \
	X('%', TypeEval) \
	X('#', TypeEvalElements) \
	X('"', Quote) \
	X('-', Dash) \
	X('>', GreaterThan) \
	X('<', LessThan) \

typedef enum {
	MetaExpansionToken_EOF,
	MetaExpansionToken_Identifier,
	MetaExpansionToken_Number,
	MetaExpansionToken_String,
	#define X(__1, kind, ...) MetaExpansionToken_## kind,
	META_EXPANSION_TOKEN_LIST
	#undef X
	MetaExpansionToken_Count,
} MetaExpansionToken;

read_only global str8 meta_expansion_token_strings[] = {
	str8_comp("EOF"),
	str8_comp("Identifier"),
	str8_comp("Number"),
	str8_comp("String"),
	#define X(s, kind, ...) str8_comp(#s),
	META_EXPANSION_TOKEN_LIST
	#undef X
};

typedef	struct {
	str8 s;
	union {
		s64  number;
		str8 string;
	};
	str8 save;
	MetaLocation loc;
} MetaExpansionParser;

#define meta_expansion_save(v)    (v)->save = (v)->s
#define meta_expansion_restore(v) swap((v)->s, (v)->save)
#define meta_expansion_commit(v)  meta_expansion_restore(v)

#define meta_expansion_expected(loc, e, g) \
	meta_compiler_error(loc, "invalid expansion string: expected %.*s after %.*s\n", \
	                    (s32)meta_expansion_token_strings[e].length, meta_expansion_token_strings[e].data, \
	                    (s32)meta_expansion_token_strings[g].length, meta_expansion_token_strings[g].data)

function str8
meta_expansion_extract_string(MetaExpansionParser *p)
{
	str8 result = {.data = p->s.data};
	for (; result.length < p->s.length; result.length++) {
		b32 done = 0;
		switch (p->s.data[result.length]) {
		#define X(t, ...) case t:
		META_EXPANSION_TOKEN_LIST
		#undef X
		case ' ':
		{done = 1;}break;
		default:{}break;
		}
		if (done) break;
	}
	p->s.data   += result.length;
	p->s.length -= result.length;
	return result;
}

function MetaExpansionToken
meta_expansion_token(MetaExpansionParser *p)
{
	MetaExpansionToken result = MetaExpansionToken_EOF;
	meta_expansion_save(p);
	if (p->s.length > 0) {
		b32 chop = 1;
		switch (p->s.data[0]) {
		#define X(t, kind, ...) case t:{ result = MetaExpansionToken_## kind; }break;
		META_EXPANSION_TOKEN_LIST
		#undef X
		default:{
			chop = 0;
			if (Between(p->s.data[0], '0', '9')) result = MetaExpansionToken_Number;
			else                                 result = MetaExpansionToken_Identifier;
		}break;
		}
		if (chop) {
			str8_chop(&p->s, 1);
			p->s = str8_trim(p->s);
		}

		switch (result) {
		case MetaExpansionToken_Number:{
			NumberConversion integer = integer_from_str8(p->s);
			if (integer.result != NumberConversionResult_Success) {
				/* TODO(rnp): point at start */
				meta_compiler_error(p->loc, "invalid integer in expansion string\n");
			}
			p->number = integer.S64;
			p->s      = integer.unparsed;
		}break;
		case MetaExpansionToken_Identifier:{ p->string = meta_expansion_extract_string(p); }break;
		default:{}break;
		}
		p->s = str8_trim(p->s);
	}
	return result;
}

function MetaExpansionPart *
meta_expansion_start_conditional(MetaContext *ctx, Arena *arena, MetaExpansionPartList *ops,
                                 MetaExpansionParser *p, MetaExpansionToken token, b32 negate)
{
	MetaExpansionPart *result = meta_push_expansion_part(ctx, arena, ops, MetaExpansionPartKind_Conditional,
	                                                     str8(""), 0, p->loc);
	switch (token) {
	case MetaExpansionToken_Number:{
		result->conditional.lhs.kind   = MetaExpansionConditionalArgumentKind_Number;
		result->conditional.lhs.number = negate ? -p->number : p->number;
	}break;
	default:{}break;
	}
	return result;
}

function void
meta_expansion_end_conditional(MetaExpansionPart *ep, MetaExpansionParser *p, MetaExpansionToken token, b32 negate)
{
	if (ep->conditional.rhs.kind != MetaExpansionConditionalArgumentKind_Invalid) {
		meta_compiler_error(p->loc, "invalid expansion conditional: duplicate right hand expression: '%.*s'\n",
		                    (s32)p->save.length, p->save.data);
	}
	switch (token) {
	case MetaExpansionToken_Number:{
		ep->conditional.rhs.kind   = MetaExpansionConditionalArgumentKind_Number;
		ep->conditional.rhs.number = negate ? -p->number : p->number;
	}break;
	default:{}break;
	}
}

function MetaExpansionPartList
meta_generate_expansion_set(MetaContext *ctx, Arena *arena, str8 expansion_string, MetaEntity *table, MetaLocation loc)
{
	MetaExpansionPartList result = {0};
	str8 left = {0}, inner, remainder = expansion_string;
	do {
		meta_expansion_string_split(remainder, &left, &inner, &remainder, loc);
		if (left.length)  meta_push_expansion_part(ctx, arena, &result, MetaExpansionPartKind_String, left, table, loc);
		if (inner.length) {
			MetaExpansionParser p[1] = {{.s = inner, .loc = loc}};

			MetaExpansionPart *test_part = 0;
			b32 count_test_parts = 0;

			for (MetaExpansionToken token = meta_expansion_token(p);
			     token != MetaExpansionToken_EOF;
			     token = meta_expansion_token(p))
			{
				if (count_test_parts) test_part->conditional.instruction_skip++;
				switch (token) {
				case MetaExpansionToken_Alignment:{
					meta_push_expansion_part(ctx, arena, &result, MetaExpansionPartKind_Alignment, p->s, table, loc);
				}break;

				case MetaExpansionToken_Identifier:{
					meta_push_expansion_part(ctx, arena, &result, MetaExpansionPartKind_Reference, p->string, table, loc);
				}break;

				case MetaExpansionToken_TypeEval:
				case MetaExpansionToken_TypeEvalElements:
				{
					if (meta_expansion_token(p) != MetaExpansionToken_Identifier) {
						loc.column += (u32)(p->save.data - expansion_string.data);
						meta_expansion_expected(loc, MetaExpansionToken_Identifier, token);
					}
					MetaExpansionPartKind kind = token == MetaExpansionToken_TypeEval ?
					                                      MetaExpansionPartKind_EvalKind :
					                                      MetaExpansionPartKind_EvalKindCount;
					meta_push_expansion_part(ctx, arena, &result, kind, p->string, table, loc);
				}break;

				case MetaExpansionToken_Quote:{
					u8 *point = p->s.data;
					str8 string = meta_expansion_extract_string(p);
					token = meta_expansion_token(p);
					if (token != MetaExpansionToken_Quote) {
						loc.column += (u32)(point - expansion_string.data);
						/* TODO(rnp): point at start */
						meta_compiler_error(loc, "unterminated string in expansion\n");
					}
					meta_push_expansion_part(ctx, arena, &result, MetaExpansionPartKind_String, string, table, loc);
				}break;

				case MetaExpansionToken_Dash:{
					token = meta_expansion_token(p);
					switch (token) {
					case MetaExpansionToken_GreaterThan:{
						if (!test_part) goto error;
						if (test_part->conditional.lhs.kind == MetaExpansionConditionalArgumentKind_Invalid ||
						    test_part->conditional.rhs.kind == MetaExpansionConditionalArgumentKind_Invalid)
						{
							b32 lhs = test_part->conditional.lhs.kind == MetaExpansionConditionalArgumentKind_Invalid;
							b32 rhs = test_part->conditional.rhs.kind == MetaExpansionConditionalArgumentKind_Invalid;
							if (lhs && rhs)
								meta_compiler_error(loc, "expansion string test terminated without arguments\n");
							meta_compiler_error(loc, "expansion string test terminated without %s argument\n",
							                    lhs? "left" : "right");
						}
						count_test_parts = 1;
					}break;
					case MetaExpansionToken_Number:{
						if (test_part) meta_expansion_end_conditional(test_part, p, token, 1);
						else           test_part = meta_expansion_start_conditional(ctx, arena, &result, p, token, 1);
					}break;
					default:{ goto error; }break;
					}
				}break;

				case MetaExpansionToken_Number:{
					if (test_part) meta_expansion_end_conditional(test_part, p, token, 0);
					else           test_part = meta_expansion_start_conditional(ctx, arena, &result, p, token, 0);
				}break;

				case MetaExpansionToken_GreaterThan:
				case MetaExpansionToken_LessThan:
				{
					if (test_part && test_part->conditional.op != MetaExpansionOperation_Invalid) goto error;
					if (!test_part) {
						if (result.count == 0) {
							meta_compiler_error(p->loc, "invalid expansion conditional: missing left hand side\n");
						}

						str8 *strings = result.data[result.count - 1].strings;
						MetaExpansionPartKind last_kind = result.data[result.count - 1].kind;
						if (last_kind != MetaExpansionPartKind_EvalKindCount &&
						    last_kind != MetaExpansionPartKind_Reference)
						{
							meta_compiler_error(p->loc, "invalid expansion conditional: left hand side not numeric\n");
						}
						result.count--;
						test_part = meta_expansion_start_conditional(ctx, arena, &result, p, token, 0);
						if (last_kind == MetaExpansionPartKind_EvalKindCount) {
							test_part->conditional.lhs.kind = MetaExpansionConditionalArgumentKind_Evaluation;
						} else {
							test_part->conditional.lhs.kind = MetaExpansionConditionalArgumentKind_Reference;
						}
						test_part->conditional.lhs.strings = strings;
					}
					test_part->conditional.op = token == MetaExpansionToken_LessThan ?
					                                     MetaExpansionOperation_LessThan :
					                                     MetaExpansionOperation_GreaterThan;
				}break;

				error:
				default:
				{
					meta_compiler_error(loc, "invalid nested %.*s in expansion string\n",
					                    (s32)meta_expansion_token_strings[token].length,
					                    meta_expansion_token_strings[token].data);
				}break;
				}
			}
		}
	} while (remainder.length);
	return result;
}

function da_count
meta_expand_table_entity_id(MetaContext *ctx, MetaEntry *e)
{
	assert(e->kind == MetaEntryKind_Expand);

	/* TODO(rnp): for now this requires that the @Table came first */
	meta_entry_argument_expected(e, str8("table_name"));
	str8 table_name = meta_entry_argument_expect(e, 0, MetaEntryArgumentKind_String).string;

	da_count result = meta_lookup_string_slow(ctx->entity_names.data, ctx->entity_names.count, table_name);

	if (result < 0) meta_entry_error(e, "undefined table %.*s\n", (s32)table_name.length, table_name.data);

	MetaEntity *table = ctx->entities.data + result;
	if (!meta_entity_kind_is_table[table->kind]) {
		str8 old_kind    = meta_entity_kind_names[table->kind];
		str8 wanted_kind = meta_entity_kind_names[MetaEntityKind_Table];
		meta_entry_error(e, "%.*s previously defined as %.*s but should be %.*s\n",
		                 (s32)table_name.length,  table_name.data,
		                 (s32)old_kind.length,    old_kind.data,
		                 (s32)wanted_kind.length, wanted_kind.data);
	}

	return result;
}

function str8
meta_expand_parts_to_str8_at_index(MetaContext *ctx, u64 table_index, MetaExpansionPartList parts)
{
	Stream sb = arena_stream(ctx->arena);
	for EachIndex((u64)parts.count, part) {
		MetaExpansionPart *p = parts.data + part;
		u32 index = 0;
		if (p->kind == MetaExpansionPartKind_Reference) index = table_index;
		stream_append_str8(&sb, p->strings[index]);
	}
	str8 result = arena_stream_commit(ctx->arena, &sb);
	return result;
}

function void
meta_pack_table_begin(MetaEntry *e, MetaTable *t)
{
	switch (e->kind) {

	case MetaEntryKind_Enumeration:
	case MetaEntryKind_Flags:
	{
		read_only local_persist str8 enumeration_fields[] = {str8_comp("name")};
		t->fields      = enumeration_fields;
		t->field_count = countof(enumeration_fields);
	}break;

	case MetaEntryKind_Struct:
	case MetaEntryKind_Union:
	{
		meta_entry_argument_expected_(e, 0, 0);
		#define X(_i, name, ...) str8_comp(#name),
		read_only local_persist str8 struct_fields[] = {META_STRUCT_FIELDS};
		#undef X
		t->fields      = struct_fields;
		t->field_count = countof(struct_fields);
	}break;

	case MetaEntryKind_Table:{
		meta_entry_argument_expected(e, str8("[field ...]"));
		MetaEntryArgument fields = meta_entry_argument_expect(e, 0, MetaEntryArgumentKind_Array);
		t->fields      = fields.strings;
		t->field_count = (u32)fields.count;
	}break;

	InvalidDefaultCase;
	}
}

function s64
meta_pack_table_entity(MetaContext *ctx, MetaEntry *e, s64 entry_count, str8 name, MetaEntityID parent)
{
	MetaEntityKind entity_kind = MetaEntityKind_Nil;
	switch (e->kind) {
	case MetaEntryKind_Enumeration:{  entity_kind = MetaEntityKind_Enumeration;   }break;
	case MetaEntryKind_Flags:{        entity_kind = MetaEntityKind_Flags;         }break;
	case MetaEntryKind_Struct:{       entity_kind = MetaEntityKind_Struct;        }break;
	case MetaEntryKind_Table:{        entity_kind = MetaEntityKind_Table;         }break;
	case MetaEntryKind_Union:{        entity_kind = MetaEntityKind_Union;         }break;
	InvalidDefaultCase;
	}

	MetaEntityID entity_id = meta_intern_entity(ctx, name, entity_kind, parent, e->location, 0);

	MetaTable table = {0}, *t = &table;
	meta_pack_table_begin(e, t);

	b32 structure = e->kind == MetaEntryKind_Struct ||
	                e->kind == MetaEntryKind_Union;

	MetaEntryScope scope = meta_entry_extract_scope(e, entry_count);
	Temp scratch;
	if (scope.consumed > 1)
	DeferLoop(scratch = temp_begin(ctx->scratch), temp_end(scratch))
	{
		// NOTE(rnp): count expands
		s64 expand_count = 0;
		for (MetaEntry *row = scope.start; row != scope.one_past_last; row++)
			if (row->kind == MetaEntryKind_Expand)
				expand_count++;

		// NOTE(rnp): extract expand tables
		da_count *table_ids = 0;
		s64 table_id_index = 0;
		if (expand_count > 0) {
			table_ids = push_array(ctx->scratch, da_count, expand_count);
			for (MetaEntry *row = scope.start; row != scope.one_past_last; row++)
				if (row->kind == MetaEntryKind_Expand)
					table_ids[table_id_index++] = meta_expand_table_entity_id(ctx, row);
		}

		table_id_index = 0;
		for (MetaEntry *row = scope.start; row != scope.one_past_last; row++) {
			if (row->kind != MetaEntryKind_Array &&
			    row->kind != MetaEntryKind_Expand &&
			    row->kind != MetaEntryKind_String)
			{
				meta_entry_nesting_error(row, e->kind);
			}

			MetaEntryArgument entries = {.count = 1};

			if (row->kind == MetaEntryKind_Expand) {
				if (row + 1 == scope.one_past_last || (
				    row[1].kind != MetaEntryKind_Array &&
				    row[1].kind != MetaEntryKind_String))
				{
					meta_entry_nesting_error(row + 1, row->kind);
				}

				if (row[1].kind == MetaEntryKind_Array)
					entries.count = meta_entry_argument_expect(row + 1, 0, MetaEntryArgumentKind_Array).count;
			}

			if (row->kind == MetaEntryKind_Array)
				entries.count = meta_entry_argument_expect(row, 0, MetaEntryArgumentKind_Array).count;

			if (structure && entries.count != 2 && entries.count != 3) {
				meta_compiler_error(row->location, "incorrect field count for @%s entry got: %zu expected: "
				                    "[name type (elements)]\n", meta_entry_kind_strings[e->kind],
				                    (size_t)entries.count);
			} else if (!structure && entries.count != t->field_count) {
				meta_compiler_error_message(row->location, "incorrect field count for @%s entry got: %zu expected: %u\n",
				                            meta_entry_kind_strings[e->kind], (size_t)entries.count, t->field_count);
				fprintf(stderr, "  fields: [");
				for (u64 i = 0; i < t->field_count; i++) {
					if (i != 0) fprintf(stderr, " ");
					fprintf(stderr, "%.*s", (s32)t->fields[i].length, t->fields[i].data);
				}
				fprintf(stderr, "]\n");
				meta_error();
			}

			if (row->kind == MetaEntryKind_Expand) {
				t->entry_count += ctx->entities.data[table_ids[table_id_index++]].table.entry_count;
				// NOTE(rnp): skip expand argument
				row++;
			} else {
				t->entry_count++;
			}
		}

		t->entries = push_array(ctx->arena, str8 *, t->field_count);
		for (u32 field = 0; field < t->field_count; field++)
			t->entries[field] = push_array(ctx->arena, str8, t->entry_count);

		u32 row_index = 0;
		table_id_index = 0;
		for (MetaEntry *row = scope.start; row != scope.one_past_last; row++) {
			u64 argument_count = row->arguments ? row->arguments->count : 1;
			if (row->kind == MetaEntryKind_Expand) {
				row++;
				argument_count = row->arguments ? row->arguments->count : 1;

				MetaEntity *new_table = ctx->entities.data + table_ids[table_id_index++];

				u32 working_row_index = row_index;
				for EachIndex(argument_count, it) {
					working_row_index = row_index;
					str8 expand = row->arguments ? row->arguments->strings[it] : row->name;
					MetaExpansionPartList parts = meta_generate_expansion_set(ctx, ctx->scratch, expand, new_table, row->location);
					for EachIndex(new_table->table.entry_count, entry_index)
						t->entries[it][working_row_index++] = meta_expand_parts_to_str8_at_index(ctx, entry_index, parts);
				}

				for (; row_index < working_row_index; row_index++)
					if (structure && argument_count == 2)
						t->entries[2][row_index] = str8("1");

			} else {
				str8 *fs = &row->name;
				if (row->arguments)
					fs = row->arguments->strings;

				for (u32 field = 0; field < t->field_count; field++)
					t->entries[field][row_index] = fs[field];

				// NOTE(rnp): if we are filling out a struct the array element count is optional
				// and defaults to 1. fill this out here for uniformity elsewhere in the code
				if (structure && argument_count == 2)
					t->entries[2][row_index] = str8("1");
				row_index++;
			}
		}
	}

	MetaEntity *entity = meta_entity(ctx, entity_id);
	entity->table = table;

	switch (e->kind) {
	case MetaEntryKind_Enumeration:
	case MetaEntryKind_Flags:
	case MetaEntryKind_Struct:
	case MetaEntryKind_Table:
	case MetaEntryKind_Union:
	{}break;

	InvalidDefaultCase;
	}

	return scope.consumed;
}

function s64
meta_pack_references(MetaContext *ctx, MetaEntry *entries, s64 entry_count, MetaEntityID parent,
                     str8 scope_name, str8 prefix)
{
	MetaEntryScope scope = meta_entry_extract_scope(entries, entry_count);
	for (MetaEntry *e = scope.start; e < scope.one_past_last; e++) {
		switch (e->kind) {
		case MetaEntryKind_Struct:
		case MetaEntryKind_Union:
		{
			meta_entity_reference_reference(ctx, e->name, scope_name, e->location, parent, prefix);
		}break;
		default:{meta_entry_nesting_error(e, entries->kind);}break;
		}
	}
	return scope.consumed;
}

function str8 *
meta_expand_to_str8_array(MetaContext *ctx, str8 expand, MetaEntity *table, MetaLocation location)
{
	str8 *result = 0;
	Temp scratch;
	DeferLoop(scratch = temp_begin(ctx->scratch), temp_end(scratch))
	{
		MetaExpansionPartList parts = meta_generate_expansion_set(ctx, ctx->scratch, expand, table, location);
		result = push_array(ctx->arena, str8, table->table.entry_count);
		for EachIndex(table->table.entry_count, expansion)
			result[expansion] = meta_expand_parts_to_str8_at_index(ctx, expansion, parts);
	}
	return result;
}

function s64
meta_expand(MetaContext *ctx, MetaEntry *e, s64 entry_count, MetaEmitOperationList *ops)
{
	assert(e->kind == MetaEntryKind_Expand);

	MetaEntity *table = ctx->entities.data + meta_expand_table_entity_id(ctx, e);
	str8 table_name = ctx->entity_names.data[da_index(table, &ctx->entities)];

	MetaEntryScope scope = meta_entry_extract_scope(e, entry_count);
	for (MetaEntry *row = scope.start; row != scope.one_past_last; row++) {
		switch (row->kind) {
		case MetaEntryKind_String:{
			if (!ops) goto error;

			MetaExpansionPartList parts = meta_generate_expansion_set(ctx, ctx->arena, row->name, table, row->location);

			MetaEmitOperation *op = da_push(ctx->arena, ops);
			op->kind     = MetaEmitOperationKind_Expand;
			op->location = row->location;
			op->expansion_operation.parts           = parts.data;
			op->expansion_operation.part_count      = (u32)parts.count;
			op->expansion_operation.table_entity_id = da_index(table, &ctx->entities);
		}break;

		case MetaEntryKind_Enumeration:
		case MetaEntryKind_Flags:
		{
			if (ops) meta_entry_nesting_error(row, MetaEntryKind_Expand);

			meta_entry_argument_expected(row, str8("`raw_string`"));
			str8 expand = meta_entry_argument_expect(row, 0, MetaEntryArgumentKind_String).string;

			MetaEntityKind entity_kind = row->kind == MetaEntryKind_Flags ? MetaEntityKind_Flags : MetaEntityKind_Enumeration;
			MetaEntityID entity_id = meta_intern_entity(ctx, row->name, entity_kind, meta_root_entity_id(ctx),
			                                            row->location, 0);
			MetaEntry entry = {.kind = row->kind};
			MetaEntity *new = ctx->entities.data + entity_id.value;
			meta_pack_table_begin(&entry, &new->table);
			new->table.entries     = push_array(ctx->arena, str8 *, new->table.field_count);
			new->table.entry_count = table->table.entry_count;
			new->table.entries[0]  = meta_expand_to_str8_array(ctx, expand, table, row->location);
		}break;

		case MetaEntryKind_Struct:
		case MetaEntryKind_Union:
		{
			if (ops) meta_entry_nesting_error(row, MetaEntryKind_Expand);
			MetaEntryArgument fields = meta_entry_argument_expect(row, 0, MetaEntryArgumentKind_Array);
			if (fields.count != 2 && fields.count != 3) {
				meta_compiler_error(row->location, "Invalid arguments in table expansion: '%.*s'\n"
				                                   "Union expansion requires field names for member names, type names, "
				                                   "and optionally element counts.\n", (s32)table_name.length, table_name.data);
			}

			MetaEntityKind entity_kind = row->kind == MetaEntryKind_Struct ? MetaEntityKind_Struct : MetaEntityKind_Union;
			MetaEntityID   entity_id   = meta_intern_entity(ctx, row->name, entity_kind,
			                                                meta_root_entity_id(ctx), row->location, 0);
			MetaEntry entry = {.kind = row->kind};
			MetaEntity *new = ctx->entities.data + entity_id.value;
			meta_pack_table_begin(&entry, &new->table);
			new->table.entries     = push_array(ctx->arena, str8 *, new->table.field_count);
			new->table.entry_count = table->table.entry_count;
			new->table.entries[MetaStructField_Name] = meta_expand_to_str8_array(ctx, fields.strings[0],
			                                                                     table, row->location);
			new->table.entries[MetaStructField_Type] = meta_expand_to_str8_array(ctx, fields.strings[1],
			                                                                     table, row->location);
			if (fields.count == 3) {
				new->table.entries[MetaStructField_Elements] = meta_expand_to_str8_array(ctx, fields.strings[2],
				                                                                         table, row->location);
			} else {
				new->table.entries[MetaStructField_Elements] = push_array(ctx->arena, str8, table->table.entry_count);
				for EachIndex(new->table.entry_count, eid)
					new->table.entries[MetaStructField_Elements][eid] = str8("1");
			}
		}break;

		error:
		default:
		{
			meta_entry_nesting_error(row, MetaEntryKind_Expand);
		}break;
		}
	}
	return scope.consumed;
}

function MetaKind
meta_map_kind(str8 kind, str8 table_name, MetaLocation location)
{
	s64 id = meta_lookup_string_slow(meta_kind_meta_types, MetaKind_Count, kind);
	if (id < 0) {
		meta_compiler_error(location, "Invalid Kind in '%.*s' table expansion: %.*s\n",
		                    (s32)table_name.length, table_name.data, (s32)kind.length, kind.data);
	}
	MetaKind result = (MetaKind)id;
	return result;
}

function void
meta_pack_constant(MetaContext *ctx, MetaEntry *e)
{
	assert(e->kind == MetaEntryKind_Constant);

	MetaEntityID entity_id = meta_intern_entity(ctx, e->name, MetaEntityKind_Constant,
	                                            meta_root_entity_id(ctx), e->location, 0);

	meta_entry_argument_expected(e, str8("value"));
	str8 value = meta_entry_argument_expect(e, 0, MetaEntryArgumentKind_String).string;

	NumberConversion number = number_from_str8(value);
	if (number.result != NumberConversionResult_Success || number.unparsed.length != 0) {
		meta_compiler_error(e->location, "Invalid integer in definition of Constant '%.*s': %.*s\n",
		                    (s32)e->name.length, e->name.data, (s32)value.length, value.data);
	}

	MetaEntity *entity = meta_entity(ctx, entity_id);
	if (number.kind == NumberConversionKind_Float) {
		entity->constant.kind = MetaConstantKind_Float;
		entity->constant.F64  = number.F64;
	} else {
		entity->constant.kind = MetaConstantKind_Integer;
		entity->constant.U64  = number.U64;
	}
}

function void
metagen_push_byte_array(MetaprogramContext *m, str8 bytes)
{
	for (s64 i = 0; i < bytes.length; i++) {
		b32 end_line = (i != 0) && (i % 16) == 0;
		if (i != 0) meta_push(m, end_line ? str8(",") : str8(", "));
		if (end_line) meta_end_line(m);
		if ((i % 16) == 0) meta_indent(m);
		meta_push(m, str8("0x"));
		meta_push_u64_hex(m, bytes.data[i]);
	}
	meta_end_line(m);
}

function void
metagen_push_table(MetaprogramContext *m, str8 row_start, str8 row_end, str8 **column_strings, u64 rows, u64 columns)
{
	Temp scratch;
	DeferLoop(scratch = temp_begin(m->scratch), temp_end(scratch))
	{
		u32 *column_widths = 0;
		if (columns > 1) {
			column_widths = push_array(m->scratch, u32, columns - 1);
			for (u64 column = 0; column < columns - 1; column++) {
				str8 *strings = column_strings[column];
				for (u64 row = 0; row < rows; row++)
					column_widths[column] = Max(column_widths[column], (u32)strings[row].length);
			}
		}

		for (u64 row = 0; row < rows; row++) {
			meta_begin_line(m, row_start);
			for (u64 column = 0; column < columns; column++) {
				str8 text = column_strings[column][row];
				meta_push(m, text);
				s32 pad = columns > 1 ? 1 : 0;
				if (column_widths && column < columns - 1)
					pad += (s32)column_widths[column] - (s32)text.length;
				if (column < columns - 1) meta_pad(m, ' ', pad);
			}
			meta_end_line(m, row_end);
		}
	}
}

function s64
meta_expansion_part_conditional_argument(MetaExpansionConditionalArgument a, u32 entry,
                                         str8 table_name, MetaLocation loc)
{
	s64 result = 0;
	switch (a.kind) {
	case MetaExpansionConditionalArgumentKind_Number:{
		result = a.number;
	}break;

	case MetaExpansionConditionalArgumentKind_Evaluation:
	{
		str8 string   = a.strings[entry];
		MetaKind kind = meta_map_kind(string, table_name, loc);
		result        = meta_kind_elements[kind];
	}break;

	case MetaExpansionConditionalArgumentKind_Reference:{
		str8 string = a.strings[entry];
		NumberConversion integer = integer_from_str8(string);
		if (integer.result != NumberConversionResult_Success) {
			meta_compiler_error(loc, "Invalid integer in '%.*s' table expansion: %.*s\n",
			                    (s32)table_name.length, table_name.data, (s32)string.length, string.data);
		}
		result = integer.S64;
	}break;

	InvalidDefaultCase;
	}

	return result;
}

function b32
meta_expansion_part_conditional(MetaExpansionPart *p, u32 entry, str8 table_name, MetaLocation loc)
{
	assert(p->kind == MetaExpansionPartKind_Conditional);
	b32 result = 0;
	s64 lhs = meta_expansion_part_conditional_argument(p->conditional.lhs, entry, table_name, loc);
	s64 rhs = meta_expansion_part_conditional_argument(p->conditional.rhs, entry, table_name, loc);
	switch (p->conditional.op) {
	case MetaExpansionOperation_LessThan:{    result = lhs < rhs; }break;
	case MetaExpansionOperation_GreaterThan:{ result = lhs > rhs; }break;
	InvalidDefaultCase;
	}
	return result;
}

function void
metagen_run_emit(MetaprogramContext *m, MetaContext *ctx, MetaEmitOperationList *ops, str8 *evaluation_table)
{
	for (s64 opcode = 0; opcode < ops->count; opcode++) {
		MetaEmitOperation *op = ops->data + opcode;
		switch (op->kind) {
		case MetaEmitOperationKind_String:{ meta_push_line(m, op->string); }break;
		case MetaEmitOperationKind_FileBytes:{
			Temp scratch;
			DeferLoop(scratch = temp_begin(m->scratch), temp_end(scratch))
			{
				str8 filename = push_str8_from_parts(m->scratch, str8(OS_PATH_SEPARATOR), ctx->directory, op->string);
				str8 file     = os_read_entire_file(m->scratch, (c8 *)filename.data);
				m->indentation_level++;
				metagen_push_byte_array(m, file);
				m->indentation_level--;
			}
		}break;
		case MetaEmitOperationKind_Expand:{
			Temp scratch;
			DeferLoop(scratch = temp_begin(m->scratch), temp_end(scratch))
			{
				MetaEmitOperationExpansion *eop = &op->expansion_operation;
				MetaTable *t = &ctx->entities.data[eop->table_entity_id].table;
				str8 table_name = ctx->entity_names.data[eop->table_entity_id];

				u32 alignment_count  = 1;
				u32 evaluation_count = 0;
				for (u32 part = 0; part < eop->part_count; part++) {
					if (eop->parts[part].kind == MetaExpansionPartKind_Alignment)
						alignment_count++;
					if (eop->parts[part].kind == MetaExpansionPartKind_EvalKind ||
					    eop->parts[part].kind == MetaExpansionPartKind_EvalKindCount)
						evaluation_count++;
				}

				MetaKind **evaluation_columns = push_array(m->scratch, MetaKind *, evaluation_count);
				for (u32 column = 0; column < evaluation_count; column++)
					evaluation_columns[column] = push_array(m->scratch, MetaKind, t->entry_count);

				for (u32 part = 0; part < eop->part_count; part++) {
					u32 eval_column = 0;
					MetaExpansionPart *p = eop->parts + part;
					if (p->kind == MetaExpansionPartKind_EvalKind) {
						for (u32 entry = 0; entry < t->entry_count; entry++) {
							evaluation_columns[eval_column][entry] = meta_map_kind(p->strings[entry],
							                                                       table_name, op->location);
						}
						eval_column++;
					}
				}

				str8 **columns = push_array(m->scratch, str8 *, alignment_count);
				for (u32 column = 0; column < alignment_count; column++)
					columns[column] = push_array(m->scratch, str8, t->entry_count);

				Stream sb = arena_stream(m->scratch);
				for (u32 entry = 0; entry < t->entry_count; entry++) {
					u32 column      = 0;
					u32 eval_column = 0;
					for (u32 part = 0; part < eop->part_count; part++) {
						MetaExpansionPart *p = eop->parts + part;
						switch (p->kind) {
						case MetaExpansionPartKind_Alignment:{
							columns[column][entry] = arena_stream_commit_and_reset(m->scratch, &sb);
							column++;
						}break;

						case MetaExpansionPartKind_Conditional:{
							if (!meta_expansion_part_conditional(p, entry, table_name, op->location))
								part += p->conditional.instruction_skip;
						}break;

						case MetaExpansionPartKind_EvalKind:{
							str8 kind = evaluation_table[evaluation_columns[eval_column][entry]];
							stream_append_str8(&sb, kind);
						}break;

						case MetaExpansionPartKind_EvalKindCount:{
							stream_append_u64(&sb, meta_kind_elements[evaluation_columns[eval_column][entry]]);
						}break;

						case MetaExpansionPartKind_Reference:
						case MetaExpansionPartKind_String:
						{
							str8 string = p->kind == MetaExpansionPartKind_Reference ? p->strings[entry] : p->string;
							stream_append_str8(&sb, string);
						}break;
						}
					}

					columns[column][entry] = arena_stream_commit_and_reset(m->scratch, &sb);
				}
				metagen_push_table(m, str8(""), str8(""), columns, t->entry_count, alignment_count);
			}
		}break;
		InvalidDefaultCase;
		}
	}
	meta_end_line(m);
}

function s32
meta_struct_member_elements(MetaContext *ctx, MetaStruct *s, u32 member)
{
	assert(member < s->info.member_count);
	s32 result = s->elements[member];
	if (s->member_flags[member] & MetaBuildStructMemberFlag_ReferenceElements)
		result = (s32)meta_entity(ctx, (MetaEntityID){result})->constant.U64;
	if (s->member_flags[member] & MetaBuildStructMemberFlag_EnumerationCount)
		result = (s32)meta_entity(ctx, (MetaEntityID){result})->table.entry_count;
	return result;
}

function void
metagen_push_counted_enum_body(MetaprogramContext *m, str8 kind, str8 prefix, str8 mid, str8 suffix,
                               str8 *ids, s64 ids_count)
{
	s64 max_id_length = 0;
	for (s64 id = 0; id < ids_count; id++)
		max_id_length = Max(max_id_length, ids[id].length);

	for (s64 id = 0; id < ids_count; id++) {
		meta_begin_line(m, prefix, kind, ids[id]);
		meta_pad(m, ' ', 1 + (s32)(max_id_length - ids[id].length));
		meta_push(m, mid);
		meta_push_u64(m, (u64)id);
		meta_end_line(m, suffix);
	}
}

function void
metagen_push_counted_enum_body_from_ids(MetaprogramContext *m, str8 kind, str8 prefix, str8 mid, str8 suffix,
                                        da_count *ids, str8 *id_names, da_count ids_count)
{
	s64 max_id_length = 0;
	for (s64 id = 0; id < ids_count; id++)
		max_id_length = Max(max_id_length, id_names[ids[id]].length);

	for (s64 id = 0; id < ids_count; id++) {
		meta_begin_line(m, prefix, kind, id_names[ids[id]]);
		meta_pad(m, ' ', 1 + (s32)(max_id_length - id_names[ids[id]].length));
		meta_push(m, mid);
		meta_push_s64(m, id);
		meta_end_line(m, suffix);
	}
}

function void
metagen_push_c_enum(MetaprogramContext *m, str8 kind, b32 flags, str8 *ids, s64 ids_count)
{
	str8 kind_full = push_str8_from_parts(m->scratch, str8(""), kind, str8("_"));
	meta_begin_scope(m, str8("typedef enum {"));
	metagen_push_counted_enum_body(m, kind_full, str8(""), flags ? str8("= 1 << ") : str8("= "), str8(","), ids, ids_count);
	if (!flags) meta_push_line(m, kind_full, str8("Count,"));
	meta_end_scope(m, str8("} "), kind, str8(";\n"));
}

typedef enum {
	MetaPushStructStyle_C,
	MetaPushStructStyle_MATLAB,
	MetaPushStructStyle_Count,
} MetaPushStructStyle;

typedef struct {
	MetaPushStructStyle layout_style;
	MetaPushStructStyle union_style;
	MetaPushStructStyle element_count_style;
	str8 *base_types;
	u8   *base_type_element_count_scales;
	str8  prefix;
	str8  suffix;
	str8  str_element_prefix;
} MetaPushStructParameters;

function void
meta_push_struct_body(MetaContext *ctx, MetaprogramContext *m, MetaEntity *struct_entity,
                      MetaPushStructParameters p)
{
	struct stack_item {MetaEntity *se; u32 member_offset;} init[16];
	struct {
		struct stack_item *data;
		da_count count;
		da_count capacity;
	} stack = {init, 0, countof(init)};

	Temp scratch = temp_begin(m->scratch);

	u32 flattened_member_count = 0;

	*da_push(m->scratch, &stack) = (struct stack_item){struct_entity, 0};
	while (stack.count > 0) {
		stack.count--;
		MetaEntity *se = stack.data[stack.count].se;
		MetaStruct *s  = ctx->struct_infos + se->table.struct_info_id;
		u32 member     = stack.data[stack.count].member_offset;
		while (member < s->info.member_count) {
			if (s->members[member].length == 0) {
				assert(s->member_flags[member] & MetaStructMemberFlag_ReferenceType);
				MetaStruct *ss = ctx->struct_infos + ctx->entities.data[s->type_ids[member]].table.struct_info_id;
				if (ss->info.flags & MetaStructFlag_Union) {
					member++;
					flattened_member_count++;
				} else {
					*da_push(ctx->scratch, &stack) = (struct stack_item){se, member + 1};
					*da_push(ctx->scratch, &stack) = (struct stack_item){ctx->entities.data + s->type_ids[member], 0};
					break;
				}
			} else {
				member++;
				flattened_member_count++;
			}
		}
	}

	str8 *columns[2];
	columns[0] = push_array(m->scratch, str8, flattened_member_count);
	columns[1] = push_array(m->scratch, str8, flattened_member_count);

	u32 row = 0, scope = 0;
	*da_push(m->scratch, &stack) = (struct stack_item){struct_entity, 0};
	while (stack.count > 0) {
		stack.count--;
		MetaEntity *se = stack.data[stack.count].se;
		MetaStruct *s  = ctx->struct_infos + se->table.struct_info_id;
		u32 member     = stack.data[stack.count].member_offset;

		while (member < s->info.member_count) {
			b32  type_reference = (s->member_flags[member] & MetaStructMemberFlag_ReferenceType) != 0;
			s32  type_id        = s->type_ids[member];
			str8 member_name    = s->members[member];

			assert(member_name.length != 0 || type_reference);

			if (s->members[member].length == 0 &&
			    (p.union_style != MetaPushStructStyle_MATLAB || ctx->entities.data[type_id].kind != MetaEntityKind_Union))
			{
				*da_push(m->scratch, &stack) = (struct stack_item){se, member + 1};
				*da_push(m->scratch, &stack) = (struct stack_item){ctx->entities.data + type_id, 0};

				MetaStruct *ss = ctx->struct_infos + ctx->entities.data[type_id].table.struct_info_id;
				if (p.layout_style == MetaPushStructStyle_C && ss->info.flags & MetaStructFlag_Union) {
					metagen_push_table(m, p.prefix, p.suffix, columns, row, 2);
					meta_begin_scope(m, str8("union {"));
					row = 0;
					scope++;
				}

				break;
			} else {
				Stream sb = arena_stream(m->scratch);

				b32 enum_count         = (s->member_flags[member] & MetaBuildStructMemberFlag_EnumerationCount) != 0;
				b32 elements_reference = enum_count || (s->member_flags[member] & MetaBuildStructMemberFlag_ReferenceElements) != 0;
				// NOTE(rnp): member name column
				{
					read_only local_persist str8 elements_count_open[MetaPushStructStyle_Count] = {
						[MetaPushStructStyle_C]      = str8_comp("["),
						[MetaPushStructStyle_MATLAB] = str8_comp("("),
					};
					read_only local_persist str8 elements_count_close[MetaPushStructStyle_Count] = {
						[MetaPushStructStyle_C]      = str8_comp("]"),
						[MetaPushStructStyle_MATLAB] = str8_comp(")"),
					};
					read_only local_persist s32 name_column[MetaPushStructStyle_Count] = {
						[MetaPushStructStyle_C]      = 1,
						[MetaPushStructStyle_MATLAB] = 0,
					};

					u32 resolved_element_count = meta_struct_member_elements(ctx, s, member);

					if (type_reference && p.union_style == MetaPushStructStyle_MATLAB) {
						MetaEntity *re = ctx->entities.data + type_id;
						MetaStruct *rs = ctx->struct_infos + re->table.struct_info_id;
						if (member_name.length == 0) {
							assert(rs->info.flags & MetaStructFlag_Union);
							member_name = str8("data");
						}
						if (rs->info.flags & MetaStructFlag_Union)
							resolved_element_count *= rs->info.size;
					} else if (!type_reference && p.base_type_element_count_scales) {
						resolved_element_count *= p.base_type_element_count_scales[type_id];
					}

					if (resolved_element_count > 1 || p.element_count_style == MetaPushStructStyle_MATLAB) {
						stream_append_str8s(&sb, member_name, elements_count_open[p.layout_style]);
						if (elements_reference && p.element_count_style != MetaPushStructStyle_MATLAB) {
							stream_append_str8s(&sb, p.str_element_prefix, ctx->entity_names.data[s->elements[member]]);
							if (enum_count) stream_append_str8(&sb, str8("_Count"));
						} else {
							if (p.element_count_style == MetaPushStructStyle_MATLAB)
								stream_append_str8(&sb, str8("1,"));
							stream_append_u64(&sb, resolved_element_count);
						}
						stream_append_str8(&sb, elements_count_close[p.layout_style]);
						columns[name_column[p.layout_style]][row] = arena_stream_commit_and_reset(m->scratch, &sb);
					} else {
						columns[name_column[p.layout_style]][row] = member_name;
					}
				}

				// NOTE(rnp): type column
				{
					read_only local_persist s32 type_column[MetaPushStructStyle_Count] = {
						[MetaPushStructStyle_C]      = 0,
						[MetaPushStructStyle_MATLAB] = 1,
					};

					if (type_reference) {
						MetaEntity *re = ctx->entities.data + type_id;
						MetaStruct *rs = 0;

						if (meta_entity_kind_is_struct[re->kind])
							rs = ctx->struct_infos + re->table.struct_info_id;

						if (rs && rs->info.flags & MetaStructFlag_Union && p.union_style == MetaPushStructStyle_MATLAB) {
							stream_append_str8(&sb, p.base_types[MetaKind_U8]);
							if (p.layout_style == MetaPushStructStyle_MATLAB)
								stream_append_str8(&sb, str8("  % +"));
						} else if (re->kind == MetaEntityKind_Enumeration && p.layout_style == MetaPushStructStyle_MATLAB) {
							// NOTE(rnp): matlab enumerations are int32 if we make this uint32
							// MATLAB won't fuck up the type when the field is assigned
							stream_append_str8(&sb, p.base_types[MetaKind_U32]);
							if (p.layout_style == MetaPushStructStyle_MATLAB)
								stream_append_str8(&sb, str8(" % "));
						} else {
							if (p.layout_style == MetaPushStructStyle_MATLAB) {
								// NOTE(rnp): matlab has really broken requirements around sub structures
								// we can only use an opaque struct here
								//stream_append_str8(&sb, str8("struct % "));
							} else {
								str8 name = rs ? rs->info.name : ctx->entity_names.data[type_id];
								stream_append_str8s(&sb, p.str_element_prefix, name);
							}
						}

						if (p.layout_style == MetaPushStructStyle_MATLAB) {
							stream_append_str8s(&sb, p.str_element_prefix,
							                    rs ? rs->info.name : ctx->entity_names.data[type_id]);
						}

						columns[type_column[p.layout_style]][row] = arena_stream_commit_and_reset(m->scratch, &sb);
					} else {
						columns[type_column[p.layout_style]][row] = p.base_types[type_id];
					}
				}

				row++;
				member++;
			}
		}

		if (member == s->info.member_count && s->info.flags & MetaStructFlag_Union && p.layout_style == MetaPushStructStyle_C) {
			metagen_push_table(m, p.prefix, p.suffix, columns, row, 2);
			while (scope > 0) {
				meta_end_scope(m, str8("};"));
				scope--;
			}
			row = 0;
		}
	}
	metagen_push_table(m, p.prefix, p.suffix, columns, row, 2);

	temp_end(scratch);
}

function void
meta_push_matlab_properties(MetaprogramContext *m, MetaContext *ctx, MetaStruct *meta_struct)
{

	DeferLoop(meta_begin_scope(m, str8("properties")), meta_end_scope(m, str8("end")))
	{
		meta_push_struct_body(ctx, m, meta_entity(ctx, meta_struct->entity), (MetaPushStructParameters){
			.layout_style        = MetaPushStructStyle_MATLAB,
			.union_style         = MetaPushStructStyle_MATLAB,
			.element_count_style = MetaPushStructStyle_MATLAB,
			.base_types          = meta_kind_matlab_types,
			.suffix              = str8(""),
			.str_element_prefix  = str8(META_NAMESPACE_UPPER "."),
			.base_type_element_count_scales = meta_kind_elements,
		});
	}
}

read_only global str8 c_file_header = str8_comp(""
	"/* See LICENSE for license details. */\n\n"
	"// GENERATED CODE\n\n"
	"#include <stdint.h>\n\n"
);

function b32
metagen_emit_c_code(MetaContext *ctx, Arena *arena)
{
	os_make_directory("c" OS_PATH_SEPARATOR "generated");
	char *out_meta = "c" OS_PATH_SEPARATOR "generated" OS_PATH_SEPARATOR "zemp_bp.h";

	MetaprogramContext m[1] = {{.stream = arena_stream(arena), .scratch = ctx->scratch}};

	if (setjmp(compiler_jmp_buf))
		build_fatal("Failed to generate C Code");

	b32 result = 1;

	if (!needs_rebuild(out_meta, "ornot.meta"))
		return result;

	build_log_generate("C Header");

	meta_push(m, c_file_header);

	/////////////////////////
	// NOTE(rnp): constants
	{
		u32 integers = 0;
		u32 floats   = 0;

		for (da_count constant = 0; constant < ctx->entity_kind_counts[MetaEntityKind_Constant]; constant++) {
			da_count    id = ctx->entity_kind_ids[MetaEntityKind_Constant][constant];
			MetaEntity *e  = ctx->entities.data + id;
			if (e->constant.kind == MetaConstantKind_Integer) integers++;
			if (e->constant.kind == MetaConstantKind_Float)   floats++;
		}

		u32 row_alloc_count = Max(integers, floats);
		str8 *columns[2];
		columns[0] = push_array(m->scratch, str8, row_alloc_count);
		columns[1] = push_array(m->scratch, str8, row_alloc_count);

		u32 row_count;

		row_count = 0;
		for (da_count constant = 0; constant < ctx->entity_kind_counts[MetaEntityKind_Constant]; constant++) {
			da_count    id = ctx->entity_kind_ids[MetaEntityKind_Constant][constant];
			MetaEntity *e  = ctx->entities.data + id;
			if (e->constant.kind == MetaConstantKind_Integer) {
				u64 index = integer_width_index(e->constant.U64);
				Stream sb = arena_stream(m->scratch);
				stream_append_str8(&sb, str8("(0x"));
				stream_append_hex_u64_width(&sb, e->constant.U64, meta_integer_print_digits[index]);
				stream_append_str8(&sb, meta_integer_print_c_suffix[index]);
				columns[0][row_count] = ctx->entity_names.data[id];
				columns[1][row_count] = arena_stream_commit(m->scratch, &sb);
				row_count++;
			}
		}
		metagen_push_table(m, str8("#define " META_NAMESPACE_UPPER "_"), str8(")"), columns, row_count, 2);

		row_count = 0;
		if (integers && floats) meta_push_line(m, str8("\n"));
		for (da_count constant = 0; constant < ctx->entity_kind_counts[MetaEntityKind_Constant]; constant++) {
			da_count    id = ctx->entity_kind_ids[MetaEntityKind_Constant][constant];
			MetaEntity *e  = ctx->entities.data + id;
			if (e->constant.kind == MetaConstantKind_Float) {
				Stream sb = arena_stream(m->scratch);
				stream_append_str8(&sb, str8("("));
				stream_append_f64(&sb, e->constant.F64, 1000000);
				columns[0][row_count] = ctx->entity_names.data[id];
				columns[1][row_count] = arena_stream_commit(m->scratch, &sb);
				row_count++;
			}
		}
		metagen_push_table(m, str8("#define " META_NAMESPACE_UPPER), str8(")"), columns, row_count, 2);

		if (integers || floats) meta_push(m, str8("\n"));
	}

	arena_clear(m->scratch);

	/////////////////////////
	// NOTE(rnp): enumerants
	struct {MetaEntityKind kind; b32 flags;} enums[] = {
		{MetaEntityKind_Enumeration, 0},
		{MetaEntityKind_Flags,       1},
	};
	for EachElement(enums, it) {
		for (da_count kind = 0; kind < ctx->entity_kind_counts[enums[it].kind]; kind++) {
			da_count    id = ctx->entity_kind_ids[enums[it].kind][kind];
			MetaEntity *e  = ctx->entities.data + id;

			str8 enum_name = push_str8_from_parts(m->scratch, str8(""), str8(META_NAMESPACE_UPPER "_"),
			                                      ctx->entity_names.data[id]);
			metagen_push_c_enum(m, enum_name, enums[it].flags, e->table.entries[0], e->table.entry_count);
		}
	}

	arena_clear(m->scratch);

	//////////////////////
	// NOTE(rnp): structs
	{
		for EachElement(meta_struct_entity_kinds, kind_it) {
			if (meta_struct_emit[kind_it]) {
				for (da_count it = 0; it < ctx->entity_kind_counts[meta_struct_entity_kinds[kind_it]]; it++) {
					if (it != 0) meta_push(m, str8("\n"));
					da_count entity = ctx->entity_kind_ids[meta_struct_entity_kinds[kind_it]][it];
					str8 name = ctx->entity_names.data[entity];

					meta_begin_scope(m, str8("typedef struct " META_NAMESPACE_UPPER "_"), name, str8(" {")); {
						meta_push_struct_body(ctx, m, ctx->entities.data + entity, (MetaPushStructParameters){
							.layout_style        = MetaPushStructStyle_C,
							.union_style         = MetaPushStructStyle_C,
							.element_count_style = MetaPushStructStyle_C,
							.base_types          = meta_kind_base_c_types,
							.suffix              = str8(";"),
							.str_element_prefix  = str8(META_NAMESPACE_UPPER "_"),
							.base_type_element_count_scales = meta_kind_elements,
						});
					} meta_end_scope(m, str8("} " META_NAMESPACE_UPPER "_"), name, str8(";"));
				}
			}
		}
	}

	result = meta_write_and_reset(m, out_meta);

	return result;
}

read_only global str8 matlab_file_header = str8_comp(""
	"% See LICENSE for license details.\n\n"
	"% GENERATED CODE\n"
);

function b32
metagen_emit_matlab_code(MetaContext *ctx, Arena *arena)
{
	b32 result = 1;

	char *out_test = "matlab"                 OS_PATH_SEPARATOR
	                 "+" META_NAMESPACE_UPPER OS_PATH_SEPARATOR
	                 "HeaderV2.m";

	if (!needs_rebuild(out_test, "ornot.meta"))
		return result;

	build_log_generate("MATLAB Bindings");

	str8 base_directory = str8("matlab" OS_PATH_SEPARATOR "+" META_NAMESPACE_UPPER);

	if (!os_remove_directory((c8 *)base_directory.data))
		build_fatal("failed to remove directory: %s", (c8 *)base_directory.data);

	os_make_directory((c8 *)base_directory.data);

	if (setjmp(compiler_jmp_buf)) {
		os_remove_directory((c8 *)base_directory.data);
		build_log_error("Failed to generate MATLAB Bindings");
		return 0;
	}

	MetaprogramContext m[1] = {{.stream = arena_stream(arena), .scratch = ctx->scratch}};

	////////////////////////
	// NOTE(rnp): constants
	{
		str8 output = push_str8_from_parts(m->scratch, str8(""), base_directory, str8(OS_PATH_SEPARATOR), str8("Constants.m"));

		meta_push_line(m, matlab_file_header);
		meta_begin_scope(m, str8("classdef Constants"));
		meta_begin_scope(m, str8("properties (Constant)"));
		for (da_count constant = 0; constant < ctx->entity_kind_counts[MetaEntityKind_Constant]; constant++) {
			da_count    id   = ctx->entity_kind_ids[MetaEntityKind_Constant][constant];
			MetaEntity *e    = ctx->entities.data + id;
			str8        name = ctx->entity_names.data[id];

			meta_begin_line(m, name, str8("(1,1) "));
			if (e->constant.kind == MetaConstantKind_Integer) {
				u64  index = integer_width_index(e->constant.U64);
				meta_push(m, meta_integer_print_matlab_kind[index], str8(" = 0x"));
				meta_push_u64_hex_width(m, e->constant.U64, meta_integer_print_digits[index]);
			} else {
				// TODO(rnp): implement when needed
			}
			meta_end_line(m);
		}
		result &= meta_end_and_write_matlab(m, (c8 *)output.data);
		arena_clear(m->scratch);
	}

	/////////////////////////
	// NOTE(rnp): enumerants
	for (da_count kind = 0; kind < ctx->entity_kind_counts[MetaEntityKind_Enumeration]; kind++) {
		da_count id = ctx->entity_kind_ids[MetaEntityKind_Enumeration][kind];
		str8 name   = ctx->entity_names.data[id];
		str8 output = push_str8_from_parts(m->scratch, str8(""), base_directory, str8(OS_PATH_SEPARATOR), name, str8(".m"));

		MetaTable *etable = &ctx->entities.data[id].table;
		str8 *kinds = etable->entries[0];
		meta_push_line(m, matlab_file_header);
		meta_begin_scope(m, str8("classdef "), name, str8(" < int32"));
		meta_begin_scope(m, str8("enumeration"));
		str8 prefix = str8("");
		if (etable->entry_count > 0 && IsDigit(kinds[0].data[0])) prefix = str8("m");
		metagen_push_counted_enum_body(m, str8(""), prefix, str8("("), str8(")"), kinds, etable->entry_count);
		result &= meta_end_and_write_matlab(m, (c8 *)output.data);

		arena_clear(m->scratch);
	}

	//////////////////////
	// NOTE(rnp): structs
	for EachElement(meta_struct_entity_kinds, kind_it) {
		if (meta_struct_emit[kind_it]) {
			for (da_count it = 0; it < ctx->entity_kind_counts[meta_struct_entity_kinds[kind_it]]; it++) {
				da_count entity = ctx->entity_kind_ids[meta_struct_entity_kinds[kind_it]][it];
				str8 name = ctx->entity_names.data[entity];

				str8 output = push_str8_from_parts(m->scratch, str8(""), base_directory, str8(OS_PATH_SEPARATOR),
				                                   name, str8(".m"));

				MetaEntity *e = ctx->entities.data + entity;
				MetaStruct *s = ctx->struct_infos + e->table.struct_info_id;

				Temp scratch;
				meta_push_line(m, matlab_file_header);
				meta_begin_scope(m, str8("classdef "), name); {
					meta_push_matlab_properties(m, ctx, s);

					meta_push(m, str8("\n"));
					meta_begin_scope(m, str8("properties (Constant)")); {
						meta_begin_line(m, str8("byteSize(1,1) uint32 = "));
						meta_push_u64(m, s->info.size);
						meta_end_line(m);
					} meta_end_scope(m, str8("end"));
					meta_push(m, str8("\n"));
					meta_begin_scope(m, str8("methods")); {
						meta_begin_scope(m, str8("function bytes = toBytes(obj)")); {
							meta_begin_scope(m, str8("arguments (Input)")); {
								meta_push_line(m, str8("obj(1,1) " META_NAMESPACE_UPPER "."), name);
							} meta_end_scope(m, str8("end"));
							meta_begin_scope(m, str8("arguments (Output)")); {
								meta_push_line(m, str8("bytes uint8"));
							} meta_end_scope(m, str8("end"));
							meta_push_line(m, str8("bytes = zeros(1, " META_NAMESPACE_UPPER "."), name, str8(".byteSize);"));

							// NOTE(rnp): first pass: base types
							DeferLoop(scratch = temp_begin(m->scratch), temp_end(scratch))
							{
								str8 **columns = push_array(m->scratch, str8 *, 3);
								for (s64 i = 0; i < 3; i++)
									columns[i] = push_array(m->scratch, str8, s->info.member_count);

								u32 offset  = 1;
								u32 members = 0;
								for (u32 member = 0; member < s->info.member_count; member++) {
									s32 type_id = s->type_ids[member];
									if (s->member_flags[member] & MetaBuildStructMemberFlag_ReferenceType) {
										MetaEntity *re = ctx->entities.data + type_id;
										offset += ctx->struct_infos[re->table.struct_info_id].info.size;
									} else {
										u32 row = members++;
										Stream sb = arena_stream(m->scratch);
										stream_append_str8(&sb, str8("bytes("));
										stream_append_u64(&sb, offset);
										offset += s->elements[member] * meta_kind_byte_sizes[type_id];
										stream_append_str8(&sb, str8(":"));
										stream_append_u64(&sb, offset - 1);
										stream_append_str8(&sb, str8(")"));
										columns[0][row] = arena_stream_commit_and_reset(m->scratch, &sb);
										columns[1][row] = push_str8_from_parts(m->scratch, str8(""), str8("= typecast(obj."),
										                                       s->members[member], str8("(:),"));
										columns[2][row] = push_str8_from_parts(m->scratch, str8(""), str8("'uint8');"));
									}
								}
								metagen_push_table(m, str8(""), str8(""), columns, members, 3);
							}

							// NOTE(rnp): second pass: sub structures
							DeferLoop(scratch = temp_begin(m->scratch), temp_end(scratch))
							{
								u32 offset  = 1;
								u32 members = 0;
								str8 **columns = push_array(m->scratch, str8 *, 2);
								for (s64 i = 0; i < 2; i++)
									columns[i] = push_array(m->scratch, str8, s->info.member_count);

								for (u32 member = 0; member < s->info.member_count; member++) {
									s32 type_id = s->type_ids[member];
									if (s->member_flags[member] & MetaBuildStructMemberFlag_ReferenceType) {
										MetaEntity *re = ctx->entities.data + type_id;
										u32 row = members++;
										Stream sb = arena_stream(m->scratch);
										stream_append_str8s(&sb, str8("bytes("));
										stream_append_u64(&sb, offset);
										offset += ctx->struct_infos[re->table.struct_info_id].info.size;
										stream_append_str8(&sb, str8(":"));
										stream_append_u64(&sb, offset - 1);
										stream_append_str8(&sb, str8(")"));
										columns[0][row] = arena_stream_commit_and_reset(m->scratch, &sb);

										columns[1][row] = push_str8_from_parts(m->scratch, str8(""), str8("= obj."),
										                                       s->members[member], str8(".toBytes();"));
									} else {
										offset += s->elements[member] * meta_kind_byte_sizes[type_id];
									}
								}
								metagen_push_table(m, str8(""), str8(""), columns, members, 2);
							}
						} meta_end_scope(m, str8("end"));
					} meta_end_scope(m, str8("end"));

					meta_push(m, str8("\n"));
					meta_begin_scope(m, str8("methods (Static)")); {
						meta_begin_scope(m, str8("function out = fromBytes(bytes)")); {
							meta_begin_scope(m, str8("arguments (Input)")); {
								meta_push_line(m, str8("bytes uint8"));
							} meta_end_scope(m, str8("end"));
							meta_begin_scope(m, str8("arguments (Output)")); {
								meta_push_line(m, str8("out(1,1) " META_NAMESPACE_UPPER "."), name);
							} meta_end_scope(m, str8("end"));
							meta_push_line(m, str8("out = " META_NAMESPACE_UPPER "."), name, str8(";"));

							// NOTE(rnp): first pass: base types
							DeferLoop(scratch = temp_begin(m->scratch), temp_end(scratch))
							{
								str8 **columns = push_array(m->scratch, str8 *, 3);
								for (s64 i = 0; i < 3; i++)
									columns[i] = push_array(m->scratch, str8, s->info.member_count);

								u32 offset  = 1;
								u32 members = 0;
								for (u32 member = 0; member < s->info.member_count; member++) {
									s32 type_id = s->type_ids[member];
									if (s->member_flags[member] & MetaBuildStructMemberFlag_ReferenceType) {
										MetaEntity *re = ctx->entities.data + type_id;
										offset += ctx->struct_infos[re->table.struct_info_id].info.size;
									} else {
										u32 row = members++;
										columns[0][row] = push_str8_from_parts(m->scratch, str8(""), str8("out."),
										                                       s->members[member], str8("(:)"));

										Stream sb = arena_stream(m->scratch);
										stream_append_str8(&sb, str8("= typecast(bytes("));
										stream_append_u64(&sb, offset);
										offset += s->elements[member] * meta_kind_byte_sizes[type_id];
										stream_append_str8(&sb, str8(":"));
										stream_append_u64(&sb, offset - 1);
										stream_append_str8(&sb, str8("),"));
										columns[1][row] = arena_stream_commit_and_reset(m->scratch, &sb);

										columns[2][row] = push_str8_from_parts(m->scratch, str8(""), str8("'"),
										                                       meta_kind_matlab_types[type_id],
										                                       str8("');"));
									}
								}
								metagen_push_table(m, str8(""), str8(""), columns, members, 3);
							}

							// NOTE(rnp): second pass: sub structures
							DeferLoop(scratch = temp_begin(m->scratch), temp_end(scratch))
							{
								u32 offset  = 1;
								u32 members = 0;
								str8 **columns = push_array(m->scratch, str8 *, 2);
								for (s64 i = 0; i < 2; i++)
									columns[i] = push_array(m->scratch, str8, s->info.member_count);

								for (u32 member = 0; member < s->info.member_count; member++) {
									s32 type_id = s->type_ids[member];
									if (s->member_flags[member] & MetaBuildStructMemberFlag_ReferenceType) {
										MetaEntity *re = ctx->entities.data + type_id;
										u32 row = members++;
										columns[0][row] = push_str8_from_parts(m->scratch, str8(""), str8("out."),
										                                       s->members[member]);

										Stream sb = arena_stream(m->scratch);
										stream_append_str8s(&sb, str8("= " META_NAMESPACE_UPPER "."),
										                    ctx->entity_names.data[type_id], str8(".fromBytes(bytes("));
										stream_append_u64(&sb, offset);
										offset += ctx->struct_infos[re->table.struct_info_id].info.size;
										stream_append_str8(&sb, str8(":"));
										stream_append_u64(&sb, offset - 1);
										stream_append_str8(&sb, str8("));"));

										columns[1][row] = arena_stream_commit_and_reset(m->scratch, &sb);
									} else {
										offset += s->elements[member] * meta_kind_byte_sizes[type_id];
									}
								}
								metagen_push_table(m, str8(""), str8(""), columns, members, 2);
							}
						} meta_end_scope(m, str8("end"));
					} meta_end_scope(m, str8("end"));
				} meta_end_scope(m, str8("end"));

				result &= meta_write_and_reset(m, (c8 *)output.data);
				arena_clear(m->scratch);
			}
		}
	}
	return result;
}

function b32
metagen_emit_python_code(MetaContext *ctx, Arena *arena)
{
	b32 result = 1;

	char *out = "python" OS_PATH_SEPARATOR META_NAMESPACE_UPPER ".py";

	if (!needs_rebuild(out, "ornot.meta"))
		return result;

	build_log_generate("Python Bindings");

	if (setjmp(compiler_jmp_buf)) {
		build_log_error("Failed to generate Python Bindings");
		return 0;
	}

	MetaprogramContext m[1] = {{.stream = arena_stream(arena), .scratch = ctx->scratch}};

	read_only local_persist str8 python_file_header = str8_comp(""
		"# See LICENSE for license details.\n\n"
		"# GENERATED CODE\n"
		"import struct\n"
	);

	meta_push_line(m, python_file_header);
	meta_begin_scope(m, str8("class " META_NAMESPACE_UPPER ":"));

	////////////////////////
	// NOTE(rnp): constants
	{
		for (da_count constant = 0; constant < ctx->entity_kind_counts[MetaEntityKind_Constant]; constant++) {
			da_count    id   = ctx->entity_kind_ids[MetaEntityKind_Constant][constant];
			MetaEntity *e    = ctx->entities.data + id;
			str8        name = ctx->entity_names.data[id];

			meta_begin_line(m, name);
			if (e->constant.kind == MetaConstantKind_Integer) {
				u64  index = integer_width_index(e->constant.U64);
				meta_push(m, str8(" = 0x"));
				meta_push_u64_hex_width(m, e->constant.U64, meta_integer_print_digits[index]);
			} else {
				// TODO(rnp): implement when needed
			}
			meta_end_line(m);
		}
	}

	/////////////////////////
	// NOTE(rnp): enumerants
	for (da_count kind = 0; kind < ctx->entity_kind_counts[MetaEntityKind_Enumeration]; kind++) {
		da_count id    = ctx->entity_kind_ids[MetaEntityKind_Enumeration][kind];
		str8 name      = ctx->entity_names.data[id];
		str8 name_full = push_str8_from_parts(m->scratch, str8(""), name, str8("_"));

		MetaTable *etable = &ctx->entities.data[id].table;
		str8 *kinds = etable->entries[0];
		meta_push(m, str8("\n"));
		meta_push_line(m, str8("# "), name);
		metagen_push_counted_enum_body(m, name_full, str8(""), str8("= "), str8(""), kinds, etable->entry_count);

		arena_clear(m->scratch);
	}

	//////////////////////
	// NOTE(rnp): structs
	for EachElement(meta_struct_entity_kinds, kind_it) {
		if (meta_struct_emit[kind_it]) {
			for (da_count it = 0; it < ctx->entity_kind_counts[meta_struct_entity_kinds[kind_it]]; it++) {
				da_count entity = ctx->entity_kind_ids[meta_struct_entity_kinds[kind_it]][it];
				str8 name = ctx->entity_names.data[entity];

				MetaEntity *e = ctx->entities.data + entity;
				MetaStruct *s = ctx->struct_infos + e->table.struct_info_id;

				Temp scratch;

				str8 **columns = push_array(m->scratch, str8 *, 3);
				for (s64 i = 0; i < 3; i++)
					columns[i] = push_array(m->scratch, str8, s->info.member_count);

				meta_push(m, str8("\n"));
				meta_begin_scope(m, str8("class "), name, str8(":"));
				DeferLoop(scratch = temp_begin(m->scratch), temp_end(scratch))
				{
					meta_begin_line(m, str8("def __init__(self"));
					for (u32 entry = 0; entry < s->info.member_count; entry++) {
						meta_push(m, str8(", "));
						meta_push(m, s->members[entry], str8("="));
						if (s->elements[entry] > 1) meta_push(m, str8("["));
						meta_push(m, s->member_flags[entry] & MetaBuildStructMemberFlag_ReferenceType ? str8("None") : str8("0"));
						if (s->elements[entry] > 1) {
							// wtf is this syntax
							meta_push(m, str8("] * "));
							meta_push_u64(m, s->elements[entry]);
						}
					}
					meta_end_line(m, str8("):"));
					DeferLoop(m->indentation_level++, m->indentation_level--) {
						for (u32 entry = 0; entry < s->info.member_count; entry++) {
							columns[0][entry] = s->members[entry];

							Stream sb = arena_stream(m->scratch);
							stream_append_str8(&sb, str8("= "));

							if (s->member_flags[entry] & MetaBuildStructMemberFlag_ReferenceType) {
								str8 ref_name = ctx->entity_names.data[s->type_ids[entry]];
								stream_append_str8s(&sb, s->members[entry], str8(" if isinstance("), s->members[entry],
								                    str8(", " META_NAMESPACE_UPPER "."), ref_name,
								                    str8(") else " META_NAMESPACE_UPPER "."), ref_name, str8("()"));
							} else {
								stream_append_str8(&sb, s->members[entry]);
							}
							columns[1][entry] = arena_stream_commit_and_reset(m->scratch, &sb);
						}
						metagen_push_table(m, str8("self."), str8(""), columns, s->info.member_count, 2);
					}
					meta_push(m, str8("\n"));

					meta_push_line(m, str8("@classmethod"));
					meta_begin_scope(m, str8("def from_bytes(cls, bytes):")); {
						u32 offset = 0;
						meta_push_line(m, str8("result = cls()"));
						for (u32 entry = 0; entry < s->info.member_count; entry++) {
							columns[0][entry] = s->members[entry];

							Stream sb = arena_stream(m->scratch);
							stream_append_str8(&sb, str8(" = "));

							s32 id = s->type_ids[entry];
							if ((s->member_flags[entry] & MetaBuildStructMemberFlag_ReferenceType) == 0) {
								stream_append_str8(&sb, str8("struct.unpack_from('<"));
								stream_append_u64(&sb, s->elements[entry]);
								stream_append_str8s(&sb, meta_kind_python_struct_types[id], str8("',"));

								columns[1][entry] = arena_stream_commit_and_reset(m->scratch, &sb);
								stream_append_str8(&sb, str8("bytes, "));
								stream_append_u64(&sb, offset);
								stream_append_str8(&sb, str8(")"));

								if (s->elements[entry] == 1)
									stream_append_str8(&sb, str8("[0]"));

								columns[2][entry] = arena_stream_commit_and_reset(m->scratch, &sb);

								offset += meta_kind_byte_sizes[id] * s->elements[entry];
							} else {
								MetaEntity *re = ctx->entities.data + id;
								str8 ref_name = ctx->entity_names.data[s->type_ids[entry]];
								stream_append_str8s(&sb, str8(META_NAMESPACE_UPPER "."), ref_name, str8(".from_bytes("));
								columns[1][entry] = arena_stream_commit_and_reset(m->scratch, &sb);

								stream_append_str8(&sb, str8("bytes["));
								stream_append_u64(&sb, offset);
								stream_append_str8(&sb, str8(":])"));
								columns[2][entry] = arena_stream_commit_and_reset(m->scratch, &sb);

								offset += ctx->struct_infos[re->table.struct_info_id].info.size;
							}
						}
						metagen_push_table(m, str8("result."), str8(""), columns, s->info.member_count, 3);
						meta_push_line(m, str8("return result"));
					} m->indentation_level--;

					meta_push(m, str8("\n"));
					meta_push_line(m, str8("@staticmethod"));
					meta_begin_scope(m, str8("def byte_size():")); {
						meta_begin_line(m, str8("return "));
						meta_push_u64(m, s->info.size);
						meta_end_line(m);
					} m->indentation_level--;

					meta_push(m, str8("\n"));
					meta_begin_scope(m, str8("def to_bytes(self):")); {
						u32 offset = 0;
						meta_push_line(m, str8("result = bytearray(" META_NAMESPACE_UPPER "."), name, str8(".byte_size())"));
						for (u32 entry = 0; entry < s->info.member_count; entry++) {
							s32 id  = s->type_ids[entry];
							b32 ref = (s->member_flags[entry] & MetaBuildStructMemberFlag_ReferenceType) != 0;

							MetaEntity *re = ctx->entities.data + id;

							u64  elements = ref ? ctx->struct_infos[re->table.struct_info_id].info.size
							                    : s->elements[entry];
							str8 type     = ref ? meta_kind_python_struct_types[MetaKind_U8]
							                    : meta_kind_python_struct_types[id];
							Stream sb = arena_stream(m->scratch);
							stream_append_u64(&sb, elements);
							stream_append_str8s(&sb, type, str8("',"));
							columns[0][entry] = arena_stream_commit_and_reset(m->scratch, &sb);

							stream_append_str8(&sb, str8("result, "));
							stream_append_u64(&sb, offset);
							stream_append_str8(&sb, str8(","));
							columns[1][entry] = arena_stream_commit_and_reset(m->scratch, &sb);

							stream_append_str8s(&sb, (ref || s->elements[entry] > 1) ? str8("*") : str8(" "),
							                    str8("self."), s->members[entry]);
							if (ref) stream_append_str8(&sb, str8(".to_bytes()"));
							columns[2][entry] = arena_stream_commit_and_reset(m->scratch, &sb);

							if (ref) offset += ctx->struct_infos[re->table.struct_info_id].info.size;
							else     offset += meta_kind_byte_sizes[id] * s->elements[entry];
						}
						metagen_push_table(m, str8("struct.pack_into('<"), str8(")"), columns, s->info.member_count, 3);
						meta_push_line(m, str8("return result"));
					} m->indentation_level--;
				} m->indentation_level--;
			}
		}
	}

	result &= meta_write_and_reset(m, out);

	return result;
}

function MetaContext *
metagen_load_context(Arena *arena, char *filename)
{
	if (setjmp(compiler_jmp_buf)) {
		/* NOTE(rnp): compiler error */
		return 0;
	}

	MetaContext *ctx = push_struct(arena, MetaContext);
	ctx->scratch     = arena_create(.commit_size = MB(8));
	ctx->arena       = arena;

	// NOTE(rnp): nil entity
	*da_push(ctx->arena, &ctx->entity_names) = str8("Nil");
	da_push(ctx->arena, &ctx->entities);

	MetaContext *result = ctx;

	ctx->filename  = push_str8(ctx->arena, str8_from_c_str(filename));
	ctx->directory = str8_chop(&ctx->filename, str8_scan_backwards(ctx->filename, OS_PATH_SEPARATOR_CHAR));
	ctx->fullpath  = str8_from_c_str((c8 *)ctx->directory.data);
	if (ctx->directory.length > 0) str8_chop(&ctx->filename, 1);
	if (ctx->directory.length <= 0) {
		ctx->directory = str8(".");
		ctx->fullpath = push_str8_from_parts(ctx->arena, str8(""), ctx->directory,
		                                     str8(OS_PATH_SEPARATOR), ctx->filename);
	}

	MetaEntryStack entries = meta_entry_stack_from_file(ctx->arena, filename);

	for (s64 i = 0; i < entries.count; i++) {
		MetaEntry *e = entries.data + i;

		switch (e->kind) {
		case MetaEntryKind_Constant:{
			meta_pack_constant(ctx, e);
		}break;

		case MetaEntryKind_Expand:{
			i += meta_expand(ctx, e, entries.count - i, 0);
		}break;

		case MetaEntryKind_Enumeration:
		case MetaEntryKind_Flags:
		case MetaEntryKind_Struct:
		case MetaEntryKind_Table:
		case MetaEntryKind_Union:
		{
			i += meta_pack_table_entity(ctx, e, entries.count - i, e->name, meta_root_entity_id(ctx));
		}break;

		default:
		{
			meta_entry_error(e, "invalid @%s() in global scope\n", meta_entry_kind_strings[e->kind]);
		}break;
		}
	}

	// NOTE(rnp): sort enitity ids into sub arrays
	{
		assert(ctx->entity_kind_counts[MetaEntityKind_Nil] == 0);

		for EachNonZeroEnumValue(MetaEntityKind, it) {
			if (ctx->entity_kind_counts[it]) {
				ctx->entity_kind_ids[it] = push_array(ctx->arena, typeof(*ctx->entity_kind_ids[it]), ctx->entity_kind_counts[it]);
			}
		}

		da_count entity_counts[MetaEntityKind_Count] = {0};
		for (da_count entity = 1; entity < ctx->entities.count; entity++) {
			MetaEntity *e = ctx->entities.data + entity;
			da_count index = entity_counts[e->kind]++;
			ctx->entity_kind_ids[e->kind][index] = da_index(e, &ctx->entities);
		}
	}

	// NOTE(rnp): resolve reference entities
	{
		for (da_count entity = 0; entity < ctx->entity_kind_counts[MetaEntityKind_Reference]; entity++) {
			MetaEntity *e = ctx->entities.data + ctx->entity_kind_ids[MetaEntityKind_Reference][entity];
			da_count reference_id = meta_lookup_string_slow(ctx->entity_names.data, ctx->entity_names.count, e->reference.reference_name);
			if (reference_id >= 0)
				e->reference.resolved_id.value = reference_id;
		}

		b32 error = 0;
		for (da_count entity = 0; entity < ctx->entity_kind_counts[MetaEntityKind_Reference]; entity++) {
			MetaEntity          *e = ctx->entities.data + ctx->entity_kind_ids[MetaEntityKind_Reference][entity];
			MetaEntityReference *r = &e->reference;
			if (e->reference.resolved_id.value == 0) {
				meta_compiler_error_message(e->location, "undefined reference%s to '%.*s'\n",
				                            r->reference_count > 1? "s" : "",
				                            (s32)r->reference_name.length, r->reference_name.data);
				if (r->reference_count > 1)
					meta_compiler_message("  referenced in %d other places\n", r->reference_count - 1);
				error = 1;
			}
		}
		if (error) meta_error();
	}

	// NOTE(rnp): finalize struct info
	{
		da_count struct_infos_count = 0;
		for EachElement(meta_struct_entity_kinds, kind_it)
			struct_infos_count += ctx->entity_kind_counts[meta_struct_entity_kinds[kind_it]];

		ctx->struct_infos_count = struct_infos_count;
		ctx->struct_infos       = push_array(ctx->arena, MetaStruct, struct_infos_count);

		da_count struct_info_index = 0;
		for EachElement(meta_struct_entity_kinds, kind_it) {
			for (da_count it = 0; it < ctx->entity_kind_counts[meta_struct_entity_kinds[kind_it]]; it++) {
				da_count entity = ctx->entity_kind_ids[meta_struct_entity_kinds[kind_it]][it];
				MetaEntity *e = ctx->entities.data + entity;
				e->table.struct_info_id = struct_info_index++;

				MetaStruct *s        = ctx->struct_infos + e->table.struct_info_id;
				s->info.name         = ctx->entity_names.data[entity];
				s->info.member_count = e->table.entry_count;
				s->info.size         = (u32)-1;
				s->members           = e->table.entries[MetaStructField_Name];
				s->location          = e->location;
				s->entity            = (MetaEntityID){entity};
				if (meta_struct_entity_kinds[kind_it] == MetaEntityKind_Union)
					s->info.flags = MetaStructFlag_Union;

				s->member_flags = push_array(ctx->arena, MetaBuildStructMemberFlags, s->info.member_count);
				s->elements     = push_array_no_zero(ctx->arena, s32, s->info.member_count);
				s->type_ids     = push_array_no_zero(ctx->arena, s32, s->info.member_count);
				memory_clear(s->type_ids, -1, sizeof(*s->type_ids) * s->info.member_count);
				memory_clear(s->elements, -1, sizeof(*s->elements) * s->info.member_count);
			}
		}

		// NOTE(rnp): resolve types
		for EachElement(meta_struct_entity_kinds, kind_it) {
			for (da_count it = 0; it < ctx->entity_kind_counts[meta_struct_entity_kinds[kind_it]]; it++) {
				da_count entity = ctx->entity_kind_ids[meta_struct_entity_kinds[kind_it]][it];
				MetaEntity *e = ctx->entities.data + entity;
				MetaStruct *s = ctx->struct_infos + e->table.struct_info_id;

				str8 *types = e->table.entries[MetaStructField_Type];
				for EachIndex(s->info.member_count, member) {
					s->type_ids[member] = meta_lookup_string_slow(meta_kind_meta_types, MetaKind_Count, types[member]);

					if (s->type_ids[member] == -1 && meta_struct_allow_references[kind_it]) {
						s->member_flags[member] = MetaBuildStructMemberFlag_ReferenceType;
						s64 id = meta_lookup_string_slow(ctx->entity_names.data, ctx->entity_names.count, types[member]);
						if (id >= 0) {
							MetaEntityKind kind = ctx->entities.data[id].kind;
							if (!meta_entity_kind_struct_reference_target[kind]) {
								meta_compiler_error(e->location, "struct '%.*s' references entity '%.*s' which is not a valid struct member\n",
								                    (s32)s->info.name.length, s->info.name.data,
								                    (s32)types[member].length, types[member].data);
							}
							if (ctx->entities.data[id].kind == MetaEntityKind_Union)
								s->info.flags |= MetaStructFlag_ContainsUnion;
							s->type_ids[member] = id;
						}
					}

					if (s->type_ids[member] == -1) {
						meta_compiler_error(e->location, "struct '%.*s' references undefined type '%.*s'\n",
						                    (s32)s->info.name.length, s->info.name.data,
						                    (s32)types[member].length, types[member].data);
					}
				}
			}
		}

		// NOTE(rnp): resolve element counts
		for EachElement(meta_struct_entity_kinds, kind_it) {
			for (da_count it = 0; it < ctx->entity_kind_counts[meta_struct_entity_kinds[kind_it]]; it++) {
				da_count entity = ctx->entity_kind_ids[meta_struct_entity_kinds[kind_it]][it];
				MetaEntity *e = ctx->entities.data + entity;
				MetaStruct *s = ctx->struct_infos + e->table.struct_info_id;

				str8 *elements = e->table.entries[MetaStructField_Elements];
				for EachIndex(s->info.member_count, member) {
					NumberConversion integer = integer_from_str8(elements[member]);
					if (integer.result == NumberConversionResult_Success) {
						s->elements[member] = integer.U64;
					} else {
						str8 ref_name = elements[member];
						if (ref_name.data[0] == '#') {
							s->member_flags[member] |= MetaBuildStructMemberFlag_EnumerationCount;
							str8_chop(&ref_name, 1);
						} else {
							s->member_flags[member] |= MetaBuildStructMemberFlag_ReferenceElements;
						}

						s64 id = meta_lookup_string_slow(ctx->entity_names.data, ctx->entity_names.count, ref_name);
						if (id >= 0) {
							MetaEntity *ee = ctx->entities.data + id;
							b32 valid = ee->kind == MetaEntityKind_Enumeration ||
							           (ee->kind == MetaEntityKind_Constant && ee->constant.kind == MetaConstantKind_Integer);
							if (!valid) {
								// TODO(rnp): point at correct member
								meta_compiler_error(e->location, "struct '%.*s': element count for field '%.*s'"
								                                 "references '%.*s' which is not an integer constant\n",
								                    (s32)s->info.name.length, s->info.name.data,
								                    (s32)s->members[member].length, s->members[member].data,
								                    (s32)elements[member].length, elements[member].data);
							}
							s->elements[member] = id;
						}
					}

					if (s->elements[member] == -1) {
						meta_compiler_error(e->location, "struct '%.*s': element count for field '%.*s' could not be determined\n",
						                    (s32)s->info.name.length, s->info.name.data,
						                    (s32)s->members[member].length, s->members[member].data);
					}
				}
			}
		}

		// NOTE(rnp): resolve size
		// TODO(rnp): depth could be predetermined
		b32 all_done = 0;
		for (u32 iterations = 0; !all_done && iterations < 16; iterations++) {
			for EachIndex(ctx->struct_infos_count, structure) {
				MetaStruct *s = ctx->struct_infos + structure;
				u32 size = 0;
				b32 is_union = (s->info.flags & MetaStructFlag_Union) != 0;
				for EachIndex(s->info.member_count, member) {
					b32 type_reference = (s->member_flags[member] & MetaStructMemberFlag_ReferenceType) != 0;
					u32 elements       = meta_struct_member_elements(ctx, s, member);

					u32 member_size = 0;
					if (type_reference) {
						MetaEntity *ref = ctx->entities.data + s->type_ids[member];
						if (ref->kind == MetaEntityKind_Enumeration || ref->kind == MetaEntityKind_Flags) {
							s64 limit = ref->kind == MetaEntityKind_Flags ? 32 : U32_MAX;
							if (ref->table.entry_count < limit) member_size = sizeof(u32);
							else                                member_size = sizeof(u64);
						} else {
							MetaStruct *sub_struct = ctx->struct_infos + ref->table.struct_info_id;
							if (sub_struct->info.size != (u32)-1) {
								member_size = sub_struct->info.size * elements;
							} else {
								size = (u32)-1;
								break;
							}
						}
					} else {
						member_size = meta_kind_byte_sizes[s->type_ids[member]] * elements;
					}
					size = is_union ? Max(size, member_size) : size + member_size;
				}
				if (size != (u32)-1)
					s->info.size = size;
			}

			all_done = 1;
			for EachIndex(ctx->struct_infos_count, structure)
				all_done &= ctx->struct_infos[structure].info.size != (u32)-1;
		}

		if (!all_done) {
			for EachIndex(ctx->struct_infos_count, structure) {
				MetaStruct *s = ctx->struct_infos + structure;
				if (s->info.size == (u32)-1) {
					meta_compiler_error(s->location, "storage size for struct '%.*s' could not be determined\n",
					                    (s32)s->info.name.length, s->info.name.data);
				}
			}
		}
	}

	arena_clear(ctx->scratch);
	result->arena = 0;
	return result;
}

function b32
build_zstd(Arena *arena, Options *options)
{
	b32 result = 1;
	char *lib = OUTPUT_LIB(OS_STATIC_LIB("zstd"));

	if (needs_rebuild_(lib, 0, 0)) {
		os_make_directory(OUTPUT("zstd"));
		#define ZSTD_BASE_DIRECTORY "c" OS_PATH_SEPARATOR "external" OS_PATH_SEPARATOR "zstd"
		#define ZSTD_FILE_DIRECTORY ZSTD_BASE_DIRECTORY OS_PATH_SEPARATOR "lib"
		// X(sub_directory, filename, extension)
		#define ZSTD_SOURCES \
			X(common,     debug,                    c) \
			X(common,     entropy_common,           c) \
			X(common,     error_private,            c) \
			X(common,     fse_decompress,           c) \
			X(common,     pool,                     c) \
			X(common,     threading,                c) \
			X(common,     xxhash,                   c) \
			X(common,     zstd_common,              c) \
			X(compress,   fse_compress,             c) \
			X(compress,   hist,                     c) \
			X(compress,   huf_compress,             c) \
			X(compress,   zstd_compress,            c) \
			X(compress,   zstd_compress_literals,   c) \
			X(compress,   zstd_compress_sequences,  c) \
			X(compress,   zstd_compress_superblock, c) \
			X(compress,   zstd_double_fast,         c) \
			X(compress,   zstd_fast,                c) \
			X(compress,   zstd_lazy,                c) \
			X(compress,   zstd_ldm,                 c) \
			X(compress,   zstd_opt,                 c) \
			X(compress,   zstdmt_compress,          c) \
			X(compress,   zstd_preSplit,            c) \
			X(decompress, huf_decompress_amd64,     S) \
			X(decompress, huf_decompress,           c) \
			X(decompress, zstd_ddict,               c) \
			X(decompress, zstd_decompress,          c) \
			X(decompress, zstd_decompress_block,    c) \

		git_submodule_update(arena, ZSTD_BASE_DIRECTORY);

		#define X(base, file, ext) ZSTD_FILE_DIRECTORY OS_PATH_SEPARATOR #base OS_PATH_SEPARATOR #file "." #ext,
		char *srcs[] = {ZSTD_SOURCES};
		#undef X
		#define X(base, file, ext) OUTPUT("zstd" OS_PATH_SEPARATOR OBJECT(#file)),
		char *outs[] = {ZSTD_SOURCES};
		#undef X

		CommandList cc = cmd_base(arena, options);
		result = build_static_library(arena, cc, lib, srcs, outs, countof(srcs));
	}
	return result;
}

function b32
build_ornot(Arena *arena, Options *options)
{
	b32 result = build_zstd(arena, options);
	if (result) {
		char *lib     = OUTPUT(OS_SHARED_LIB("ornot"));
		char *libs[]  = {OUTPUT(OS_STATIC_LIB("zstd"))};
		CommandList cc = cmd_base(arena, options);
		cmd_append(arena, &cc, "-I" ZSTD_FILE_DIRECTORY);
		result = build_shared_library(arena, cc, "ornot", lib, libs, countof(libs),
		                              (char *[]){"c" OS_PATH_SEPARATOR "ornot.c"}, 1);
	}
	{
		str8 output = str8(OUTPUT("ornot.h"));
		str8 zempbp = str8("c" OS_PATH_SEPARATOR "generated" OS_PATH_SEPARATOR "zemp_bp.h");
		str8 header = str8("c" OS_PATH_SEPARATOR "ornot.h");
		if (needs_rebuild((c8 *)output.data, (c8 *)header.data, (c8 *)zempbp.data)) {
			MetaprogramContext m[1] = {{.stream = arena_stream(arena)}};

			m->stream.count += os_read_entire_file(arena, (c8 *)zempbp.data).length;
			meta_push_line(m);

			m->stream.count += os_read_entire_file(arena, (c8 *)header.data).length;

			result &= meta_write_and_reset(m, (c8 *)output.data);
		}

		{
			CommandList cpp = {0};
			cmd_append(arena, &cpp, PREPROCESSOR, (c8 *)output.data, COMPILER_OUTPUT, OUTPUT("ornot_python_ffi.h"));
			result &= run_synchronous(arena, &cpp);
		}
	}
	return result;
}

extern s32
main(s32 argc, char *argv[])
{
	g_argv0 = argv[0];

	os_common_init();
	u64 start_time = os_timer_counter();

	b32 result  = 1;
	Arena *arena = arena_create(.commit_size = MB(8));
	check_rebuild_self(arena, argc, argv);
	arena_clear(arena);

	os_make_directory(OUTDIR);

	MetaContext *meta = metagen_load_context(arena, "ornot.meta");
	if (!meta) return 1;

	Temp scratch;
	DeferLoop(scratch = temp_begin(arena), temp_end(scratch))
		result &= metagen_emit_c_code(meta, arena);
	DeferLoop(scratch = temp_begin(arena), temp_end(scratch))
		result &= metagen_emit_matlab_code(meta, arena);
	DeferLoop(scratch = temp_begin(arena), temp_end(scratch))
		result &= metagen_emit_python_code(meta, arena);

	Options options = parse_options(argc, argv);

	DeferLoop(scratch = temp_begin(arena), temp_end(scratch))
		result &= build_ornot(arena, &options);

	if (options.time) {
		f64 seconds = (f64)(os_timer_counter() - start_time) / (f64)os_timer_frequency();
		build_log_info("took %0.03f [s]", seconds);
	}

	return result != 1;
}

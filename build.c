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
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

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
  #define EXTRA_FLAGS_BASE "-Werror", "-Wextra", "-Wshadow", "-Wno-unused-parameter", \
                           "-Wno-error=unused-function", "-fno-builtin"
  #if COMPILER_GCC
    #define EXTRA_FLAGS EXTRA_FLAGS_BASE, "-Wno-unused-variable"
  #else
    #define EXTRA_FLAGS EXTRA_FLAGS_BASE
  #endif
#endif

////////////////////////
// NOTE: Standard Types
#include <stddef.h>
#include <stdint.h>

typedef intptr_t  sptr;
typedef uintptr_t uptr;
typedef ptrdiff_t sz;
typedef size_t    uz;
typedef int64_t   s64;
typedef uint64_t  b64;
typedef uint64_t  u64;
typedef int32_t   s32;
typedef uint32_t  b32;
typedef uint32_t  u32;
typedef int16_t   s16;
typedef uint16_t  b16;
typedef uint16_t  u16;
typedef int8_t    s8;
typedef uint8_t   b8;
typedef uint8_t   u8;
typedef char      c8;
typedef double    f64;
typedef float     f32;

#define U64_MAX (0xFFFFFFFFFFFFFFFFull)
#define U32_MAX (0xFFFFFFFFul)
#define U16_MAX (0xFFFFu)
#define U8_MAX  (0xFFu)

#define GB(a)   ((u64)(a) << 30ULL)
#define MB(a)   ((u64)(a) << 20ULL)
#define KB(a)   ((u64)(a) << 10ULL)

typedef struct {sz length; u8 *data;} str8;
#define str8(s) (str8){.length = (sz)sizeof(s) - 1, .data = (u8 *)s}
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

  #define debugbreak     __debugbreak
  #define unreachable()  __assume(0)
#else /* !COMPILER_MSVC */
  #define alignas(n)     __attribute__((aligned(n)))
  #define no_return      __attribute__((noreturn))

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

#define alignof       _Alignof
#define static_assert _Static_assert

#define countof(a) (sizeof(a) / sizeof(*a))

#define arg_list(type, ...) (type []){__VA_ARGS__}, sizeof((type []){__VA_ARGS__}) / sizeof(type)

#define Abs(a)           ((a) < 0 ? (-a) : (a))
#define Between(x, a, b) ((x) >= (a) && (x) <= (b))
#define Clamp(x, a, b)   ((x) < (a) ? (a) : (x) > (b) ? (b) : (x))
#define Min(a, b)        ((a) < (b) ? (a) : (b))
#define Max(a, b)        ((a) > (b) ? (a) : (b))

#define DeferLoop(begin, end)          for (s32 _i_ = ((begin), 0); !_i_; _i_ += 1, (end))

#define IsDigit(c)       (Between((c), '0', '9'))

#define swap(a, b)     do {typeof(a) __tmp = (a); (a) = (b); (b) = __tmp;} while(0)

#ifdef _DEBUG
  #define assert(c) do { if (!(c)) debugbreak(); } while (0)
#else  /* !_DEBUG */
  #define assert(c) ((void)(c))
#endif /* !_DEBUG */

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

typedef struct {
	u32 logical_processor_count;
	u32 page_size;
} OS_SystemInfo;

typedef struct { u8 *beg, *end; } Arena;

#define DA_STRUCT(kind, name) typedef struct { \
	kind *data;     \
	sz    count;    \
	sz    capacity; \
} name ##List;

typedef struct {
	u8   *data;
	sz    count;
	sz    capacity;
	b32   errors;
} Stream;

typedef enum {
	IntegerConversionResult_Invalid,
	IntegerConversionResult_OutOfRange,
	IntegerConversionResult_Success,
} IntegerConversionResult;

typedef struct {
	IntegerConversionResult result;
	union {
		u64 U64;
		s64 S64;
	};
	str8 unparsed;
} IntegerConversion;

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
                                              (sz)(sizeof((char *[]){__VA_ARGS__}) / sizeof(char *)))

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

#define zero_struct(s) mem_clear(s, 0, sizeof(*s))
function void *
mem_clear(void *restrict p_, u8 c, sz size)
{
	u8 *p = p_;
	while (size > 0) p[--size] = c;
	return p;
}

function void
mem_copy(void *restrict dest, void *restrict src, uz n)
{
	u8 *s = src, *d = dest;
	for (; n; n--) *d++ = *s++;
}

/* NOTE(rnp): returns < 0 if byte is not found */
function void *
memory_scan_backwards(void *memory, u8 byte, sz n)
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

function u8 *
arena_commit(Arena *a, sz size)
{
	assert(a->end - a->beg >= size);
	u8 *result = a->beg;
	a->beg += size;
	return result;
}

function void
arena_pop(Arena *a, sz length)
{
	a->beg -= length;
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
	for (sz i = 0; result && i < a.length; i++)
		result = a.data[i] == b.data[i];
	return result;
}

function b32
str8_contains(str8 s, u8 byte)
{
	b32 result = 0;
	for (sz i = 0 ; !result && i < s.length; i++)
		result |= s.data[i] == byte;
	return result;
}

/* NOTE(rnp): returns < 0 if byte is not found */
function sz
str8_scan_backwards(str8 s, u8 byte)
{
	u8 *found = memory_scan_backwards(s.data, byte, s.length);
	sz result = found - s.data;
	return result;
}

function str8
str8_cut_head(str8 s, sz cut)
{
	str8 result = s;
	if (cut > 0) {
		result.data   += cut;
		result.length -= cut;
	}
	return result;
}

#define push_str8_from_parts(a, j, ...) push_str8_from_parts_((a), (j), arg_list(str8, __VA_ARGS__))
function str8
push_str8_from_parts_(Arena *arena, str8 joiner, str8 *parts, sz count)
{
	sz length = joiner.length * (count - 1);
	for (sz i = 0; i < count; i++)
		length += parts[i].length;

	str8 result = {.length = length, .data = arena_commit(arena, length + 1)};

	sz offset = 0;
	for (sz i = 0; i < count; i++) {
		if (i != 0) {
			mem_copy(result.data + offset, joiner.data, (uz)joiner.length);
			offset += joiner.length;
		}
		mem_copy(result.data + offset, parts[i].data, (uz)parts[i].length);
		offset += parts[i].length;
	}
	result.data[result.length] = 0;

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

function IntegerConversion
integer_from_str8(str8 raw)
{
	read_only local_persist alignas(64) s8 lut[64] = {
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, -1, -1, -1, -1, -1, -1,
		-1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1,
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
		-1, 10, 11, 12, 13, 14, 15, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	};

	IntegerConversion result = {.unparsed = raw};

	sz  i     = 0;
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
					result.result = IntegerConversionResult_OutOfRange;\
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
	result.result   = IntegerConversionResult_Success;
	if (scale < 0) result.U64 = 0 - result.U64;

	return result;
}

function no_return void os_exit(s32);

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
function void
build_log(BuildLogKind kind, char *format, ...)
{
	va_list ap;
	va_start(ap, format);
	build_log_base(kind, format, ap);
	va_end(ap);
}

#define build_fatal(fmt, ...) build_fatal_("%s: " fmt, __FUNCTION__, ##__VA_ARGS__)
function no_return void
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
stream_append(Stream *s, void *data, sz count)
{
	s->errors |= (s->capacity - s->count) < count;
	if (!s->errors) {
		mem_copy(s->data + s->count, data, (uz)count);
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
stream_append_str8s_(Stream *s, str8 *strs, sz count)
{
	for (sz i = 0; i < count; i++)
		stream_append(s, strs[i].data, strs[i].length);
}

function void
stream_push_command(Stream *s, CommandList *c)
{
	if (!s->errors) {
		for (sz i = 0; i < c->count; i++) {
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
	while (end - beg > 0 && (uz)(end - beg) < min_width)
		*--beg = '0';

	stream_append(s, beg, end - beg);
}

function void
stream_append_u64(Stream *s, u64 n)
{
	stream_append_u64_width(s, n, 0);
}

function void
stream_append_hex_u64_width(Stream *s, u64 n, sz width)
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

function Stream
arena_stream(Arena a)
{
	Stream result   = {0};
	result.data     = a.beg;
	result.capacity = a.end - a.beg;
	return result;
}

function str8
arena_stream_commit(Arena *a, Stream *s)
{
	assert(s->data == a->beg);
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
	*s = arena_stream(*arena);
	return result;
}

function void *
arena_aligned_start(Arena a, uz alignment)
{
	uz padding = -(uintptr_t)a.beg & (alignment - 1);
	u8 *result = a.beg + padding;
	return result;
}

typedef enum {
	ArenaAllocateFlags_NoZero = 1 << 0,
} ArenaAllocateFlags;

typedef struct {
	sz size;
	uz align;
	sz count;
	ArenaAllocateFlags flags;
} ArenaAllocateInfo;

#define arena_alloc(a, ...)         arena_alloc_(a, (ArenaAllocateInfo){.align = 8, .count = 1, ##__VA_ARGS__})
#define push_array(a, t, n)         (t *)arena_alloc(a, .size = sizeof(t), .align = alignof(t), .count = n)
#define push_array_no_zero(a, t, n) (t *)arena_alloc(a, .size = sizeof(t), .align = alignof(t), .count = n, .flags = ArenaAllocateFlags_NoZero)
#define push_struct(a, t)           push_array(a, t, 1)
#define push_struct_no_zero(a, t)   push_array_no_zero(a, t, 1)

function void *
arena_alloc_(Arena *a, ArenaAllocateInfo info)
{
	void *result = 0;
	if (a->beg) {
		u8 *start = arena_aligned_start(*a, info.align);
		sz available = a->end - start;
		assert((available >= 0 && info.count <= available / info.size));
		a->beg = start + info.count * info.size;
		result = start;
		if ((info.flags & ArenaAllocateFlags_NoZero) == 0)
			result = mem_clear(start, 0, info.count * info.size);
	}
	return result;
}

function Arena
sub_arena(Arena *a, sz len, uz align)
{
	Arena result = {0};

	uz padding = -(uintptr_t)a->beg & (align - 1);
	result.beg   = a->beg + padding;
	result.end   = result.beg + len;
	arena_commit(a, len + (sz)padding);

	return result;
}

enum { DA_INITIAL_CAP = 16 };

#define da_index(it, s) ((it) - (s)->data)
#define da_reserve(a, s, n) \
  (s)->data = da_reserve_((a), (s)->data, &(s)->capacity, (s)->count + n, \
                          _Alignof(typeof(*(s)->data)), sizeof(*(s)->data))

#define da_append_count(a, s, items, item_count) do { \
	da_reserve((a), (s), (item_count));                                             \
	mem_copy((s)->data + (s)->count, (items), sizeof(*(items)) * (uz)(item_count)); \
	(s)->count += (item_count);                                                     \
} while (0)

#define da_push(a, s) \
  ((s)->count == (s)->capacity  \
    ? da_reserve(a, s, 1),      \
      (s)->data + (s)->count++  \
    : (s)->data + (s)->count++)

function void *
da_reserve_(Arena *a, void *data, sz *capacity, sz needed, uz align, sz size)
{
	sz cap = *capacity;

	/* NOTE(rnp): handle both 0 initialized DAs and DAs that need to be moved (they started
	 * on the stack or someone allocated something in the middle of the arena during usage) */
	if (!data || a->beg != (u8 *)data + cap * size) {
		void *copy = arena_alloc(a, .size = size, .align = align, .count = cap);
		if (data) mem_copy(copy, data, (uz)(cap * size));
		data = copy;
	}

	if (!cap) cap = DA_INITIAL_CAP;
	while (cap < needed) cap *= 2;
	arena_alloc(a, .size = size, .align = align, .count = cap - *capacity);
	*capacity = cap;
	return data;
}

function char *
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
	OS_SystemInfo system_info;
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
		sz r = write((s32)file, raw.data, (uz)raw.length);
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

function void
os_common_init(void)
{
	os_linux_context.system_info.logical_processor_count = (u32)sysconf(_SC_NPROCESSORS_ONLN);
	os_linux_context.system_info.page_size               = (u32)getpagesize();
}

function u64
os_get_timer_frequency(void)
{
	return 1000000000ULL;
}

function u64
os_get_timer_counter(void)
{
	struct timespec time = {0};
	clock_gettime(CLOCK_MONOTONIC, &time);
	u64 result = (u64)time.tv_sec * 1000000000ULL + (u64)time.tv_nsec;
	return result;
}

function sz
os_round_up_to_page_size(sz value)
{
	sz result = round_up_to(value, os_linux_context.system_info.page_size);
	return result;
}

function Arena
os_alloc_arena(sz capacity)
{
	Arena result = {0};
	capacity   = os_round_up_to_page_size(capacity);
	result.beg = mmap(0, (uz)capacity, PROT_READ|PROT_WRITE, MAP_ANONYMOUS|MAP_PRIVATE, -1, 0);
	if (result.beg == MAP_FAILED)
		os_fatal(str8("os_alloc_arena: couldn't allocate memory\n"));
	result.end = result.beg + capacity;
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

function str8
os_read_entire_file(Arena *arena, char *file)
{
	str8 result = str8("");

	struct stat sb;
	s32 fd = open(file, O_RDONLY);
	if (fd >= 0 && fstat(fd, &sb) >= 0) {
		result.length = sb.st_size;
		result.data   = arena_commit(arena, sb.st_size);
		sz rlen = read(fd, result.data, (uz)result.length);
		if (rlen != result.length) {
			arena_pop(arena, result.length);
			result = str8("");
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
			sz copied = 0;
			while (copied != sb.st_size) {
				sz r = read(fd_old, buf, countof(buf));
				if (r < 0) break;
				sz w = write(fd_new, buf, (uz)r);
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

	STD_INPUT_HANDLE  = -10,
	STD_OUTPUT_HANDLE = -11,
	STD_ERROR_HANDLE  = -12,
};

typedef struct {
	u64           timer_frequency;
	OS_SystemInfo system_info;
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
	sz   minimum_application_address;
	sz   maximum_application_address;
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
W32(void *) VirtualAlloc(u8 *, sz, u32, u32);

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
os_get_timer_frequency(void)
{
	u64 result = os_w32_context.timer_frequency;
	return result;
}

function u64
os_get_timer_counter(void)
{
	u64 result;
	QueryPerformanceCounter(&result);
	return result;
}

function sz
os_round_up_to_page_size(sz value)
{
	sz result = round_up_to(value, os_w32_context.system_info.page_size);
	return result;
}

function Arena
os_alloc_arena(sz capacity)
{
	Arena result = {0};
	capacity   = os_round_up_to_page_size(capacity);
	result.beg = VirtualAlloc(0, capacity, MEM_RESERVE|MEM_COMMIT, PAGE_READWRITE);
	if (!result.beg)
		os_fatal(str8("os_alloc_arena: couldn't allocate memory\n"));
	result.end = result.beg + capacity;
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

function b32
os_write_new_file(char *fname, str8 raw)
{
	b32 result = 0;
	sptr h = CreateFileA(fname, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, 0, 0);
	if (h >= 0) {
		while (raw.length > 0) {
			str8 chunk = raw;
			chunk.length = Min(chunk.length, (sz)GB(2));
			result       = os_write_file(h, chunk);
			if (!result) break;
			raw = str8_cut_head(raw, chunk.length);
		}
		CloseHandle(h);
	}
	return result;
}

function str8
os_read_entire_file(Arena *arena, char *file)
{
	str8 result = str8("");

	w32_file_info fileinfo;
	sptr h = CreateFileA(file, GENERIC_READ, 0, 0, OPEN_EXISTING, 0, 0);
	if (h >= 0 && GetFileInformationByHandle(h, &fileinfo)) {
		sz filesize  = (sz)fileinfo.nFileSizeHigh << 32;
		filesize    |= (sz)fileinfo.nFileSizeLow;
		if (filesize <= U32_MAX) {
			result.length = filesize;
			result.data   = arena_commit(arena, filesize);
			s32 rlen;
			if (!ReadFile(h, result.data, (s32)result.length, &rlen, 0) || rlen != result.length) {
				arena_pop(arena, result.length);
				result = str8("");
			}
		}
	}
	if (h >= 0) CloseHandle(h);

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
needs_rebuild_(char *binary, char *deps[], sz deps_count)
{
	u64 binary_filetime = os_get_filetime(binary);
	u64 argv0_filetime  = os_get_filetime(g_argv0);
	b32 result = (binary_filetime == (u64)-1) | (argv0_filetime > binary_filetime);
	for (sz i = 0; i < deps_count; i++) {
		u64 filetime = os_get_filetime(deps[i]);
		result |= (filetime == (u64)-1) | (filetime > binary_filetime);
	}
	return result;
}

function b32
run_synchronous(Arena a, CommandList *command)
{
	Stream sb = arena_stream(a);
	stream_push_command(&sb, command);
	build_log_command("%.*s", sb.count, sb.data);
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
check_rebuild_self(Arena arena, s32 argc, char *argv[])
{
	char *binary = shift(argv, argc);
	if (needs_rebuild(binary, __FILE__)) {
		Stream name_buffer = arena_stream(arena);
		stream_append_str8s(&name_buffer, str8_from_c_str(binary), str8(".old"));
		char *old_name = (char *)arena_stream_commit_zero(&arena, &name_buffer).data;

		if (!os_rename_file(binary, old_name))
			build_fatal("failed to move: %s -> %s", binary, old_name);

		Options options = {0};
		CommandList c = cmd_base(&arena, &options);
		cmd_append(&arena, &c, EXTRA_FLAGS);
		if (!is_msvc) cmd_append(&arena, &c, "-Wno-unused-function");
		cmd_append(&arena, &c, __FILE__, OUTPUT_EXE(binary));
		if (is_msvc) cmd_append(&arena, &c, "/link", "-incremental:no", "-opt:ref");
		cmd_append(&arena, &c, (void *)0);
		if (!run_synchronous(arena, &c)) {
			os_rename_file(old_name, binary);
			build_fatal("failed to rebuild self");
		}
		os_remove_file(old_name);

		c.count = 0;
		cmd_append(&arena, &c, binary);
		cmd_append_count(&arena, &c, argv, argc);
		cmd_append(&arena, &c, (void *)0);
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
		Stream sb = arena_stream(*a);
		stream_append_str8s(&sb, str8("-PDB:"), str8_from_c_str(name), str8(".pdb"));
		char *pdb = (char *)arena_stream_commit_zero(a, &sb).data;
		cmd_append(a, cmd, "/link", "-incremental:no", "-opt:ref", "-DEBUG", pdb);
	}
}

function void
git_submodule_update(Arena a, char *name)
{
	Stream sb = arena_stream(a);
	stream_append_str8s(&sb, str8_from_c_str(name), str8(OS_PATH_SEPARATOR), str8(".git"));
	arena_stream_commit_zero(&a, &sb);

	CommandList git = {0};
	/* NOTE(rnp): cryptic bs needed to get a simple exit code if name is dirty */
	cmd_append(&a, &git, "git", "diff-index", "--quiet", "HEAD", "--", name, (void *)0);
	if (!os_file_exists((c8 *)sb.data) || !run_synchronous(a, &git)) {
		git.count = 1;
		cmd_append(&a, &git, "submodule", "update", "--init", "--depth=1", name, (void *)0);
		if (!run_synchronous(a, &git))
			build_fatal("failed to clone required module: %s", name);
	}
}

function b32
build_shared_library(Arena a, CommandList cc, char *name, char *output, char **libs, sz libs_count, char **srcs, sz srcs_count)
{
	cmd_append_count(&a, &cc, srcs, srcs_count);
	cmd_append(&a, &cc, OUTPUT_DLL(output));
	cmd_pdb(&a, &cc, name);
	cmd_append_count(&a, &cc, libs, libs_count);
	cmd_append(&a, &cc, (void *)0);
	b32 result = run_synchronous(a, &cc);
	if (!result) build_log_failure("%s", output);
	return result;
}

function b32
cc_single_file(Arena a, CommandList cc, char *exe, char *src, char *dest, char **tail, sz tail_count)
{
	char *executable[] = {src, is_msvc? "/Fe:" : "-o", dest};
	char *object[]     = {is_msvc? "/c" : "-c", src, is_msvc? "/Fo:" : "-o", dest};


	cmd_append_count(&a, &cc, exe? executable : object,
	                 exe? countof(executable) : countof(object));
	if (exe) cmd_pdb(&a, &cc, exe);
	cmd_append_count(&a, &cc, tail, tail_count);
	cmd_append(&a, &cc, (void *)0);
	b32 result = run_synchronous(a, &cc);
	if (!result) build_log_failure("%s", dest);
	return result;
}

function b32
build_static_library_from_objects(Arena a, char *name, char **flags, sz flags_count, char **objects, sz count)
{
	CommandList ar = {0};
	cmd_append(&a, &ar, STATIC_LIBRARY_BEGIN(name));
	cmd_append_count(&a, &ar, flags, flags_count);
	cmd_append_count(&a, &ar, objects, count);
	cmd_append(&a, &ar, (void *)0);
	b32 result = run_synchronous(a, &ar);
	if (!result) build_log_failure("%s", name);
	return result;
}

function b32
build_static_library(Arena a, CommandList cc, char *name, char **deps, char **outputs, sz count)
{
	/* TODO(rnp): refactor to not need outputs */
	b32 result = 1;
	for (sz i = 0; i < count; i++)
		result &= cc_single_file(a, cc, 0, deps[i], outputs[i], 0, 0);
	if (result) result = build_static_library_from_objects(a, name, 0, 0, outputs, count);
	return result;
}

typedef struct {
	str8 *data;
	sz  count;
	sz  capacity;
} str8_list;

function str8
str8_chop(str8 *in, sz count)
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
	for (sz i = 0; i < in.length && *result.data == ' '; i++) result.data++;
	result.length -= result.data - in.data;
	for (; result.length > 0 && result.data[result.length - 1] == ' '; result.length--);
	return result;
}

typedef struct {
	Stream stream;
	Arena  scratch;
	s32    indentation_level;
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
meta_push_(MetaprogramContext *m, str8 *items, sz count)
{
	stream_append_str8s_(&m->stream, items, count);
}

#define meta_pad(m, b, n)                stream_pad(&(m)->stream, (b), (n))
#define meta_indent(m)                   meta_pad((m), '\t', (m)->indentation_level)
#define meta_begin_line(m, ...)     do { meta_indent(m); meta_push(m, __VA_ARGS__);                } while(0)
#define meta_end_line(m, ...)                            meta_push(m, ##__VA_ARGS__, str8("\n"))
#define meta_push_line(m, ...)      do { meta_indent(m); meta_push(m, ##__VA_ARGS__, str8("\n"));    } while(0)
#define meta_begin_scope(m, ...)    do { meta_push_line(m, __VA_ARGS__); (m)->indentation_level++; } while(0)
#define meta_end_scope(m, ...)      do { (m)->indentation_level--; meta_push_line(m, __VA_ARGS__); } while(0)
#define meta_push_u64(m, n)              stream_append_u64(&(m)->stream, (n))
#define meta_push_i64(m, n)              stream_append_i64(&(m)->stream, (n))
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
	X(Invalid)      \
	X(Array)        \
	X(BeginScope)   \
	X(Constant)     \
	X(EndScope)     \
	X(Enumeration)  \
	X(Expand)       \
	X(Flags)        \
	X(String)       \
	X(Struct)       \
	X(Table)        \

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
	X(U8,  uint8_t,  uint8,  B,  1,  1)

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

read_only global u8 meta_kind_bytes[] = {
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

#define META_CURRENT_LOCATION (MetaLocation){__LINE__ - 1, 0}
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
	str8                 name;
	MetaLocation       location;
} MetaEntry;

typedef struct {
	MetaEntry *data;
	sz         count;
	sz         capacity;
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
	str8            string;
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

function sz
meta_lookup_string_slow(str8 *strings, sz string_count, str8 s)
{
	// TODO(rnp): obviously this is slow
	sz result = -1;
	for (sz i = 0; i < string_count; i++) {
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
	sz id = meta_lookup_string_slow(kinds + 1, countof(kinds) - 1, s);
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
			comment = ((s + 1) != end && s[1] == '/');
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
	array->kind     = MetaEntryArgumentKind_Array;
	array->strings  = arena_aligned_start(*arena, alignof(str8));
	array->location = p->p.location;
	for (MetaParseToken token = meta_parser_token(p);
	     token != MetaParseToken_EndArray;
	     token = meta_parser_token(p))
	{
		switch (token) {
		case MetaParseToken_RawString:
		case MetaParseToken_String:
		{
			assert((u8 *)(array->strings + array->count) == arena->beg);
			*push_struct(arena, str8) = p->u.string;
			array->count++;
		}break;
		default:{ meta_parser_unexpected_token(p, token); }break;
		}
	}
}

function void
meta_parser_arguments(MetaParser *p, MetaEntry *e, Arena *arena)
{
	if (meta_parser_peek_token(p) == MetaParseToken_BeginArgs) {
		meta_parser_commit(p);

		e->arguments = arena_aligned_start(*arena, alignof(MetaEntryArgument));
		for (MetaParseToken token = meta_parser_token(p);
		     token != MetaParseToken_EndArgs;
		     token = meta_parser_token(p))
		{
			e->argument_count++;
			MetaEntryArgument *arg = push_struct(arena, MetaEntryArgument);
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
	}
}

typedef struct {
	MetaEntry *start;
	MetaEntry *one_past_last;
	sz consumed;
} MetaEntryScope;

function MetaEntryScope
meta_entry_extract_scope(MetaEntry *base, sz entry_count)
{
	assert(base->kind != MetaEntryKind_BeginScope && base->kind != MetaEntryKind_EndScope);
	assert(entry_count > 0);

	MetaEntryScope result = {.start = base + 1, .consumed = 1};
	sz sub_scope = 0;
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
		case MetaParseToken_RawString:{
			e->kind     = MetaEntryKind_String;
			e->location = parser.save_point.location;
			e->name     = parser.u.string;
		}break;
		case MetaParseToken_BeginArray:
		case MetaParseToken_BeginScope:
		case MetaParseToken_EndScope:
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
meta_entry_argument_expected_(MetaEntry *e, str8 *args, uz count)
{
	if (e->argument_count != count) {
		meta_compiler_error_message(e->location, "incorrect argument count for entry %s() got: %u expected: %u\n",
		                            meta_entry_kind_strings[e->kind], e->argument_count, (u32)count);
		fprintf(stderr, "  format: @%s(", meta_entry_kind_strings[e->kind]);
		for (uz i = 0; i < count; i++) {
			if (i != 0) fprintf(stderr, ", ");
			fprintf(stderr, "%.*s", (s32)args[i].length, args[i].data);
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

typedef struct {
	str8_list *data;
	sz       count;
	sz       capacity;
} str8_list_table;

typedef struct {
	sz kind;
	sz variation;
} MetaEnumeration;

typedef struct {
	u32 *data;
	sz   count;
	sz   capacity;
} MetaIDList;

typedef struct {
	u64 value;
	u64 name_id;
} MetaConstant;
DA_STRUCT(MetaConstant, MetaConstant);

typedef struct {
	str8  *fields;
	str8 **entries;
	u32 field_count;
	u32 entry_count;
	u32 table_name_id;
} MetaTable;
DA_STRUCT(MetaTable, MetaTable);

typedef struct {
	str8  name;
	str8 *types;
	str8 *members;

	s32  *type_ids;
	s32  *sub_struct_ids;
	u32  *elements;

	u32   member_count;
	u32   byte_size;

	MetaLocation location;
} MetaStruct;
DA_STRUCT(MetaStruct, MetaStruct);

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
		s64 number;
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
	u32 part_count;
	u32 table_id;
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
	sz count;
	sz capacity;

	str8 filename;
} MetaEmitOperationList;

typedef struct {
	Arena *arena, scratch;

	str8 filename;
	str8 directory;

	str8_list         enumeration_kinds;
	str8_list_table   enumeration_members;

	str8_list         constant_names;
	MetaConstantList  constants;

	str8_list         table_names;
	MetaTableList     tables;
	MetaStructList    structs;
} MetaContext;

function sz
meta_intern_string(MetaContext *ctx, str8_list *sv, str8 s)
{
	sz result = meta_lookup_string_slow(sv->data, sv->count, s);
	if (result < 0) {
		*da_push(ctx->arena, sv) = s;
		result = sv->count - 1;
	}
	return result;
}

function sz
meta_enumeration_id(MetaContext *ctx, str8 kind)
{
	sz result = meta_intern_string(ctx, &ctx->enumeration_kinds, kind);
	if (ctx->enumeration_kinds.count != ctx->enumeration_members.count) {
		da_push(ctx->arena, &ctx->enumeration_members);
		assert(result == (ctx->enumeration_members.count - 1));
	}
	return result;
}

function void
meta_extend_enumeration(MetaContext *ctx, str8 kind, str8 *variations, uz count)
{
	sz kidx = meta_enumeration_id(ctx, kind);
	/* NOTE(rnp): may overcommit if duplicates exist in variations */
	da_reserve(ctx->arena, ctx->enumeration_members.data + kidx, (sz)count);
	for (uz i = 0; i < count; i++)
		meta_intern_string(ctx, ctx->enumeration_members.data + kidx, variations[i]);
}

function MetaEnumeration
meta_commit_enumeration(MetaContext *ctx, str8 kind, str8 variation)
{
	sz kidx = meta_enumeration_id(ctx, kind);
	sz vidx = meta_intern_string(ctx, ctx->enumeration_members.data + kidx, variation);
	MetaEnumeration result = {.kind = kidx, .variation = vidx};
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
                         MetaExpansionPartKind kind, str8 string, MetaTable *t, MetaLocation loc)
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
		sz index = meta_lookup_string_slow(t->fields, t->field_count, string);
		if (index < 0) {
			/* TODO(rnp): fix this location to point directly at the field in the string */
			str8 table_name = ctx->table_names.data[t->table_name_id];
			meta_compiler_error(loc, "table \"%.*s\" does not contain member: %.*s\n",
			                    (s32)table_name.length, table_name.data, (s32)string.length, string.data);
		}
		result->strings = t->entries[index];
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
		s64 number;
		str8  string;
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
			IntegerConversion integer = integer_from_str8(p->s);
			if (integer.result != IntegerConversionResult_Success) {
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
meta_generate_expansion_set(MetaContext *ctx, Arena *arena, str8 expansion_string, MetaTable *t, MetaLocation loc)
{
	MetaExpansionPartList result = {0};
	str8 left = {0}, inner, remainder = expansion_string;
	do {
		meta_expansion_string_split(remainder, &left, &inner, &remainder, loc);
		if (left.length)  meta_push_expansion_part(ctx, arena, &result, MetaExpansionPartKind_String, left, t, loc);
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
					meta_push_expansion_part(ctx, arena, &result, MetaExpansionPartKind_Alignment, p->s, t, loc);
				}break;

				case MetaExpansionToken_Identifier:{
					meta_push_expansion_part(ctx, arena, &result, MetaExpansionPartKind_Reference, p->string, t, loc);
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
					meta_push_expansion_part(ctx, arena, &result, kind, p->string, t, loc);
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
					meta_push_expansion_part(ctx, arena, &result, MetaExpansionPartKind_String, string, t, loc);
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

function sz
meta_expand(MetaContext *ctx, Arena scratch, MetaEntry *e, sz entry_count, MetaEmitOperationList *ops)
{
	assert(e->kind == MetaEntryKind_Expand);

	/* TODO(rnp): for now this requires that the @Table came first */
	meta_entry_argument_expected(e, str8("table_name"));
	str8 table_name = meta_entry_argument_expect(e, 0, MetaEntryArgumentKind_String).string;

	MetaTable *t = ctx->tables.data + meta_lookup_string_slow(ctx->table_names.data,
	                                                          ctx->table_names.count, table_name);
	if (t < ctx->tables.data)
		meta_entry_error(e, "undefined table %.*s\n", (s32)table_name.length, table_name.data);

	MetaEntryScope scope = meta_entry_extract_scope(e, entry_count);
	for (MetaEntry *row = scope.start; row != scope.one_past_last; row++) {
		switch (row->kind) {
		case MetaEntryKind_String:{
			if (!ops) goto error;

			MetaExpansionPartList parts = meta_generate_expansion_set(ctx, ctx->arena, row->name, t, row->location);

			MetaEmitOperation *op = da_push(ctx->arena, ops);
			op->kind     = MetaEmitOperationKind_Expand;
			op->location = row->location;
			op->expansion_operation.parts      = parts.data;
			op->expansion_operation.part_count = (u32)parts.count;
			op->expansion_operation.table_id   = (u32)da_index(t,	&ctx->tables);
		}break;
		case MetaEntryKind_Enumeration:{
			if (ops) meta_entry_nesting_error(row, e->kind);

			meta_entry_argument_expected(row, str8("kind"), str8("`raw_string`"));
			str8 kind   = meta_entry_argument_expect(row, 0, MetaEntryArgumentKind_String).string;
			str8 expand = meta_entry_argument_expect(row, 1, MetaEntryArgumentKind_String).string;

			MetaExpansionPartList parts = meta_generate_expansion_set(ctx, &scratch, expand, t, row->location);
			str8 *variations = push_array(&scratch, str8, t->entry_count);
			for (u32 expansion = 0; expansion < t->entry_count; expansion++) {
				Stream sb = arena_stream(*ctx->arena);
				for (sz part = 0; part < parts.count; part++) {
					MetaExpansionPart *p = parts.data + part;
					u32 index = 0;
					if (p->kind == MetaExpansionPartKind_Reference) index = expansion;
					stream_append_str8(&sb, p->strings[index]);
				}
				variations[expansion] = arena_stream_commit(ctx->arena, &sb);
			}
			meta_extend_enumeration(ctx, kind, variations, t->entry_count);
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
meta_map_kind(str8 kind, str8 table_name, MetaLocation location, b32 can_fail)
{
	sz id = meta_lookup_string_slow(meta_kind_meta_types, MetaKind_Count, kind);
	if (!can_fail && id < 0) {
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

	MetaConstant *c = da_push(ctx->arena, &ctx->constants);
	sz name_id = meta_lookup_string_slow(ctx->constant_names.data, ctx->constant_names.count, e->name);
	if (name_id >= 0) meta_entry_error(e, "constant redefined\n");

	str8 *c_name = da_push(ctx->arena, &ctx->constant_names);
	c->name_id = (u64)da_index(c_name, &ctx->constant_names);
	*c_name = e->name;

	meta_entry_argument_expected(e, str8("value"));
	str8 value = meta_entry_argument_expect(e, 0, MetaEntryArgumentKind_String).string;

	IntegerConversion integer = integer_from_str8(value);
	if (integer.result != IntegerConversionResult_Success || integer.unparsed.length != 0) {
		meta_compiler_error(e->location, "Invalid integer in definition of Constant '%.*s': %.*s\n",
		                    (s32)e->name.length, e->name.data, (s32)value.length, value.data);
	}
	c->value = integer.U64;
}

function sz
meta_pack_table(MetaContext *ctx, MetaEntry *e, sz entry_count, MetaTable *t)
{
	b32 structure = e->kind == MetaEntryKind_Struct;
	assert(e->kind == MetaEntryKind_Table || structure);

	if (structure) {
		meta_entry_argument_expected_(e, 0, 0);
		read_only local_persist str8 fields[] = {
			str8_comp("name"),
			str8_comp("type"),
			str8_comp("elements"),
		};
		t->fields      = fields;
		t->field_count = 3;
	} else {
		meta_entry_argument_expected(e, str8("[field ...]"));
		MetaEntryArgument fields = meta_entry_argument_expect(e, 0, MetaEntryArgumentKind_Array);
		t->fields      = fields.strings;
		t->field_count = (u32)fields.count;
	}

	MetaEntryScope scope = meta_entry_extract_scope(e, entry_count);
	if (scope.consumed > 1) {
		for (MetaEntry *row = scope.start; row != scope.one_past_last; row++) {
			if (row->kind != MetaEntryKind_Array)
				meta_entry_nesting_error(row, e->kind);

			MetaEntryArgument entries = meta_entry_argument_expect(row, 0, MetaEntryArgumentKind_Array);
			if (structure && entries.count != 2 && entries.count != 3) {
				meta_compiler_error(row->location, "incorrect field count for @%s entry got: %zu expected: "
				                    "2/3 [name type (elements)]\n", meta_entry_kind_strings[e->kind],
				                    (size_t)entries.count);
			} else if (!structure && entries.count != t->field_count) {
				meta_compiler_error_message(row->location, "incorrect field count for @%s entry got: %zu expected: %u\n",
				                            meta_entry_kind_strings[e->kind], (size_t)entries.count, t->field_count);
				fprintf(stderr, "  fields: [");
				for (uz i = 0; i < t->field_count; i++) {
					if (i != 0) fprintf(stderr, ", ");
					fprintf(stderr, "%.*s", (s32)t->fields[i].length, t->fields[i].data);
				}
				fprintf(stderr, "]\n");
				meta_error();
			}
			t->entry_count++;
		}

		t->entries = push_array(ctx->arena, str8 *, t->field_count);
		for (u32 field = 0; field < t->field_count; field++)
			t->entries[field] = push_array(ctx->arena, str8, t->entry_count);

		u32 row_index = 0;
		for (MetaEntry *row = scope.start; row != scope.one_past_last; row++, row_index++) {
			str8 *fs = row->arguments->strings;
			for (u32 field = 0; field < row->arguments->count; field++)
				t->entries[field][row_index] = fs[field];
			if (structure && row->arguments->count == 2)
				t->entries[2][row_index] = str8("1");
		}
	}

	return scope.consumed;
}

function void
meta_intern_struct(MetaContext *ctx, MetaTable *t, MetaLocation loc)
{
	MetaStruct *s = da_push(ctx->arena, &ctx->structs);
	s->name = ctx->table_names.data[t->table_name_id];

	s->members        = push_array_no_zero(ctx->arena, str8, t->entry_count);
	s->types          = push_array_no_zero(ctx->arena, str8, t->entry_count);
	s->type_ids       = push_array_no_zero(ctx->arena, s32,  t->entry_count);
	s->sub_struct_ids = push_array_no_zero(ctx->arena, s32,  t->entry_count);
	s->elements       = push_array(ctx->arena, u32, t->entry_count);

	s->location     = loc;
	s->member_count = t->entry_count;
	s->byte_size    = (u32)-1;

	for (u32 entry = 0; entry < t->entry_count; entry++)
		s->sub_struct_ids[entry] = -1;

	sz types_id    = meta_lookup_string_slow(t->fields, t->field_count, str8("type"));
	sz members_id  = meta_lookup_string_slow(t->fields, t->field_count, str8("name"));
	sz elements_id = meta_lookup_string_slow(t->fields, t->field_count, str8("elements"));

	mem_copy(s->members, t->entries[members_id], t->entry_count * sizeof(*s->members));
	mem_copy(s->types,   t->entries[types_id],   t->entry_count * sizeof(*s->types));

	str8 *elements = t->entries[elements_id];
	for (u32 entry = 0; entry < t->entry_count; entry++) {
		IntegerConversion integer = integer_from_str8(elements[entry]);
		if (integer.result == IntegerConversionResult_Success) {
			s->elements[entry] = integer.U64;
		} else {
			meta_compiler_error(loc, "invalid element count: %.*s",
			                    (s32)elements[entry].length, elements[entry].data);
		}
	}
}

function void
metagen_push_byte_array(MetaprogramContext *m, str8 bytes)
{
	for (sz i = 0; i < bytes.length; i++) {
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
metagen_push_table(MetaprogramContext *m, Arena scratch, str8 row_start, str8 row_end,
                   str8 **column_strings, uz rows, uz columns)
{
	u32 *column_widths = 0;
	if (columns > 1) {
		column_widths = push_array(&scratch, u32, (sz)columns - 1);
		for (uz column = 0; column < columns - 1; column++) {
			str8 *strings = column_strings[column];
			for (uz row = 0; row < rows; row++)
				column_widths[column] = Max(column_widths[column], (u32)strings[row].length);
		}
	}

	for (uz row = 0; row < rows; row++) {
		meta_begin_line(m, row_start);
		for (uz column = 0; column < columns; column++) {
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
		MetaKind kind = meta_map_kind(string, table_name, loc, 0);
		result        = meta_kind_elements[kind];
	}break;

	case MetaExpansionConditionalArgumentKind_Reference:{
		str8 string = a.strings[entry];
		IntegerConversion integer = integer_from_str8(string);
		if (integer.result != IntegerConversionResult_Success) {
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
metagen_run_emit(MetaprogramContext *m, MetaContext *ctx, MetaEmitOperationList *ops,
                 MetaTableList *tables, str8 *evaluation_table, str8 namespace)
{
	for (sz opcode = 0; opcode < ops->count; opcode++) {
		MetaEmitOperation *op = ops->data + opcode;
		switch (op->kind) {
		case MetaEmitOperationKind_String:{ meta_push_line(m, op->string); }break;
		case MetaEmitOperationKind_FileBytes:{
			Arena scratch = m->scratch;
			str8 filename = push_str8_from_parts(&scratch, str8(OS_PATH_SEPARATOR), ctx->directory, op->string);
			str8 file     = os_read_entire_file(&scratch, (c8 *)filename.data);
			m->indentation_level++;
			metagen_push_byte_array(m, file);
			m->indentation_level--;
		}break;
		case MetaEmitOperationKind_Expand:{
			Arena scratch = m->scratch;

			MetaEmitOperationExpansion *eop = &op->expansion_operation;
			MetaTable *t  = tables->data + eop->table_id;
			str8 table_name = ctx->table_names.data[t->table_name_id];

			u32 alignment_count  = 1;
			u32 evaluation_count = 0;
			for (u32 part = 0; part < eop->part_count; part++) {
				if (eop->parts[part].kind == MetaExpansionPartKind_Alignment)
					alignment_count++;
				if (eop->parts[part].kind == MetaExpansionPartKind_EvalKind ||
				    eop->parts[part].kind == MetaExpansionPartKind_EvalKindCount)
					evaluation_count++;
			}

			MetaKind **evaluation_columns = push_array(&scratch, MetaKind *, evaluation_count);
			for (u32 column = 0; column < evaluation_count; column++)
				evaluation_columns[column] = push_array(&scratch, MetaKind, t->entry_count);

			for (u32 part = 0; part < eop->part_count; part++) {
				u32 eval_column = 0;
				MetaExpansionPart *p = eop->parts + part;
				if (p->kind == MetaExpansionPartKind_EvalKind) {
					for (u32 entry = 0; entry < t->entry_count; entry++) {
						evaluation_columns[eval_column][entry] = meta_map_kind(p->strings[entry],
						                                                       table_name, op->location, 1);
					}
					eval_column++;
				}
			}

			str8 **columns = push_array(&scratch, str8 *, alignment_count);
			for (u32 column = 0; column < alignment_count; column++)
				columns[column] = push_array(&scratch, str8, t->entry_count);

			Stream sb = arena_stream(scratch);
			for (u32 entry = 0; entry < t->entry_count; entry++) {
				u32 column      = 0;
				u32 eval_column = 0;
				for (u32 part = 0; part < eop->part_count; part++) {
					MetaExpansionPart *p = eop->parts + part;
					switch (p->kind) {
					case MetaExpansionPartKind_Alignment:{
						columns[column][entry] = arena_stream_commit_and_reset(&scratch, &sb);
						column++;
					}break;

					case MetaExpansionPartKind_Conditional:{
						if (!meta_expansion_part_conditional(p, entry, table_name, op->location))
							part += p->conditional.instruction_skip;
					}break;

					case MetaExpansionPartKind_EvalKind:{
						sz id = (s32)evaluation_columns[eval_column][entry];
						str8 kind = id >= 0 ? evaluation_table[id] : p->strings[entry];
						if (id < 0) stream_append_str8(&sb, namespace);
						stream_append_str8(&sb, kind);
					}break;

					case MetaExpansionPartKind_EvalKindCount:{
						sz id = (s32)evaluation_columns[eval_column][entry];
						if (id < 0) {
							str8 kind = p->strings[entry];
							meta_compiler_error(op->location, "Count not defined for Kind '%.*s' in expansion of %.*s\n",
							                    (s32)kind.length, kind.data, (s32)table_name.length, table_name.data);
						}
						stream_append_u64(&sb, meta_kind_elements[id]);
					}break;

					case MetaExpansionPartKind_Reference:
					case MetaExpansionPartKind_String:
					{
						str8 string = p->kind == MetaExpansionPartKind_Reference ? p->strings[entry] : p->string;
						stream_append_str8(&sb, string);
					}break;
					}
				}

				columns[column][entry] = arena_stream_commit_and_reset(&scratch, &sb);
			}
			metagen_push_table(m, scratch, str8(""), str8(""), columns, t->entry_count, alignment_count);
		}break;
		InvalidDefaultCase;
		}
	}
}

function void
metagen_push_counted_enum_body(MetaprogramContext *m, str8 kind, str8 prefix, str8 mid, str8 suffix, str8 *ids, sz ids_count)
{
	sz max_id_length = 0;
	for (sz id = 0; id < ids_count; id++)
		max_id_length = Max(max_id_length, ids[id].length);

	for (sz id = 0; id < ids_count; id++) {
		meta_begin_line(m, prefix, kind, ids[id]);
		meta_pad(m, ' ', 1 + (s32)(max_id_length - ids[id].length));
		meta_push(m, mid);
		meta_push_u64(m, (u64)id);
		meta_end_line(m, suffix);
	}
}

function void
metagen_push_c_enum(MetaprogramContext *m, Arena scratch, str8 kind, str8 *ids, sz ids_count)
{
	str8 kind_full = push_str8_from_parts(&scratch, str8(""), kind, str8("_"));
	meta_begin_scope(m, str8("typedef enum {"));
	metagen_push_counted_enum_body(m, kind_full, str8(""), str8("= "), str8(","), ids, ids_count);
	meta_push_line(m, kind_full, str8("Count,"));
	meta_end_scope(m, str8("} "), kind, str8(";\n"));
}

read_only global str8 c_file_header = str8_comp(""
	"/* See LICENSE for license details. */\n\n"
	"// GENERATED CODE\n\n"
	"#include <stdint.h>\n\n"
);

#define ZBP_NAMESPACE "ZBP"
read_only global str8 zbp_namespace = str8_comp(ZBP_NAMESPACE);

function b32
metagen_emit_c_code(MetaContext *ctx, Arena arena)
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

	////////////////////////
	// NOTE(rnp): constants
	for (sz constant = 0; constant < ctx->constants.count; constant++) {
		MetaConstant *c = ctx->constants.data + constant;
		str8 name  = ctx->constant_names.data[c->name_id];
		u64  index = integer_width_index(c->value);
		meta_begin_line(m, str8("#define "), zbp_namespace, str8("_"), name, str8(" (0x"));
		meta_push_u64_hex_width(m, c->value, meta_integer_print_digits[index]);
		meta_end_line(m, meta_integer_print_c_suffix[index], str8(")"));
	}
	if (ctx->constants.count > 0) meta_push_line(m);

	/////////////////////////
	// NOTE(rnp): enumerants
	for (sz kind = 0; kind < ctx->enumeration_kinds.count; kind++) {
		str8 enum_name = push_str8_from_parts(&m->scratch, str8(""), zbp_namespace, str8("_"), ctx->enumeration_kinds.data[kind]);
		metagen_push_c_enum(m, m->scratch, enum_name, ctx->enumeration_members.data[kind].data,
		                    ctx->enumeration_members.data[kind].count);
		m->scratch = ctx->scratch;
	}

	//////////////////////
	// NOTE(rnp): structs
	{
		for (sz structure = 0; structure < ctx->structs.count; structure++) {
			MetaStruct *s = ctx->structs.data + structure;

			sz max_type_name_length = 0;
			for (u32 member = 0; member < s->member_count; member++) {
				s32 id = s->type_ids[member];
				if (id < 0)  {
					sz length = s->types[member].length + str8(ZBP_NAMESPACE "_").length;
					max_type_name_length = Max(max_type_name_length, length);
				} else {
					max_type_name_length = Max(max_type_name_length, meta_kind_base_c_types[id].length);
				}
			}

			if (structure != 0) meta_push(m, str8("\n"));
			meta_begin_scope(m, str8("typedef struct " ZBP_NAMESPACE "_"), s->name, str8(" {")); {
				for (u32 member = 0; member < s->member_count; member++) {
					s32  id     = s->type_ids[member];
					str8 kind   = id < 0 ? s->types[member] : meta_kind_base_c_types[id];
					sz   length = kind.length + (id < 0 ? str8(ZBP_NAMESPACE "_").length : 0);

					meta_begin_line(m, id < 0? str8(ZBP_NAMESPACE "_") : str8(""), kind);
					meta_pad(m, ' ', 1 + (s32)(max_type_name_length - length));
					meta_push(m, s->members[member]);
					if (s->elements[member] > 1) {
						meta_push(m, str8("["));
						meta_push_u64(m, s->elements[member]);
						meta_push(m, str8("]"));
					}
					meta_end_line(m, str8(";"));
				}
			} meta_end_scope(m, str8("} " ZBP_NAMESPACE "_"), s->name, str8(";"));
			m->scratch = ctx->scratch;
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
metagen_emit_matlab_code(MetaContext *ctx, Arena arena)
{
	b32 result = 1;

	char *out_test = "matlab"          OS_PATH_SEPARATOR
	                 "+" ZBP_NAMESPACE OS_PATH_SEPARATOR
	                 "HeaderV2.m";

	if (!needs_rebuild(out_test, "ornot.meta"))
		return result;

	build_log_generate("MATLAB Bindings");

	str8 base_directory = str8("matlab" OS_PATH_SEPARATOR "+" ZBP_NAMESPACE);

	if (!os_remove_directory((c8 *)base_directory.data))
		build_fatal("failed to remove directory: %s", base_directory);

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
		Arena scratch = ctx->scratch;
		str8 output = push_str8_from_parts(&scratch, str8(""), base_directory, str8(OS_PATH_SEPARATOR), str8("Constants.m"));

		meta_push_line(m, matlab_file_header);
		meta_begin_scope(m, str8("classdef Constants"));
		meta_begin_scope(m, str8("properties (Constant)"));
		for (sz constant = 0; constant < ctx->constants.count; constant++) {
			MetaConstant *c = ctx->constants.data + constant;
			str8 name  = ctx->constant_names.data[c->name_id];
			u64  index = integer_width_index(c->value);
			meta_begin_line(m, name, str8("(1,1) "), meta_integer_print_matlab_kind[index], str8(" = 0x"));
			meta_push_u64_hex_width(m, c->value, meta_integer_print_digits[index]);
			meta_end_line(m);
		}
		result &= meta_end_and_write_matlab(m, (c8 *)output.data);
	}

	/////////////////////////
	// NOTE(rnp): enumerants
	for (sz kind = 0; kind < ctx->enumeration_kinds.count; kind++) {
		Arena scratch = ctx->scratch;
		str8 name   = ctx->enumeration_kinds.data[kind];
		str8 output = push_str8_from_parts(&scratch, str8(""), base_directory, str8(OS_PATH_SEPARATOR), name, str8(".m"));
		str8_list *kinds = ctx->enumeration_members.data + kind;
		meta_push_line(m, matlab_file_header);
		meta_begin_scope(m, str8("classdef "), name, str8(" < int32"));
		meta_begin_scope(m, str8("enumeration"));
		str8 prefix = str8("");
		if (kinds->count > 0 && IsDigit(kinds->data[0].data[0])) prefix = str8("m");
		metagen_push_counted_enum_body(m, str8(""), prefix, str8("("), str8(")"), kinds->data, kinds->count);
		result &= meta_end_and_write_matlab(m, (c8 *)output.data);
	}

	//////////////////////
	// NOTE(rnp): structs
	for (sz structure = 0; structure < ctx->structs.count; structure++) {
		MetaStruct *s = ctx->structs.data + structure;

		Arena scratch = m->scratch;

		str8 output = push_str8_from_parts(&m->scratch, str8(""), base_directory, str8(OS_PATH_SEPARATOR),
		                                   s->name, str8(".m"));

		meta_push_line(m, matlab_file_header);
		meta_begin_scope(m, str8("classdef "), s->name); {
			meta_begin_scope(m, str8("properties")); {
				Arena properties_arena = m->scratch;

				str8 **columns = push_array(&m->scratch, str8 *, 2);
				for (sz i = 0; i < 2; i++)
					columns[i] = push_array(&m->scratch, str8, s->member_count);

				for (u32 member = 0; member < s->member_count; member++) {
					Stream sb = arena_stream(m->scratch);
					stream_append_str8s(&sb, s->members[member], str8("(1,"));
					stream_append_u64(&sb, s->elements[member]);
					stream_append_str8(&sb, str8(")"));

					columns[0][member] = arena_stream_commit_and_reset(&m->scratch, &sb);

					s32 id = s->type_ids[member];
					if (id >= 0) {
						columns[1][member] = meta_kind_matlab_types[id];
					} else {
						stream_append_str8s(&sb, str8(ZBP_NAMESPACE "."), s->types[member]);
						columns[1][member] = arena_stream_commit_and_reset(&m->scratch, &sb);
					}
				}
				metagen_push_table(m, m->scratch, str8(""), str8(""), columns, s->member_count, 2);
				m->scratch = properties_arena;
			} meta_end_scope(m, str8("end"));

			meta_push(m, str8("\n"));
			meta_begin_scope(m, str8("properties (Constant)")); {
				meta_begin_line(m, str8("byteSize(1,1) uint32 = "));
				meta_push_u64(m, s->byte_size);
				meta_end_line(m);
			} meta_end_scope(m, str8("end"));

			meta_push(m, str8("\n"));
			meta_begin_scope(m, str8("methods (Static)")); {
				meta_begin_scope(m, str8("function out = fromBytes(bytes)")); {
					meta_begin_scope(m, str8("arguments (Input)")); {
						meta_push_line(m, str8("bytes uint8"));
					} meta_end_scope(m, str8("end"));
					meta_begin_scope(m, str8("arguments (Output)")); {
						meta_push_line(m, str8("out(1,1) " ZBP_NAMESPACE "."), s->name);
					} meta_end_scope(m, str8("end"));
					meta_push_line(m, str8("out = " ZBP_NAMESPACE "."), s->name, str8(";"));

					// NOTE(rnp): first pass: base types
					Arena pass_arena;
					DeferLoop(pass_arena = m->scratch, m->scratch = pass_arena) {
						str8 **columns = push_array(&m->scratch, str8 *, 3);
						for (sz i = 0; i < 3; i++)
							columns[i] = push_array(&m->scratch, str8, s->member_count);

						u32 offset  = 1;
						u32 members = 0;
						for (u32 member = 0; member < s->member_count; member++) {
							s32 type_id = s->type_ids[member];
							if (type_id >= 0) {
								u32 row = members++;
								columns[0][row] = push_str8_from_parts(&m->scratch, str8(""), str8("out."),
								                                       s->members[member], str8("(:)"));

								Stream sb = arena_stream(m->scratch);
								stream_append_str8(&sb, str8("= typecast(bytes("));
								stream_append_u64(&sb, offset);
								offset += s->elements[member] * meta_kind_bytes[type_id];
								stream_append_str8(&sb, str8(":"));
								stream_append_u64(&sb, offset - 1);
								stream_append_str8(&sb, str8("),"));
								columns[1][row] = arena_stream_commit_and_reset(&m->scratch, &sb);

								columns[2][row] = push_str8_from_parts(&m->scratch, str8(""), str8("'"),
								                                       meta_kind_matlab_types[type_id],
								                                       str8("');"));
							} else {
								offset += ctx->structs.data[s->sub_struct_ids[member]].byte_size;
							}
						}
						metagen_push_table(m, m->scratch, str8(""), str8(""), columns, members, 3);
					}

					// NOTE(rnp): second pass: sub structures
					DeferLoop(pass_arena = m->scratch, m->scratch = pass_arena) {
						u32 offset  = 1;
						u32 members = 0;
						str8 **columns = push_array(&m->scratch, str8 *, 2);
						for (sz i = 0; i < 2; i++)
							columns[i] = push_array(&m->scratch, str8, s->member_count);

						for (u32 member = 0; member < s->member_count; member++) {
							s32 type_id = s->type_ids[member];
							if (type_id < 0) {
								u32 row = members++;
								columns[0][row] = push_str8_from_parts(&m->scratch, str8(""), str8("out."),
								                                          s->members[member]);

								Stream sb = arena_stream(m->scratch);
								stream_append_str8s(&sb, str8("= " ZBP_NAMESPACE "."), s->types[member],
								                    str8(".fromBytes(bytes("));
								stream_append_u64(&sb, offset);
								offset += ctx->structs.data[s->sub_struct_ids[member]].byte_size;
								stream_append_str8(&sb, str8(":"));
								stream_append_u64(&sb, offset - 1);
								stream_append_str8(&sb, str8("));"));

								columns[1][row] = arena_stream_commit_and_reset(&m->scratch, &sb);
							} else {
								offset += s->elements[member] * meta_kind_bytes[type_id];
							}
						}
						metagen_push_table(m, m->scratch, str8(""), str8(""), columns, members, 2);
					}
				} meta_end_scope(m, str8("end"));
				meta_push(m, str8("\n"));
				meta_begin_scope(m, str8("function bytes = toBytes(obj)")); {
					meta_begin_scope(m, str8("arguments (Input)")); {
						meta_push_line(m, str8("obj(1,1) " ZBP_NAMESPACE "."), s->name);
					} meta_end_scope(m, str8("end"));
					meta_begin_scope(m, str8("arguments (Output)")); {
						meta_push_line(m, str8("bytes uint8"));
					} meta_end_scope(m, str8("end"));
					meta_push_line(m, str8("bytes = zeros(1, " ZBP_NAMESPACE "."), s->name, str8(".byteSize);"));

					// NOTE(rnp): first pass: base types
					Arena pass_arena;
					DeferLoop(pass_arena = m->scratch, m->scratch = pass_arena) {
						str8 **columns = push_array(&m->scratch, str8 *, 3);
						for (sz i = 0; i < 3; i++)
							columns[i] = push_array(&m->scratch, str8, s->member_count);

						u32 offset  = 1;
						u32 members = 0;
						for (u32 member = 0; member < s->member_count; member++) {
							s32 type_id = s->type_ids[member];
							if (type_id >= 0) {
								u32 row = members++;
								Stream sb = arena_stream(m->scratch);
								stream_append_str8(&sb, str8("bytes("));
								stream_append_u64(&sb, offset);
								offset += s->elements[member] * meta_kind_bytes[type_id];
								stream_append_str8(&sb, str8(":"));
								stream_append_u64(&sb, offset - 1);
								stream_append_str8(&sb, str8(")"));
								columns[0][row] = arena_stream_commit_and_reset(&m->scratch, &sb);

								columns[1][row] = push_str8_from_parts(&m->scratch, str8(""), str8("= typecast(obj."), 
																		s->members[member], str8("(:),"));
								
								columns[2][row] = push_str8_from_parts(&m->scratch, str8(""), str8("'uint8');"));
							} else {
								offset += ctx->structs.data[s->sub_struct_ids[member]].byte_size;
							}
						}
						metagen_push_table(m, m->scratch, str8(""), str8(""), columns, members, 3);
					}

					// NOTE(rnp): second pass: sub structures
					DeferLoop(pass_arena = m->scratch, m->scratch = pass_arena) {
						u32 offset  = 1;
						u32 members = 0;
						str8 **columns = push_array(&m->scratch, str8 *, 2);
						for (sz i = 0; i < 2; i++)
							columns[i] = push_array(&m->scratch, str8, s->member_count);

						for (u32 member = 0; member < s->member_count; member++) {
							s32 type_id = s->type_ids[member];
							if (type_id < 0) {
								u32 row = members++;
								Stream sb = arena_stream(m->scratch);
								stream_append_str8s(&sb, str8("bytes("));
								stream_append_u64(&sb, offset);
								offset += ctx->structs.data[s->sub_struct_ids[member]].byte_size;
								stream_append_str8(&sb, str8(":"));
								stream_append_u64(&sb, offset - 1);
								stream_append_str8(&sb, str8(")"));
								columns[0][row] = arena_stream_commit_and_reset(&m->scratch, &sb);

								columns[1][row] = push_str8_from_parts(&m->scratch, str8(""), str8("= obj."), s->members[member],
																		str8(".toBytes();"));
							} else {
								offset += s->elements[member] * meta_kind_bytes[type_id];
							}
						}
						metagen_push_table(m, m->scratch, str8(""), str8(""), columns, members, 2);
					}
				} meta_end_scope(m, str8("end"));
			} meta_end_scope(m, str8("end"));
		} meta_end_scope(m, str8("end"));

		result &= meta_write_and_reset(m, (c8 *)output.data);
		m->scratch = scratch;
	}
	return result;
}

function b32
metagen_emit_python_code(MetaContext *ctx, Arena arena)
{
	b32 result = 1;

	char *out = "python" OS_PATH_SEPARATOR ZBP_NAMESPACE ".py";

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
	meta_begin_scope(m, str8("class " ZBP_NAMESPACE ":"));

	////////////////////////
	// NOTE(rnp): constants
	{
		for (sz constant = 0; constant < ctx->constants.count; constant++) {
			MetaConstant *c = ctx->constants.data + constant;
			str8 name  = ctx->constant_names.data[c->name_id];
			u64  index = integer_width_index(c->value);
			meta_begin_line(m, name, str8(" = 0x"));
			meta_push_u64_hex_width(m, c->value, meta_integer_print_digits[index]);
			meta_end_line(m);
		}
	}

	/////////////////////////
	// NOTE(rnp): enumerants
	for (sz kind = 0; kind < ctx->enumeration_kinds.count; kind++) {
		str8 name      = ctx->enumeration_kinds.data[kind];
		str8 name_full = push_str8_from_parts(&m->scratch, str8(""), name, str8("_"));
		str8_list *kinds = ctx->enumeration_members.data + kind;
		meta_push(m, str8("\n"));
		meta_push_line(m, str8("# "), name);
		metagen_push_counted_enum_body(m, name_full, str8(""), str8("= "), str8(""), kinds->data, kinds->count);
		m->scratch = ctx->scratch;
	}

	//////////////////////
	// NOTE(rnp): structs
	for (sz structure = 0; structure < ctx->structs.count; structure++) {
		MetaStruct *s = ctx->structs.data + structure;
		Arena scratch = m->scratch;

		str8 **columns = push_array(&m->scratch, str8 *, 3);
		for (sz i = 0; i < 3; i++)
			columns[i] = push_array(&m->scratch, str8, s->member_count);

		meta_push(m, str8("\n"));
		meta_begin_scope(m, str8("class "), s->name, str8(":")); {
			meta_push_line(m, str8("@classmethod"));
			meta_begin_scope(m, str8("def from_bytes(cls, bytes):")); {
				u32 offset = 0;
				meta_push_line(m, str8("result = cls()"));
				for (u32 entry = 0; entry < s->member_count; entry++) {
					columns[0][entry] = s->members[entry];

					Stream sb = arena_stream(m->scratch);
					stream_append_str8(&sb, str8(" = "));

					s32 id = s->type_ids[entry];
					if (id >= 0) {
						stream_append_str8(&sb, str8("struct.unpack_from('<"));
						stream_append_u64(&sb, s->elements[entry]);
						stream_append_str8s(&sb, meta_kind_python_struct_types[id], str8("',"));

						columns[1][entry] = arena_stream_commit_and_reset(&m->scratch, &sb);
						stream_append_str8(&sb, str8("bytes, "));
						stream_append_u64(&sb, offset);
						stream_append_str8(&sb, str8(")"));

						if (s->elements[entry] == 1)
							stream_append_str8(&sb, str8("[0]"));

						columns[2][entry] = arena_stream_commit_and_reset(&m->scratch, &sb);

						offset += meta_kind_bytes[id] * s->elements[entry];
					} else {
						stream_append_str8s(&sb, str8(ZBP_NAMESPACE "."), s->types[entry], str8(".from_bytes("));
						columns[1][entry] = arena_stream_commit_and_reset(&m->scratch, &sb);

						stream_append_str8(&sb, str8("bytes["));
						stream_append_u64(&sb, offset);
						stream_append_str8(&sb, str8(":])"));
						columns[2][entry] = arena_stream_commit_and_reset(&m->scratch, &sb);
						offset += ctx->structs.data[s->sub_struct_ids[entry]].byte_size;
					}
				}
				metagen_push_table(m, m->scratch, str8("result."), str8(""), columns, s->member_count, 3);
				meta_push_line(m, str8("return result"));
			} m->indentation_level--;

			meta_push(m, str8("\n"));
			meta_push_line(m, str8("@staticmethod"));
			meta_begin_scope(m, str8("def byte_size():")); {
				meta_begin_line(m, str8("return "));
				meta_push_u64(m, s->byte_size);
				meta_end_line(m);
			} m->indentation_level--;
		} m->indentation_level--;
		m->scratch = scratch;
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
	ctx->scratch     = sub_arena(arena, MB(1), 16);
	ctx->arena       = arena;

	MetaContext *result = ctx;

	ctx->filename  = str8_from_c_str(filename);
	ctx->directory = str8_chop(&ctx->filename, str8_scan_backwards(ctx->filename, OS_PATH_SEPARATOR_CHAR));
	str8_chop(&ctx->filename, 1);
	if (ctx->directory.length <= 0) ctx->directory = str8(".");

	Arena scratch = ctx->scratch;
	MetaEntryStack entries = meta_entry_stack_from_file(ctx->arena, filename);

	s32 stack_items[32];
	struct { s32 *data; sz capacity; sz count; } stack = {stack_items, countof(stack_items), 0};

	for (sz i = 0; i < entries.count; i++) {
		MetaEntry *e = entries.data + i;
		//if (e->kind == MetaEntryKind_EndScope)   depth--;
		//meta_entry_print(e, depth, -1);
		//if (e->kind == MetaEntryKind_BeginScope) depth++;
		//continue;

		switch (e->kind) {
		case MetaEntryKind_BeginScope:{ *da_push(&scratch, &stack) = (s32)(i - 1); }break;
		case MetaEntryKind_EndScope:{ stack.count--; }break;
		case MetaEntryKind_Enumeration:{
			meta_entry_argument_expected(e, str8("kind"), str8("[id ...]"));
			str8 kind = meta_entry_argument_expect(e, 0, MetaEntryArgumentKind_String).string;
			MetaEntryArgument ids = meta_entry_argument_expect(e, 1, MetaEntryArgumentKind_Array);
			for (u32 id = 0; id < ids.count; id++)
				meta_commit_enumeration(ctx, kind, ids.strings[id]);
		}break;
		case MetaEntryKind_Expand:{
			i += meta_expand(ctx, scratch, e, entries.count - i, 0);
		}break;
		case MetaEntryKind_Constant:{
			meta_pack_constant(ctx, e);
		}break;
		case MetaEntryKind_Struct:
		case MetaEntryKind_Table:
		{
			b32 structure = e->kind == MetaEntryKind_Struct;
			sz table_name_id = meta_lookup_string_slow(ctx->table_names.data, ctx->table_names.count, e->name);
			if (table_name_id >= 0) meta_entry_error(e, "%s redefined\n", structure ? "struct" : "table");

			str8 *t_name = da_push(ctx->arena, &ctx->table_names);
			*t_name = e->name;

			Arena temp = ctx->scratch;
			MetaTable *t;
			if (e->kind == MetaEntryKind_Struct) t = push_struct(&ctx->scratch, MetaTable);
			else                                 t = da_push(ctx->arena, &ctx->tables);
			t->table_name_id = (u32)da_index(t_name, &ctx->table_names);

			i += meta_pack_table(ctx, e, entries.count - i, t);

			if (structure)
				meta_intern_struct(ctx, t, e->location);

			ctx->scratch = temp;

		}break;

		default:
		{
			meta_entry_error(e, "invalid @%s() in global scope\n", meta_entry_kind_strings[e->kind]);
		}break;
		}
	}

	// NOTE(rnp): finalize struct info
	{
		for (sz structure = 0; structure < ctx->structs.count; structure++) {
			MetaStruct *s = ctx->structs.data + structure;
			for (u32 member = 0; member < s->member_count; member++) {
				s->type_ids[member] = meta_lookup_string_slow(meta_kind_meta_types, MetaKind_Count, s->types[member]);

				if (s->type_ids[member] == -1) {
					for (sz try = 0; try < ctx->structs.count; try++) {
						if (str8_equal(ctx->structs.data[try].name, s->types[member])) {
							s->sub_struct_ids[member] = try;
							break;
						}
					}
				}

				if (s->type_ids[member] == -1 && s->sub_struct_ids[member] == -1) {
					meta_compiler_error(s->location, "struct '%.*s' references undefined struct '%.*s'\n",
					                    (s32)s->name.length, s->name.data,
					                    (s32)s->types[member].length, s->types[member].data);
				}
			}
		}

		// TODO(rnp): depth could be predetermined
		u32 iterations = 0;
		b32 all_done   = 0;
		while (!all_done && iterations < 16) {
			for (sz structure = 0; structure < ctx->structs.count; structure++) {
				MetaStruct *s = ctx->structs.data + structure;
				u32 size = 0;
				for (u32 member = 0; member < s->member_count; member++) {
					if (s->type_ids[member] >= 0) {
						size += meta_kind_bytes[s->type_ids[member]] * s->elements[member];
					} else {
						MetaStruct *sub_struct = ctx->structs.data + s->sub_struct_ids[member];
						if (sub_struct->byte_size != (u32)-1) {
							size += sub_struct->byte_size;
						} else {
							size = (u32)-1;
							break;
						}
					}
				}
				if (size != (u32)-1)
					s->byte_size = size;
			}

			all_done = 1;
			for (sz structure = 0; structure < ctx->structs.count; structure++)
				all_done &= ctx->structs.data[structure].byte_size != (u32)-1;
		}

		if (!all_done) {
			for (sz structure = 0; structure < ctx->structs.count; structure++) {
				MetaStruct *s = ctx->structs.data + structure;
				if (s->byte_size == (u32)-1) {
					meta_compiler_error(s->location, "storage size for struct '%.*s' could not be determined\n",
					                    (s32)s->name.length, s->name.data);
				}
			}
		}
	}

	compiler_file = __FILE__;
	result->arena = 0;
	return result;
}

function b32
build_zstd(Arena arena, Options *options)
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

		CommandList cc = cmd_base(&arena, options);
		result = build_static_library(arena, cc, lib, srcs, outs, countof(srcs));
	}
	return result;
}

function b32
build_ornot(Arena arena, Options *options)
{
	b32 result = build_zstd(arena, options);
	if (result) {
		Arena scratch = arena;
		char *lib     = OUTPUT(OS_SHARED_LIB("ornot"));
		char *libs[]  = {OUTPUT(OS_STATIC_LIB("zstd"))};
		CommandList cc = cmd_base(&scratch, options);
		cmd_append(&scratch, &cc, "-I" ZSTD_FILE_DIRECTORY);
		result = build_shared_library(scratch, cc, "ornot", lib, libs, countof(libs),
		                              (char *[]){"c" OS_PATH_SEPARATOR "ornot.c"}, 1);
	}
	{
		str8 output = str8(OUTPUT("ornot.h"));
		str8 zempbp = str8("c" OS_PATH_SEPARATOR "generated" OS_PATH_SEPARATOR "zemp_bp.h");
		str8 header = str8("c" OS_PATH_SEPARATOR "ornot.h");
		if (needs_rebuild((c8 *)output.data, (c8 *)header.data, (c8 *)zempbp.data)) {
			Arena scratch = arena;
			MetaprogramContext m[1] = {{.stream = arena_stream(scratch)}};

			m->stream.count += os_read_entire_file(&scratch, (c8 *)zempbp.data).length;
			meta_push_line(m);

			scratch.beg = m->stream.data + m->stream.count;
			m->stream.count += os_read_entire_file(&scratch, (c8 *)header.data).length;

			result &= meta_write_and_reset(m, (c8 *)output.data);
		}

		{
			CommandList cpp = {0};
			cmd_append(&arena, &cpp, PREPROCESSOR, (c8 *)output.data, COMPILER_OUTPUT, OUTPUT("ornot_python_ffi.h"));
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
	u64 start_time = os_get_timer_counter();

	b32 result  = 1;
	Arena arena = os_alloc_arena(MB(8));
	check_rebuild_self(arena, argc, argv);

	os_make_directory(OUTDIR);

	MetaContext *meta = metagen_load_context(&arena, "ornot.meta");
	if (!meta) return 1;

	result &= metagen_emit_c_code(meta, arena);
	result &= metagen_emit_matlab_code(meta, arena);
	result &= metagen_emit_python_code(meta, arena);

	Options options = parse_options(argc, argv);

	result &= build_ornot(arena, &options);

	if (options.time) {
		f64 seconds = (f64)(os_get_timer_counter() - start_time) / (f64)os_get_timer_frequency();
		build_log_info("took %0.03f [s]", seconds);
	}

	return result != 1;
}

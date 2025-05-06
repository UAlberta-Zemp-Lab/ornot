#include <zstd.h>

#include "ornot.h"

typedef char      c8;
typedef uint8_t   u8;
typedef int16_t   i16;
typedef uint32_t  u32;
typedef uint32_t  b32;
typedef uint64_t  u64;
typedef size_t    uz;
typedef ptrdiff_t iz;
typedef ptrdiff_t iptr;

#define ARRAY_COUNT(a) (sizeof(a) / sizeof(*a))
typedef struct { iz len; u8 *data; } s8;
#define s8(s) (s8){.len = ARRAY_COUNT(s) - 1, .data = (u8 *)s}

#define function      static
#define global        static
#define local_persist static

typedef struct {
	void *data;
	u64   size;
} MemoryBlock;

typedef struct {
	MemoryBlock backing;
	iz          filled;
} MemoryStream;

#include "platform.h"

function void *mem_copy(void *restrict dst, void *restrict src, uz n)
{
	u8 *d = dst, *s = src;
	for (; n; n--) *d++ = *s++;
	return dst;
}

b32 write_zemp_bp_v1(c8 *output_name, zemp_bp_v1 *header)
{
	header->magic = ZEMP_BP_MAGIC;
	b32 result = os_write_new_file(output_name,
	                               (s8){.data = (u8 *)header, .len = sizeof(*header)});
	return result;
}

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#warning "zemp_bp_v1 unpacking not yet implemented for big endian hosts"
#else
b32 unpack_zemp_bp_v1(c8 *input_name, zemp_bp_v1 *output_header)
{
	b32 result = 0;

	MemoryStream file_data = os_read_whole_file(input_name);
	if (file_data.filled > 0 && (*(u64 *)file_data.backing.data == ZEMP_BP_MAGIC)) {
		zemp_bp_v1 *header = file_data.backing.data;
		if (header->version == 1) {
			mem_copy(output_header, header, sizeof(*header));
			result = 1;
		}
	}
	os_block_release(file_data.backing);

	return result;
}
#endif

b32 write_i16_data_compressed(c8 *output_name, i16 *data, u32 data_element_count)
{
	b32 result = 0;
	iz data_size = data_element_count * sizeof(*data);
	iz buf_size  = ZSTD_COMPRESSBOUND(data_size);
	MemoryBlock buf = os_block_alloc(buf_size);
	if (buf.size) {
		iz written = ZSTD_compress(buf.data, buf.size, data, data_size, ZSTD_CLEVEL_DEFAULT);
		result     = !ZSTD_isError(written);
		if (result)
			result = os_write_new_file(output_name, (s8){.data = buf.data, .len = written});
	}
	os_block_release(buf);

	return result;
}

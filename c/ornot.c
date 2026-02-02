#include <zstd.h>

#include "generated/zemp_bp.h"
#include "ornot.h"

typedef char      c8;
typedef uint8_t   u8;
typedef int16_t   i16;
typedef int32_t   i32;
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

b32 write_zemp_bp_v1(c8 *output_name, ZBP_HeaderV1 *header)
{
	header->magic = ZBP_HeaderMagic;
	b32 result = os_write_new_file(output_name,
	                               (s8){.data = (u8 *)header, .len = sizeof(*header)});
	return result;
}

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#warning "zemp_bp_v1 unpacking not yet implemented for big endian hosts"
#else
b32 unpack_zemp_bp_v1(c8 *input_name, ZBP_HeaderV1 *output_header)
{
	b32 result = 0;

	MemoryStream file_data = os_read_whole_file(input_name);
	if (file_data.filled > 0 && (*(u64 *)file_data.backing.data == ZBP_HeaderMagic)) {
		ZBP_HeaderV1 *header = file_data.backing.data;
		if (header->version == 1) {
			mem_copy(output_header, header, sizeof(*header));
			result = 1;
		}
	}
	os_block_release(file_data.backing);

	return result;
}
#endif

b32 unpack_zstd_compressed_data(c8 *file, void *output, uz output_size)
{
	b32 result = 0;
	MemoryStream file_data = os_read_whole_file(file);
	if (file_data.filled > 0) {
		u8 *input     = file_data.backing.data;
		uz input_size = file_data.filled;
		uz requested_size = ZSTD_getFrameContentSize(input, input_size);
		if (requested_size <= output_size) {
			uz decompressed_size = ZSTD_decompress(output, output_size, input, input_size);
			result = decompressed_size == requested_size;
		}
	}
	os_block_release(file_data.backing);
	return result;
}

b32 unpack_compressed_i16_data(c8 *file, void *output, uz output_size)
{
	return unpack_zstd_compressed_data(file, output, output_size);
}

b32 write_data_with_zstd_compression(c8 *output_name, void *data, u64 data_size)
{
	b32 result   = 0;
	u64 buf_size = ZSTD_COMPRESSBOUND(data_size);
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

b32 write_i16_data_compressed(c8 *output_name, i16 *data, u32 data_element_count)
{
	return write_data_with_zstd_compression(output_name, data, (u64)data_element_count * sizeof(*data));
}

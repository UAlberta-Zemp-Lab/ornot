#if 1
/* IMPORTANT(rnp): depending on the license we are not allowed to do this if we intend
 * on shipping ornot as a library */
#include "external/zstd/lib/common/entropy_common.c"
#include "external/zstd/lib/common/error_private.c"
#include "external/zstd/lib/common/fse_decompress.c"
#include "external/zstd/lib/common/xxhash.c"
#include "external/zstd/lib/compress/fse_compress.c"
#include "external/zstd/lib/compress/hist.c"
#include "external/zstd/lib/compress/huf_compress.c"
#include "external/zstd/lib/compress/zstd_compress.c"
#include "external/zstd/lib/compress/zstd_compress_literals.c"
#include "external/zstd/lib/compress/zstd_compress_sequences.c"
#include "external/zstd/lib/compress/zstd_compress_superblock.c"
#include "external/zstd/lib/compress/zstd_double_fast.c"
#include "external/zstd/lib/compress/zstd_fast.c"
#include "external/zstd/lib/compress/zstd_lazy.c"
#include "external/zstd/lib/compress/zstd_ldm.c"
#include "external/zstd/lib/compress/zstd_opt.c"
#else
#include <zstd.h>
#endif

#include "ornot.h"

#define ARRAY_COUNT(a) (sizeof(a) / sizeof(*a))
typedef struct { size len; u8 *data; } s8;
#define s8(s) (s8){.len = ARRAY_COUNT(s) - 1, .data = (u8 *)s}

typedef struct {
	void *data;
	u64   size;
} MemoryBlock;

typedef struct {
	MemoryBlock backing;
	size        filled;
} MemoryStream;

#include "platform.h"

b32 write_zemp_bp_v1(c8 *output_name, zemp_bp_v1 *header)
{
	header->magic = ZEMP_BP_MAGIC;
	b32 result = os_write_new_file(output_name,
	                               (s8){.data = (u8 *)header, .len = sizeof(*header)});
	return result;
}

b32 unpack_zemp_bp_v1(c8 *input_name, zemp_bp_v1 *output_header)
{
	MemoryStream file_data = os_read_whole_file(input_name);
	b32 result = 0;

	if (file_data.filled && (*(uint64_t *)file_data.backing.data == ZEMP_BP_MAGIC)) {
		zemp_bp_v1 *header = file_data.backing.data;
		if (header->version == 1) {
			memcpy(output_header, header, sizeof(*header));
			result = 1;
			os_block_release(file_data.backing);
		}
	}

	return result;
}

b32 write_i16_data_compressed(c8 *output_name, i16 *data, u32 data_element_count)
{
	b32 result = 0;
	size data_size = data_element_count * sizeof(*data);
	size buf_size  = ZSTD_COMPRESSBOUND(data_size);
	MemoryBlock buf = os_block_alloc(buf_size);
	if (buf.size) {
		size written = ZSTD_compress(buf.data, buf.size, data, data_size, ZSTD_CLEVEL_DEFAULT);
		result       = !ZSTD_isError(written);
		if (result)
			result = os_write_new_file(output_name, (s8){.data = buf.data, .len = written});
		os_block_release(buf);
	}

	return result;
}

#include <stdint.h>

#ifndef ORNOT_EXPORT
  #ifdef _WIN32
    #define ORNOT_EXPORT __declspec(dllexport)
  #else
    #define ORNOT_EXPORT
  #endif
#endif

// NOTE: Compress data to buffer using ZSTD
// output:      a pointer to a buffer with enough space (zstd_compress_bound())
// output_size: returns the size of data actually written to output.
//              MUST be initialized to the size of the output buffer.
// input:       input data
// input_size:  size of the input data
//
// returns whether the operation succeeded (1) or failed (0)
ORNOT_EXPORT uint32_t zstd_compress(void *output, uint64_t *output_size, void *input, uint64_t input_size);

// NOTE: Determine the upper bound on space needed to store the compressed data
// Exactly the following:
// input_size >= 0xFF00FF00FF00FF00ULL ?
// 0 :
// (input_size + (input_size >> 8) + ((input_size < (128 << 10)) ? (((128 << 10) - input_size) >> 11) : 0))
ORNOT_EXPORT uint64_t zstd_compress_bound(uint64_t input_size);

ORNOT_EXPORT uint32_t write_data_with_zstd_compression(char *output_name, void *data, uint64_t data_size);
ORNOT_EXPORT uint32_t unpack_zstd_compressed_data_from_file(char *input_file, void *output, uint64_t output_size);

ORNOT_EXPORT uint32_t unpack_zstd_compressed_data(void *input, uint64_t input_size, void *output, uint64_t output_size);

// NOTE: DEPRECATED: these are aliases of *_zstd_* functions
ORNOT_EXPORT uint32_t write_i16_data_compressed(char *output_name, int16_t *data, uint32_t data_element_count);
ORNOT_EXPORT uint32_t unpack_compressed_i16_data(char *input_file, void *output, uint64_t output_size);

// NOTE: DEPRECATED: write file using your languages standard library facilities
ORNOT_EXPORT uint32_t write_zemp_bp_v1(char *output_name, ZBP_HeaderV1 *header);
// NOTE: DEPRECATED: use the provided language specific unpackers (in C you can just raw cast)
ORNOT_EXPORT uint32_t unpack_zemp_bp_v1(char *input_name, ZBP_HeaderV1 *output_header);

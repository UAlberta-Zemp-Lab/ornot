#include <stddef.h>

#ifndef ORNOT_EXPORT
  #ifdef _WIN32
    #define ORNOT_EXPORT __declspec(dllexport)
  #else
    #define ORNOT_EXPORT
  #endif
#endif

ORNOT_EXPORT uint32_t write_data_with_zstd_compression(char *output_name, void *data, uint64_t data_size);
ORNOT_EXPORT uint32_t unpack_zstd_compressed_data_from_file(char *input_file, void *output, size_t output_size);

ORNOT_EXPORT uint32_t unpack_zstd_compressed_data(void *input, size_t input_size, void *output, size_t output_size);

// NOTE: DEPRECATED: these are aliases of *_zstd_* functions
ORNOT_EXPORT uint32_t write_i16_data_compressed(char *output_name, int16_t *data, uint32_t data_element_count);
ORNOT_EXPORT uint32_t unpack_compressed_i16_data(char *input_file, void *output, size_t output_size);

// NOTE: DEPRECATED: write file using your languages standary library facilities
ORNOT_EXPORT uint32_t write_zemp_bp_v1(char *output_name, ZBP_HeaderV1 *header);
// NOTE: DEPRECATED: use the provided language specific unpackers (in C you can just raw cast)
ORNOT_EXPORT uint32_t unpack_zemp_bp_v1(char *input_name, ZBP_HeaderV1 *output_header);

#include <stddef.h>

#ifndef ORNOT_EXPORT
  #ifdef _WIN32
    #define ORNOT_EXPORT __declspec(dllexport)
  #else
    #define ORNOT_EXPORT
  #endif
#endif

ORNOT_EXPORT uint32_t write_zemp_bp_v1(char *output_name, ZBP_HeaderV1 *header);
ORNOT_EXPORT uint32_t unpack_zemp_bp_v1(char *input_name, ZBP_HeaderV1 *output_header);

ORNOT_EXPORT uint32_t write_i16_data_compressed(char *output_name, int16_t *data, uint32_t data_element_count);
ORNOT_EXPORT uint32_t unpack_compressed_i16_data(char *input_file, void *output, size_t output_size);

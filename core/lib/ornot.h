#include <stddef.h>
#include <stdint.h>

#ifdef _WIN32
#define LIB_FN __declspec(dllexport)
#else
#define LIB_FN
#endif

#include "zemp_bp.h"

LIB_FN uint32_t write_zemp_bp_v1(char *output_name, zemp_bp_v1 *header);
LIB_FN uint32_t unpack_zemp_bp_v1(char *input_name, zemp_bp_v1 *output_header);

LIB_FN uint32_t write_i16_data_compressed(char *output_name, int16_t *data, uint32_t data_element_count);

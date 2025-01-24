#include <stddef.h>
#include <stdint.h>

typedef char      c8;
typedef uint8_t   u8;
typedef int16_t   i16;
typedef uint16_t  u16;
typedef int32_t   i32;
typedef uint32_t  u32;
typedef uint32_t  b32;
typedef uint64_t  u64;
typedef float     f32;
typedef double    f64;
typedef ptrdiff_t size;
typedef ptrdiff_t iptr;

#ifdef _WIN32
#define LIB_FN __declspec(dllexport)
#else
#define LIB_FN
#endif

#include "zemp_bp.h"

LIB_FN b32 write_zemp_bp_v1(char *output_name, zemp_bp_v1 *header);
LIB_FN b32 unpack_zemp_bp_v1(char *input_name, zemp_bp_v1 *output_header);

LIB_FN b32 write_i16_data_compressed(char *output_name, i16 *data, u32 data_element_count);

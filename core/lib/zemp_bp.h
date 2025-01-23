/* NOTE: standalone header for getting zemp_bp struct definition */
#include <stdint.h>

#ifdef _MSC_VER
#define PACK(s) __pragma(pack(push, 1) ) s __pragma(pack(pop))
#else
#define PACK(s) s __attribute__((__packed__))
#endif

PACK(struct zemp_bp_v1 {
	uint32_t version;
	uint16_t decode_mode;
	uint16_t beamform_mode;
	uint32_t raw_data_dim[4];
	uint32_t decoded_data_dim[4];
	uint32_t transducer_count;
	float    speed_of_sound;
	float    center_frequency;
	float    sampling_frequency;
	float    time_offset;
	uint32_t transmit_mode;
	float    transducer_element_pitch[2];
	float    transducer_transform_matrices[64]; /* NOTE: column major order */
	int16_t  channel_mapping[1024];
	float    steering_angles[1024];
	float    focal_depths[1024];
	int16_t  sparse_elements[1024];
	int16_t  hadamard_rows[1024];
});
typedef struct zemp_bp_v1 zemp_bp_v1;

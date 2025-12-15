/* NOTE: standalone header for getting zemp_bp struct definition */
#include <stdint.h>

// ('P' << 56 | 'B' << 48 | 'P' << 40 | 'M' << 32 | 'E' << 24 | 'Z' << 16 | 0xFE << 8 | 0xCA)
#define ZEMP_BP_MAGIC (uint64_t)0x5042504D455AFECAull

typedef struct {
	uint64_t magic;
	uint32_t version;
	uint16_t decode_mode;
	uint16_t beamform_mode;
	uint32_t raw_data_dim[4];
	uint32_t decoded_data_dim[4];
	float    transducer_element_pitch[2];
	float    transducer_transform_matrix[16]; /* NOTE: column major order */
	int16_t  channel_mapping[256];
	float    steering_angles[256];
	float    focal_depths[256];
	int16_t  sparse_elements[256];
	int16_t  hadamard_rows[256];
	float    speed_of_sound;
	float    center_frequency;
	float    sampling_frequency;
	float    time_offset;
	uint32_t transmit_mode;
} zemp_bp_v1;

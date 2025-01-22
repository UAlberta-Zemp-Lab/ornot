/* NOTE: standalone header for getting zemp_bp struct definition */
#include <stdint.h>

typedef __attribute__((packed)) struct {
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
	float    transducer_transform_matrices[64]; /* NOTE: column major order */
	int16_t  channel_mapping[1024];
	float    streering_angles[1024];
	float    focal_depths[1024];
	int16_t  sparse_elements[1024];
	int16_t  hadamard_rows[1024];
} zemp_bp_v1;

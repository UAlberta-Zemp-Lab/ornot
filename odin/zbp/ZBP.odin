// See LICENSE for license details.

// GENERATED CODE

package ornot_zbp

HeaderMagic :: 0x5042504d455afeca
OffsetAlignment :: 0x04

RCAOrientation:: enum {
	None    = 0,
	Rows    = 1,
	Columns = 2,
}

DecodeMode:: enum {
	None     = 0,
	Hadamard = 1,
	Walsh    = 2,
}

SamplingMode:: enum {
	Standard = 0,
	Bandpass = 1,
}

AcquisitionKind:: enum {
	FORCES         = 0,
	UFORCES        = 1,
	HERCULES       = 2,
	RCA_VLS        = 3,
	RCA_TPW        = 4,
	UHERCULES      = 5,
	RACES          = 6,
	EPIC_FORCES    = 7,
	EPIC_UFORCES   = 8,
	EPIC_UHERCULES = 9,
	Flash          = 10,
	HERO_PA        = 11,
	HEXDoppler     = 12,
	XDoppler       = 13,
}

ContrastMode:: enum {
	None = 0,
	A1S2 = 1,
}

EmissionKind:: enum {
	Sine  = 0,
	Chirp = 1,
}

DataKind:: enum {
	Int16          = 0,
	Int16Complex   = 1,
	Float32        = 2,
	Float32Complex = 3,
	Float16        = 4,
	Float16Complex = 5,
}

DataCompressionKind:: enum {
	None = 0,
	ZSTD = 1,
}

TransmitReceiveOrientation :: bit_field u8 {
	transmit : RCAOrientations | 4,
	receive  : RCAOrientations | 4,
}

BaseHeader :: struct {
	magic:  u64,
	major:  u32,
	minor:  u32,
}

HeaderV1 :: struct {
	magic:                        u64,
	version:                      u32,
	decode_mode:                  i16,
	beamform_mode:                i16,
	raw_data_dimension:           [4]u32,
	sample_count:                 u32,
	channel_count:                u32,
	receive_event_count:          u32,
	frame_count:                  u32,
	transducer_element_pitch:     [2]f32,
	transducer_transform_matrix:  [16]f32,
	channel_mapping:              [256]i16,
	steering_angles:              [256]f32,
	focal_depths:                 [256]f32,
	sparse_elements:              [256]i16,
	hadamard_rows:                [256]i16,
	speed_of_sound:               f32,
	demodulation_frequency:       f32,
	sampling_frequency:           f32,
	time_offset:                  f32,
	transmit_mode:                u32,
}

HeaderV2 :: struct {
	magic:                          u64,
	major:                          u32,
	minor:                          u32,
	raw_data_dimension:             [4]u32,
	raw_data_kind:                  i32,
	raw_data_offset:                i32,
	raw_data_compression_kind:      i32,
	decode_mode:                    i32,
	sampling_mode:                  i32,
	sampling_frequency:             f32,
	demodulation_frequency:         f32,
	speed_of_sound:                 f32,
	channel_mapping_offset:         i32,
	sample_count:                   u32,
	channel_count:                  u32,
	receive_event_count:            u32,
	transducer_transform_matrix:    [16]f32,
	transducer_element_pitch:       [2]f32,
	time_offset:                    f32,
	group_acquisition_time:         f32,
	ensemble_repetition_interval:   f32,
	acquisition_mode:               i32,
	acquisition_parameters_offset:  i32,
	contrast_mode:                  i32,
	contrast_parameters_offset:     i32,
	emission_descriptors_offset:    i32,
}

EmissionDescriptor :: struct {
	emission_kind:      i32,
	parameters_offset:  i32,
}

EmissionSineParameters :: struct {
	cycles:     f32,
	frequency:  f32,
}

EmissionChirpParameters :: struct {
	duration:       f32,
	min_frequency:  f32,
	max_frequency:  f32,
}

RCATransmitFocus :: struct {
	focal_depth:                   f32,
	steering_angle:                f32,
	origin_offset:                 f32,
	transmit_receive_orientation:  u32,
}

FORCESParameters :: struct {
	transmit_focus:  ZBP_RCATransmitFocus,
}

uFORCESParameters :: struct {
	transmit_focus:          ZBP_RCATransmitFocus,
	sparse_elements_offset:  i32,
}

HERCULESParameters :: struct {
	transmit_focus:  ZBP_RCATransmitFocus,
}

uHERCULESParameters :: struct {
	transmit_focus:          ZBP_RCATransmitFocus,
	sparse_elements_offset:  i32,
}

TPWParameters :: struct {
	tilting_angles_offset:                 i32,
	transmit_receive_orientations_offset:  i32,
}

VLSParameters :: struct {
	focal_depths_offset:                   i32,
	origin_offsets_offset:                 i32,
	transmit_receive_orientations_offset:  i32,
}

HERO_PAParameters :: struct {
	transmit_receive_orientation:  u32,
}

HEXDopplerParameters :: struct {
	bin_count:  [2]i32,
	bin_size:   [2]i32,
}

XDopplerParameters :: struct {
	angle_count:            [2]i32,
	tilting_angles_offset:  i32,
}

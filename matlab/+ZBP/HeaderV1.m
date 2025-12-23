% See LICENSE for license details.

% GENERATED CODE

classdef HeaderV1
	properties
		magic(1,1)                        uint64
		version(1,1)                      uint32
		decode_mode(1,1)                  int16
		beamform_mode(1,1)                int16
		raw_data_dimension(1,4)           uint32
		sample_count(1,1)                 uint32
		channel_count(1,1)                uint32
		receive_event_count(1,1)          uint32
		frame_count(1,1)                  uint32
		transducer_element_pitch(1,2)     single
		transducer_transform_matrix(1,16) single
		channel_mapping(1,256)            int16
		steering_angles(1,256)            single
		focal_depths(1,256)               single
		sparse_elements(1,256)            int16
		hadamard_rows(1,256)              int16
		speed_of_sound(1,1)               single
		demodulation_frequency(1,1)       single
		sampling_frequency(1,1)           single
		time_offset(1,1)                  single
		transmit_mode(1,1)                uint32
	end
end

% See LICENSE for license details.

% GENERATED CODE

classdef HeaderV2
	properties
		magic(1,1)                         uint64
		major(1,1)                         uint32
		minor(1,1)                         uint32
		raw_data_dimension(1,4)            uint32
		raw_data_kind(1,1)                 int32
		raw_data_offset(1,1)               int32
		raw_data_compression_kind(1,1)     int32
		decode_mode(1,1)                   int32
		sampling_mode(1,1)                 int32
		sampling_frequency(1,1)            single
		demodulation_frequency(1,1)        single
		speed_of_sound(1,1)                single
		channel_mapping_offset(1,1)        int32
		sample_count(1,1)                  uint32
		channel_count(1,1)                 uint32
		receive_event_count(1,1)           uint32
		transducer_transform_matrix(1,16)  single
		transducer_element_pitch(1,2)      single
		time_offset(1,1)                   single
		group_acquisition_time(1,1)        single
		ensemble_repitition_interval(1,1)  single
		acquisition_mode(1,1)              int32
		acquisition_parameters_offset(1,1) int32
		contrast_mode(1,1)                 int32
		contrast_parameters_offset(1,1)    int32
		emission_descriptors_offset(1,1)   int32
	end
end

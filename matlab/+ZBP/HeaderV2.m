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

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 0;
			out      = ZBP.HeaderV2;

			out.magic(:) = typecast(bytes((consumed + 1):(consumed + 8)), 'uint64');
			consumed = consumed + 8;

			out.major(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'uint32');
			consumed = consumed + 4;

			out.minor(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'uint32');
			consumed = consumed + 4;

			out.raw_data_dimension(:) = typecast(bytes((consumed + 1):(consumed + 16)), 'uint32');
			consumed = consumed + 16;

			out.raw_data_kind(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;

			out.raw_data_offset(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;

			out.raw_data_compression_kind(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;

			out.decode_mode(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;

			out.sampling_mode(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;

			out.sampling_frequency(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.demodulation_frequency(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.speed_of_sound(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.channel_mapping_offset(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;

			out.sample_count(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'uint32');
			consumed = consumed + 4;

			out.channel_count(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'uint32');
			consumed = consumed + 4;

			out.receive_event_count(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'uint32');
			consumed = consumed + 4;

			out.transducer_transform_matrix(:) = typecast(bytes((consumed + 1):(consumed + 64)), 'single');
			consumed = consumed + 64;

			out.transducer_element_pitch(:) = typecast(bytes((consumed + 1):(consumed + 8)), 'single');
			consumed = consumed + 8;

			out.time_offset(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.group_acquisition_time(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.ensemble_repitition_interval(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.acquisition_mode(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;

			out.acquisition_parameters_offset(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;

			out.contrast_mode(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;

			out.contrast_parameters_offset(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;

			out.emission_descriptors_offset(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;
		end
	end
end

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

	properties (Constant)
		byteSize(1,1) uint32 = 184
	end

	methods (Static)
		function out = fromBytes(bytes)
			out = ZBP.HeaderV2;
			out.magic(:)                         = typecast(bytes(1:8),     'uint64');
			out.major(:)                         = typecast(bytes(9:12),    'uint32');
			out.minor(:)                         = typecast(bytes(13:16),   'uint32');
			out.raw_data_dimension(:)            = typecast(bytes(17:32),   'uint32');
			out.raw_data_kind(:)                 = typecast(bytes(33:36),   'int32');
			out.raw_data_offset(:)               = typecast(bytes(37:40),   'int32');
			out.raw_data_compression_kind(:)     = typecast(bytes(41:44),   'int32');
			out.decode_mode(:)                   = typecast(bytes(45:48),   'int32');
			out.sampling_mode(:)                 = typecast(bytes(49:52),   'int32');
			out.sampling_frequency(:)            = typecast(bytes(53:56),   'single');
			out.demodulation_frequency(:)        = typecast(bytes(57:60),   'single');
			out.speed_of_sound(:)                = typecast(bytes(61:64),   'single');
			out.channel_mapping_offset(:)        = typecast(bytes(65:68),   'int32');
			out.sample_count(:)                  = typecast(bytes(69:72),   'uint32');
			out.channel_count(:)                 = typecast(bytes(73:76),   'uint32');
			out.receive_event_count(:)           = typecast(bytes(77:80),   'uint32');
			out.transducer_transform_matrix(:)   = typecast(bytes(81:144),  'single');
			out.transducer_element_pitch(:)      = typecast(bytes(145:152), 'single');
			out.time_offset(:)                   = typecast(bytes(153:156), 'single');
			out.group_acquisition_time(:)        = typecast(bytes(157:160), 'single');
			out.ensemble_repitition_interval(:)  = typecast(bytes(161:164), 'single');
			out.acquisition_mode(:)              = typecast(bytes(165:168), 'int32');
			out.acquisition_parameters_offset(:) = typecast(bytes(169:172), 'int32');
			out.contrast_mode(:)                 = typecast(bytes(173:176), 'int32');
			out.contrast_parameters_offset(:)    = typecast(bytes(177:180), 'int32');
			out.emission_descriptors_offset(:)   = typecast(bytes(181:184), 'int32');
		end
	end
end

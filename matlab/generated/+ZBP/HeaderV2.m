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

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.HeaderV2
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.HeaderV2.byteSize);
			bytes(1:8)     = typecast(obj.magic(:),                         'uint8');
			bytes(9:12)    = typecast(obj.major(:),                         'uint8');
			bytes(13:16)   = typecast(obj.minor(:),                         'uint8');
			bytes(17:32)   = typecast(obj.raw_data_dimension(:),            'uint8');
			bytes(33:36)   = typecast(obj.raw_data_kind(:),                 'uint8');
			bytes(37:40)   = typecast(obj.raw_data_offset(:),               'uint8');
			bytes(41:44)   = typecast(obj.raw_data_compression_kind(:),     'uint8');
			bytes(45:48)   = typecast(obj.decode_mode(:),                   'uint8');
			bytes(49:52)   = typecast(obj.sampling_mode(:),                 'uint8');
			bytes(53:56)   = typecast(obj.sampling_frequency(:),            'uint8');
			bytes(57:60)   = typecast(obj.demodulation_frequency(:),        'uint8');
			bytes(61:64)   = typecast(obj.speed_of_sound(:),                'uint8');
			bytes(65:68)   = typecast(obj.channel_mapping_offset(:),        'uint8');
			bytes(69:72)   = typecast(obj.sample_count(:),                  'uint8');
			bytes(73:76)   = typecast(obj.channel_count(:),                 'uint8');
			bytes(77:80)   = typecast(obj.receive_event_count(:),           'uint8');
			bytes(81:144)  = typecast(obj.transducer_transform_matrix(:),   'uint8');
			bytes(145:152) = typecast(obj.transducer_element_pitch(:),      'uint8');
			bytes(153:156) = typecast(obj.time_offset(:),                   'uint8');
			bytes(157:160) = typecast(obj.group_acquisition_time(:),        'uint8');
			bytes(161:164) = typecast(obj.ensemble_repitition_interval(:),  'uint8');
			bytes(165:168) = typecast(obj.acquisition_mode(:),              'uint8');
			bytes(169:172) = typecast(obj.acquisition_parameters_offset(:), 'uint8');
			bytes(173:176) = typecast(obj.contrast_mode(:),                 'uint8');
			bytes(177:180) = typecast(obj.contrast_parameters_offset(:),    'uint8');
			bytes(181:184) = typecast(obj.emission_descriptors_offset(:),   'uint8');
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.HeaderV2
			end
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

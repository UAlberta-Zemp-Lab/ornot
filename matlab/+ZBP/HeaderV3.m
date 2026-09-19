% See LICENSE for license details.

% GENERATED CODE

classdef HeaderV3
	properties
		magic(1,1)                           uint64
		major(1,1)                           uint32
		minor(1,1)                           uint32
		raw_data_dimension(1,4)              uint32
		raw_data_size(1,1)                   uint64
		raw_data_offset(1,1)                 int32
		raw_data_kind(1,1)                   uint32 % ZBP.DataKind
		raw_data_compression_kind(1,1)       uint32 % ZBP.DataCompressionKind
		raw_data_layout(1,1)                 uint32 % ZBP.DataLayout
		decode_mode(1,1)                     uint32 % ZBP.DecodeMode
		sampling_mode(1,1)                   uint32 % ZBP.SamplingMode
		sampling_frequency(1,1)              single
		speed_of_sound(1,1)                  single
		channel_mapping_offset(1,1)          int32
		sample_count(1,1)                    uint32
		channel_count(1,1)                   uint32
		receive_event_count(1,1)             uint32
		transducer_tile_count(1,2)           uint32
		transducer_element_pitch(1,2)        single
		group_acquisition_time(1,1)          single
		ensemble_repetition_interval(1,1)    single
		acquisition_mode(1,1)                uint32 % ZBP.AcquisitionKind
		acquisition_parameters_offset(1,1)   int32
		contrast_mode(1,1)                   uint32 % ZBP.ContrastMode
		contrast_parameters_offset(1,1)      int32
		emission_descriptors_offset(1,1)     int32
		time_delays_offset(1,1)              int32
		demodulation_frequencies_offset(1,1) int32
		transducer_transforms_offset(1,1)    int32
		string_count(1,1)                    uint32
		string_table_offset(1,1)             int32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 152
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.HeaderV3
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.HeaderV3.byteSize);
			bytes(1:8)     = typecast(obj.magic(:),                           'uint8');
			bytes(9:12)    = typecast(obj.major(:),                           'uint8');
			bytes(13:16)   = typecast(obj.minor(:),                           'uint8');
			bytes(17:32)   = typecast(obj.raw_data_dimension(:),              'uint8');
			bytes(33:40)   = typecast(obj.raw_data_size(:),                   'uint8');
			bytes(41:44)   = typecast(obj.raw_data_offset(:),                 'uint8');
			bytes(45:48)   = typecast(obj.raw_data_kind(:),                   'uint8');
			bytes(49:52)   = typecast(obj.raw_data_compression_kind(:),       'uint8');
			bytes(53:56)   = typecast(obj.raw_data_layout(:),                 'uint8');
			bytes(57:60)   = typecast(obj.decode_mode(:),                     'uint8');
			bytes(61:64)   = typecast(obj.sampling_mode(:),                   'uint8');
			bytes(65:68)   = typecast(obj.sampling_frequency(:),              'uint8');
			bytes(69:72)   = typecast(obj.speed_of_sound(:),                  'uint8');
			bytes(73:76)   = typecast(obj.channel_mapping_offset(:),          'uint8');
			bytes(77:80)   = typecast(obj.sample_count(:),                    'uint8');
			bytes(81:84)   = typecast(obj.channel_count(:),                   'uint8');
			bytes(85:88)   = typecast(obj.receive_event_count(:),             'uint8');
			bytes(89:96)   = typecast(obj.transducer_tile_count(:),           'uint8');
			bytes(97:104)  = typecast(obj.transducer_element_pitch(:),        'uint8');
			bytes(105:108) = typecast(obj.group_acquisition_time(:),          'uint8');
			bytes(109:112) = typecast(obj.ensemble_repetition_interval(:),    'uint8');
			bytes(113:116) = typecast(obj.acquisition_mode(:),                'uint8');
			bytes(117:120) = typecast(obj.acquisition_parameters_offset(:),   'uint8');
			bytes(121:124) = typecast(obj.contrast_mode(:),                   'uint8');
			bytes(125:128) = typecast(obj.contrast_parameters_offset(:),      'uint8');
			bytes(129:132) = typecast(obj.emission_descriptors_offset(:),     'uint8');
			bytes(133:136) = typecast(obj.time_delays_offset(:),              'uint8');
			bytes(137:140) = typecast(obj.demodulation_frequencies_offset(:), 'uint8');
			bytes(141:144) = typecast(obj.transducer_transforms_offset(:),    'uint8');
			bytes(145:148) = typecast(obj.string_count(:),                    'uint8');
			bytes(149:152) = typecast(obj.string_table_offset(:),             'uint8');
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.HeaderV3
			end
			out = ZBP.HeaderV3;
			out.magic(:)                           = typecast(bytes(1:8),     'uint64');
			out.major(:)                           = typecast(bytes(9:12),    'uint32');
			out.minor(:)                           = typecast(bytes(13:16),   'uint32');
			out.raw_data_dimension(:)              = typecast(bytes(17:32),   'uint32');
			out.raw_data_size(:)                   = typecast(bytes(33:40),   'uint64');
			out.raw_data_offset(:)                 = typecast(bytes(41:44),   'int32');
			out.raw_data_kind(:)                   = typecast(bytes(45:48),   'uint32');
			out.raw_data_compression_kind(:)       = typecast(bytes(49:52),   'uint32');
			out.raw_data_layout(:)                 = typecast(bytes(53:56),   'uint32');
			out.decode_mode(:)                     = typecast(bytes(57:60),   'uint32');
			out.sampling_mode(:)                   = typecast(bytes(61:64),   'uint32');
			out.sampling_frequency(:)              = typecast(bytes(65:68),   'single');
			out.speed_of_sound(:)                  = typecast(bytes(69:72),   'single');
			out.channel_mapping_offset(:)          = typecast(bytes(73:76),   'int32');
			out.sample_count(:)                    = typecast(bytes(77:80),   'uint32');
			out.channel_count(:)                   = typecast(bytes(81:84),   'uint32');
			out.receive_event_count(:)             = typecast(bytes(85:88),   'uint32');
			out.transducer_tile_count(:)           = typecast(bytes(89:96),   'uint32');
			out.transducer_element_pitch(:)        = typecast(bytes(97:104),  'single');
			out.group_acquisition_time(:)          = typecast(bytes(105:108), 'single');
			out.ensemble_repetition_interval(:)    = typecast(bytes(109:112), 'single');
			out.acquisition_mode(:)                = typecast(bytes(113:116), 'uint32');
			out.acquisition_parameters_offset(:)   = typecast(bytes(117:120), 'int32');
			out.contrast_mode(:)                   = typecast(bytes(121:124), 'uint32');
			out.contrast_parameters_offset(:)      = typecast(bytes(125:128), 'int32');
			out.emission_descriptors_offset(:)     = typecast(bytes(129:132), 'int32');
			out.time_delays_offset(:)              = typecast(bytes(133:136), 'int32');
			out.demodulation_frequencies_offset(:) = typecast(bytes(137:140), 'int32');
			out.transducer_transforms_offset(:)    = typecast(bytes(141:144), 'int32');
			out.string_count(:)                    = typecast(bytes(145:148), 'uint32');
			out.string_table_offset(:)             = typecast(bytes(149:152), 'int32');
		end
	end
end

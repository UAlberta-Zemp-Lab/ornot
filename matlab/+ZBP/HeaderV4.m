% See LICENSE for license details.

% GENERATED CODE

classdef HeaderV4
	properties
		magic(1,1)                           uint64
		major(1,1)                           uint32
		minor(1,1)                           uint32
		raw_data_size(1,1)                   uint64
		raw_data_offset(1,1)                 int32
		raw_data_compression_kind(1,1)       uint32 % ZBP.DataCompressionKind
		raw_data_kind(1,1)                   uint32 % ZBP.DataKind
		data_layout_kind(1,1)                uint32 % ZBP.DataLayoutKind
		data_layout_offset(1,1)              int32
		element_count(1,2)                   uint32
		acquisition_precedence(1,4)          uint32 % ZBP.LayoutPrecedence
		sample_count(1,1)                    uint32
		receive_event_count(1,1)             uint32
		channel_count(1,1)                   uint32
		data_frame_count(1,1)                uint32
		ensemble_count(1,1)                  uint32
		decode_mode(1,1)                     uint32 % ZBP.DecodeMode
		sampling_mode(1,1)                   uint32 % ZBP.SamplingMode
		sampling_frequency(1,1)              single
		speed_of_sound(1,1)                  single
		transducer_tile_count(1,2)           uint32
		transducer_element_pitch(1,2)        single
		group_acquisition_time(1,1)          single
		ensemble_repetition_interval(1,1)    single
		acquisition_mode(1,1)                uint32 % ZBP.AcquisitionKind
		acquisition_parameters_offset(1,1)   int32
		contrast_mode(1,1)                   uint32 % ZBP.ContrastMode
		contrast_data_flags(1,1)             uint32
		contrast_parameters_offset(1,1)      int32
		emission_descriptors_offset(1,1)     int32
		time_delays_offset(1,1)              int32
		demodulation_frequencies_offset(1,1) int32
		transducer_transforms_offset(1,1)    int32
		string_count(1,1)                    uint32
		string_table_offset(1,1)             int32
		format_extension_offset(1,1)         int32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 176
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.HeaderV4
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.HeaderV4.byteSize);
			bytes(1:8)     = typecast(obj.magic(:),                           'uint8');
			bytes(9:12)    = typecast(obj.major(:),                           'uint8');
			bytes(13:16)   = typecast(obj.minor(:),                           'uint8');
			bytes(17:24)   = typecast(obj.raw_data_size(:),                   'uint8');
			bytes(25:28)   = typecast(obj.raw_data_offset(:),                 'uint8');
			bytes(29:32)   = typecast(obj.raw_data_compression_kind(:),       'uint8');
			bytes(33:36)   = typecast(obj.raw_data_kind(:),                   'uint8');
			bytes(37:40)   = typecast(obj.data_layout_kind(:),                'uint8');
			bytes(41:44)   = typecast(obj.data_layout_offset(:),              'uint8');
			bytes(45:52)   = typecast(obj.element_count(:),                   'uint8');
			bytes(53:68)   = typecast(obj.acquisition_precedence(:),          'uint8');
			bytes(69:72)   = typecast(obj.sample_count(:),                    'uint8');
			bytes(73:76)   = typecast(obj.receive_event_count(:),             'uint8');
			bytes(77:80)   = typecast(obj.channel_count(:),                   'uint8');
			bytes(81:84)   = typecast(obj.data_frame_count(:),                'uint8');
			bytes(85:88)   = typecast(obj.ensemble_count(:),                  'uint8');
			bytes(89:92)   = typecast(obj.decode_mode(:),                     'uint8');
			bytes(93:96)   = typecast(obj.sampling_mode(:),                   'uint8');
			bytes(97:100)  = typecast(obj.sampling_frequency(:),              'uint8');
			bytes(101:104) = typecast(obj.speed_of_sound(:),                  'uint8');
			bytes(105:112) = typecast(obj.transducer_tile_count(:),           'uint8');
			bytes(113:120) = typecast(obj.transducer_element_pitch(:),        'uint8');
			bytes(121:124) = typecast(obj.group_acquisition_time(:),          'uint8');
			bytes(125:128) = typecast(obj.ensemble_repetition_interval(:),    'uint8');
			bytes(129:132) = typecast(obj.acquisition_mode(:),                'uint8');
			bytes(133:136) = typecast(obj.acquisition_parameters_offset(:),   'uint8');
			bytes(137:140) = typecast(obj.contrast_mode(:),                   'uint8');
			bytes(141:144) = typecast(obj.contrast_data_flags(:),             'uint8');
			bytes(145:148) = typecast(obj.contrast_parameters_offset(:),      'uint8');
			bytes(149:152) = typecast(obj.emission_descriptors_offset(:),     'uint8');
			bytes(153:156) = typecast(obj.time_delays_offset(:),              'uint8');
			bytes(157:160) = typecast(obj.demodulation_frequencies_offset(:), 'uint8');
			bytes(161:164) = typecast(obj.transducer_transforms_offset(:),    'uint8');
			bytes(165:168) = typecast(obj.string_count(:),                    'uint8');
			bytes(169:172) = typecast(obj.string_table_offset(:),             'uint8');
			bytes(173:176) = typecast(obj.format_extension_offset(:),         'uint8');
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.HeaderV4
			end
			out = ZBP.HeaderV4;
			out.magic(:)                           = typecast(bytes(1:8),     'uint64');
			out.major(:)                           = typecast(bytes(9:12),    'uint32');
			out.minor(:)                           = typecast(bytes(13:16),   'uint32');
			out.raw_data_size(:)                   = typecast(bytes(17:24),   'uint64');
			out.raw_data_offset(:)                 = typecast(bytes(25:28),   'int32');
			out.raw_data_compression_kind(:)       = typecast(bytes(29:32),   'uint32');
			out.raw_data_kind(:)                   = typecast(bytes(33:36),   'uint32');
			out.data_layout_kind(:)                = typecast(bytes(37:40),   'uint32');
			out.data_layout_offset(:)              = typecast(bytes(41:44),   'int32');
			out.element_count(:)                   = typecast(bytes(45:52),   'uint32');
			out.acquisition_precedence(:)          = typecast(bytes(53:68),   'uint32');
			out.sample_count(:)                    = typecast(bytes(69:72),   'uint32');
			out.receive_event_count(:)             = typecast(bytes(73:76),   'uint32');
			out.channel_count(:)                   = typecast(bytes(77:80),   'uint32');
			out.data_frame_count(:)                = typecast(bytes(81:84),   'uint32');
			out.ensemble_count(:)                  = typecast(bytes(85:88),   'uint32');
			out.decode_mode(:)                     = typecast(bytes(89:92),   'uint32');
			out.sampling_mode(:)                   = typecast(bytes(93:96),   'uint32');
			out.sampling_frequency(:)              = typecast(bytes(97:100),  'single');
			out.speed_of_sound(:)                  = typecast(bytes(101:104), 'single');
			out.transducer_tile_count(:)           = typecast(bytes(105:112), 'uint32');
			out.transducer_element_pitch(:)        = typecast(bytes(113:120), 'single');
			out.group_acquisition_time(:)          = typecast(bytes(121:124), 'single');
			out.ensemble_repetition_interval(:)    = typecast(bytes(125:128), 'single');
			out.acquisition_mode(:)                = typecast(bytes(129:132), 'uint32');
			out.acquisition_parameters_offset(:)   = typecast(bytes(133:136), 'int32');
			out.contrast_mode(:)                   = typecast(bytes(137:140), 'uint32');
			out.contrast_data_flags(:)             = typecast(bytes(141:144), 'uint32');
			out.contrast_parameters_offset(:)      = typecast(bytes(145:148), 'int32');
			out.emission_descriptors_offset(:)     = typecast(bytes(149:152), 'int32');
			out.time_delays_offset(:)              = typecast(bytes(153:156), 'int32');
			out.demodulation_frequencies_offset(:) = typecast(bytes(157:160), 'int32');
			out.transducer_transforms_offset(:)    = typecast(bytes(161:164), 'int32');
			out.string_count(:)                    = typecast(bytes(165:168), 'uint32');
			out.string_table_offset(:)             = typecast(bytes(169:172), 'int32');
			out.format_extension_offset(:)         = typecast(bytes(173:176), 'int32');
		end
	end
end

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

	properties (Constant)
		byteSize(1,1) uint32 = 3724
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.HeaderV1
			end
			out = ZBP.HeaderV1;
			out.magic(:)                       = typecast(bytes(1:8),       'uint64');
			out.version(:)                     = typecast(bytes(9:12),      'uint32');
			out.decode_mode(:)                 = typecast(bytes(13:14),     'int16');
			out.beamform_mode(:)               = typecast(bytes(15:16),     'int16');
			out.raw_data_dimension(:)          = typecast(bytes(17:32),     'uint32');
			out.sample_count(:)                = typecast(bytes(33:36),     'uint32');
			out.channel_count(:)               = typecast(bytes(37:40),     'uint32');
			out.receive_event_count(:)         = typecast(bytes(41:44),     'uint32');
			out.frame_count(:)                 = typecast(bytes(45:48),     'uint32');
			out.transducer_element_pitch(:)    = typecast(bytes(49:56),     'single');
			out.transducer_transform_matrix(:) = typecast(bytes(57:120),    'single');
			out.channel_mapping(:)             = typecast(bytes(121:632),   'int16');
			out.steering_angles(:)             = typecast(bytes(633:1656),  'single');
			out.focal_depths(:)                = typecast(bytes(1657:2680), 'single');
			out.sparse_elements(:)             = typecast(bytes(2681:3192), 'int16');
			out.hadamard_rows(:)               = typecast(bytes(3193:3704), 'int16');
			out.speed_of_sound(:)              = typecast(bytes(3705:3708), 'single');
			out.demodulation_frequency(:)      = typecast(bytes(3709:3712), 'single');
			out.sampling_frequency(:)          = typecast(bytes(3713:3716), 'single');
			out.time_offset(:)                 = typecast(bytes(3717:3720), 'single');
			out.transmit_mode(:)               = typecast(bytes(3721:3724), 'uint32');
		end

		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.HeaderV1
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.HeaderV1.byteSize);
			bytes(1:8)       = typecast(obj.magic(:),                       'uint8');
			bytes(9:12)      = typecast(obj.version(:),                     'uint8');
			bytes(13:14)     = typecast(obj.decode_mode(:),                 'uint8');
			bytes(15:16)     = typecast(obj.beamform_mode(:),               'uint8');
			bytes(17:32)     = typecast(obj.raw_data_dimension(:),          'uint8');
			bytes(33:36)     = typecast(obj.sample_count(:),                'uint8');
			bytes(37:40)     = typecast(obj.channel_count(:),               'uint8');
			bytes(41:44)     = typecast(obj.receive_event_count(:),         'uint8');
			bytes(45:48)     = typecast(obj.frame_count(:),                 'uint8');
			bytes(49:56)     = typecast(obj.transducer_element_pitch(:),    'uint8');
			bytes(57:120)    = typecast(obj.transducer_transform_matrix(:), 'uint8');
			bytes(121:632)   = typecast(obj.channel_mapping(:),             'uint8');
			bytes(633:1656)  = typecast(obj.steering_angles(:),             'uint8');
			bytes(1657:2680) = typecast(obj.focal_depths(:),                'uint8');
			bytes(2681:3192) = typecast(obj.sparse_elements(:),             'uint8');
			bytes(3193:3704) = typecast(obj.hadamard_rows(:),               'uint8');
			bytes(3705:3708) = typecast(obj.speed_of_sound(:),              'uint8');
			bytes(3709:3712) = typecast(obj.demodulation_frequency(:),      'uint8');
			bytes(3713:3716) = typecast(obj.sampling_frequency(:),          'uint8');
			bytes(3717:3720) = typecast(obj.time_offset(:),                 'uint8');
			bytes(3721:3724) = typecast(obj.transmit_mode(:),               'uint8');
		end
	end
end

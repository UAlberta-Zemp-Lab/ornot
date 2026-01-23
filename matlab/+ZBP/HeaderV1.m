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

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 0;
			out      = ZBP.HeaderV1;

			out.magic(:) = typecast(bytes((consumed + 1):(consumed + 8)), 'uint64');
			consumed = consumed + 8;

			out.version(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'uint32');
			consumed = consumed + 4;

			out.decode_mode(:) = typecast(bytes((consumed + 1):(consumed + 2)), 'int16');
			consumed = consumed + 2;

			out.beamform_mode(:) = typecast(bytes((consumed + 1):(consumed + 2)), 'int16');
			consumed = consumed + 2;

			out.raw_data_dimension(:) = typecast(bytes((consumed + 1):(consumed + 16)), 'uint32');
			consumed = consumed + 16;

			out.sample_count(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'uint32');
			consumed = consumed + 4;

			out.channel_count(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'uint32');
			consumed = consumed + 4;

			out.receive_event_count(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'uint32');
			consumed = consumed + 4;

			out.frame_count(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'uint32');
			consumed = consumed + 4;

			out.transducer_element_pitch(:) = typecast(bytes((consumed + 1):(consumed + 8)), 'single');
			consumed = consumed + 8;

			out.transducer_transform_matrix(:) = typecast(bytes((consumed + 1):(consumed + 64)), 'single');
			consumed = consumed + 64;

			out.channel_mapping(:) = typecast(bytes((consumed + 1):(consumed + 512)), 'int16');
			consumed = consumed + 512;

			out.steering_angles(:) = typecast(bytes((consumed + 1):(consumed + 1024)), 'single');
			consumed = consumed + 1024;

			out.focal_depths(:) = typecast(bytes((consumed + 1):(consumed + 1024)), 'single');
			consumed = consumed + 1024;

			out.sparse_elements(:) = typecast(bytes((consumed + 1):(consumed + 512)), 'int16');
			consumed = consumed + 512;

			out.hadamard_rows(:) = typecast(bytes((consumed + 1):(consumed + 512)), 'int16');
			consumed = consumed + 512;

			out.speed_of_sound(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.demodulation_frequency(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.sampling_frequency(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.time_offset(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.transmit_mode(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'uint32');
			consumed = consumed + 4;
		end
	end
end

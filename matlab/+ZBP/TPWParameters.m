% See LICENSE for license details.

% GENERATED CODE

classdef TPWParameters
	properties
		tilting_angles_offset(1,1)                int32
		transmit_receive_orientations_offset(1,1) int32
	end

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 0;
			out      = ZBP.TPWParameters;

			out.tilting_angles_offset(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;

			out.transmit_receive_orientations_offset(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;
		end
	end
end

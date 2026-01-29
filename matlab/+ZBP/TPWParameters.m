% See LICENSE for license details.

% GENERATED CODE

classdef TPWParameters
	properties
		tilting_angles_offset(1,1)                int32
		transmit_receive_orientations_offset(1,1) int32
	end

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 8;
			out      = ZBP.TPWParameters;
			out.tilting_angles_offset(:)                = typecast(bytes(1:4), '*int32');
			out.transmit_receive_orientations_offset(:) = typecast(bytes(5:8), '*int32');
		end
	end
end

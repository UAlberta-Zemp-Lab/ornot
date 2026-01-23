% See LICENSE for license details.

% GENERATED CODE

classdef RCATransmitFocus
	properties
		focal_depth(1,1)                  single
		steering_angle(1,1)               single
		origin_offset(1,1)                single
		transmit_receive_orientation(1,1) uint32
	end

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 0;
			out      = ZBP.RCATransmitFocus;

			out.focal_depth(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.steering_angle(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.origin_offset(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.transmit_receive_orientation(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'uint32');
			consumed = consumed + 4;
		end
	end
end

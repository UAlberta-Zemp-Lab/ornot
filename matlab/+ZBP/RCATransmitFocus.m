% See LICENSE for license details.

% GENERATED CODE

classdef RCATransmitFocus
	properties
		focal_depth(1,1)                  single
		steering_angle(1,1)               single
		origin_offset(1,1)                single
		transmit_receive_orientation(1,1) uint32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 16
	end

	methods (Static)
		function out = fromBytes(bytes)
			out = ZBP.RCATransmitFocus;
			out.focal_depth(:)                  = typecast(bytes(1:4),   'single');
			out.steering_angle(:)               = typecast(bytes(5:8),   'single');
			out.origin_offset(:)                = typecast(bytes(9:12),  'single');
			out.transmit_receive_orientation(:) = typecast(bytes(13:16), 'uint32');
		end
	end
end

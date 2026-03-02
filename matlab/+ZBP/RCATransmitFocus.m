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

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.RCATransmitFocus
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.RCATransmitFocus.byteSize);
			bytes(1:4)   = typecast(obj.focal_depth(:),                  'uint8');
			bytes(5:8)   = typecast(obj.steering_angle(:),               'uint8');
			bytes(9:12)  = typecast(obj.origin_offset(:),                'uint8');
			bytes(13:16) = typecast(obj.transmit_receive_orientation(:), 'uint8');
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.RCATransmitFocus
			end
			out = ZBP.RCATransmitFocus;
			out.focal_depth(:)                  = typecast(bytes(1:4),   'single');
			out.steering_angle(:)               = typecast(bytes(5:8),   'single');
			out.origin_offset(:)                = typecast(bytes(9:12),  'single');
			out.transmit_receive_orientation(:) = typecast(bytes(13:16), 'uint32');
		end
	end
end

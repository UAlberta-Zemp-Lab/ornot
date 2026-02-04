% See LICENSE for license details.

% GENERATED CODE

classdef TPWParameters
	properties
		tilting_angles_offset(1,1)                int32
		transmit_receive_orientations_offset(1,1) int32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 8
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.TPWParameters
			end
			out = ZBP.TPWParameters;
			out.tilting_angles_offset(:)                = typecast(bytes(1:4), 'int32');
			out.transmit_receive_orientations_offset(:) = typecast(bytes(5:8), 'int32');
		end

		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.TPWParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.TPWParameters.byteSize);
			bytes(1:4) = typecast(obj.tilting_angles_offset(:),                'uint8');
			bytes(5:8) = typecast(obj.transmit_receive_orientations_offset(:), 'uint8');
		end
	end
end

% See LICENSE for license details.

% GENERATED CODE

classdef VLSParameters
	properties
		focal_depths_offset(1,1)                  int32
		origin_offsets_offset(1,1)                int32
		transmit_receive_orientations_offset(1,1) int32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 12
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.VLSParameters
			end
			out = ZBP.VLSParameters;
			out.focal_depths_offset(:)                  = typecast(bytes(1:4),  'int32');
			out.origin_offsets_offset(:)                = typecast(bytes(5:8),  'int32');
			out.transmit_receive_orientations_offset(:) = typecast(bytes(9:12), 'int32');
		end
	end
end

% See LICENSE for license details.

% GENERATED CODE

classdef EPIC_FORCESParameters
	properties
		transmit_foci_offset(1,1) int32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 4
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.EPIC_FORCESParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.EPIC_FORCESParameters.byteSize);
			bytes(1:4) = typecast(obj.transmit_foci_offset(:), 'uint8');
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.EPIC_FORCESParameters
			end
			out = ZBP.EPIC_FORCESParameters;
			out.transmit_foci_offset(:) = typecast(bytes(1:4), 'int32');
		end
	end
end

% See LICENSE for license details.

% GENERATED CODE

classdef HEXDopplerParameters
	properties
		bin_count(1,2) int32
		bin_size(1,2)  int32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 16
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.HEXDopplerParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.HEXDopplerParameters.byteSize);
			bytes(1:8)  = typecast(obj.bin_count(:), 'uint8');
			bytes(9:16) = typecast(obj.bin_size(:),  'uint8');
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.HEXDopplerParameters
			end
			out = ZBP.HEXDopplerParameters;
			out.bin_count(:) = typecast(bytes(1:8),  'int32');
			out.bin_size(:)  = typecast(bytes(9:16), 'int32');
		end
	end
end

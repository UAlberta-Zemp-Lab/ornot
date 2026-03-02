% See LICENSE for license details.

% GENERATED CODE

classdef BaseHeader
	properties
		magic(1,1) uint64
		major(1,1) uint32
		minor(1,1) uint32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 16
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.BaseHeader
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.BaseHeader.byteSize);
			bytes(1:8)   = typecast(obj.magic(:), 'uint8');
			bytes(9:12)  = typecast(obj.major(:), 'uint8');
			bytes(13:16) = typecast(obj.minor(:), 'uint8');
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.BaseHeader
			end
			out = ZBP.BaseHeader;
			out.magic(:) = typecast(bytes(1:8),   'uint64');
			out.major(:) = typecast(bytes(9:12),  'uint32');
			out.minor(:) = typecast(bytes(13:16), 'uint32');
		end
	end
end

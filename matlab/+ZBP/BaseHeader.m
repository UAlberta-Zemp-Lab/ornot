% See LICENSE for license details.

% GENERATED CODE

classdef BaseHeader
	properties
		magic(1,1) uint64
		major(1,1) uint32
		minor(1,1) uint32
	end

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 16;
			out      = ZBP.BaseHeader;
			out.magic(:) = typecast(bytes(1:8),   '*uint64');
			out.major(:) = typecast(bytes(9:12),  '*uint32');
			out.minor(:) = typecast(bytes(13:16), '*uint32');
		end
	end
end

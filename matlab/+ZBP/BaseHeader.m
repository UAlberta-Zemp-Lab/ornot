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
			consumed = 0;
			out      = ZBP.BaseHeader;

			out.magic(:) = typecast(bytes((consumed + 1):(consumed + 8)), 'uint64');
			consumed = consumed + 8;

			out.major(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'uint32');
			consumed = consumed + 4;

			out.minor(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'uint32');
			consumed = consumed + 4;
		end
	end
end

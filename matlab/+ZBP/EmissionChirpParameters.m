% See LICENSE for license details.

% GENERATED CODE

classdef EmissionChirpParameters
	properties
		duration(1,1)      single
		min_frequency(1,1) single
		max_frequency(1,1) single
	end

	properties (Constant)
		byteSize(1,1) uint32 = 12
	end

	methods (Static)
		function out = fromBytes(bytes)
			out = ZBP.EmissionChirpParameters;
			out.duration(:)      = typecast(bytes(1:4),  'single');
			out.min_frequency(:) = typecast(bytes(5:8),  'single');
			out.max_frequency(:) = typecast(bytes(9:12), 'single');
		end
	end
end

% See LICENSE for license details.

% GENERATED CODE

classdef EmissionChirpParameters
	properties
		duration(1,1)      single
		min_frequency(1,1) single
		max_frequency(1,1) single
	end

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 0;
			out      = ZBP.EmissionChirpParameters;

			out.duration(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.min_frequency(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.max_frequency(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;
		end
	end
end

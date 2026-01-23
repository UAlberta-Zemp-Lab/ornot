% See LICENSE for license details.

% GENERATED CODE

classdef EmissionSineParameters
	properties
		cycles(1,1)    single
		frequency(1,1) single
	end

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 0;
			out      = ZBP.EmissionSineParameters;

			out.cycles(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;

			out.frequency(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'single');
			consumed = consumed + 4;
		end
	end
end

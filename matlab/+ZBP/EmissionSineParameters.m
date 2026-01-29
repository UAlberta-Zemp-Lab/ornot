% See LICENSE for license details.

% GENERATED CODE

classdef EmissionSineParameters
	properties
		cycles(1,1)    single
		frequency(1,1) single
	end

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 8;
			out      = ZBP.EmissionSineParameters;
			out.cycles(:)    = typecast(bytes(1:4), '*single');
			out.frequency(:) = typecast(bytes(5:8), '*single');
		end
	end
end

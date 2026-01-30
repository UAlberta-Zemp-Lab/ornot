% See LICENSE for license details.

% GENERATED CODE

classdef EmissionSineParameters
	properties
		cycles(1,1)    single
		frequency(1,1) single
	end

	properties (Constant)
		byteSize(1,1) uint32 = 8
	end

	methods (Static)
		function out = fromBytes(bytes)
			out = ZBP.EmissionSineParameters;
			out.cycles(:)    = typecast(bytes(1:4), 'single');
			out.frequency(:) = typecast(bytes(5:8), 'single');
		end
	end
end

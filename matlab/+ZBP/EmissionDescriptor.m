% See LICENSE for license details.

% GENERATED CODE

classdef EmissionDescriptor
	properties
		emission_kind(1,1)     int32
		parameters_offset(1,1) int32
	end

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 0;
			out      = ZBP.EmissionDescriptor;

			out.emission_kind(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;

			out.parameters_offset(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;
		end
	end
end

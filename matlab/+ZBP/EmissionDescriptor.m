% See LICENSE for license details.

% GENERATED CODE

classdef EmissionDescriptor
	properties
		emission_kind(1,1)     int32
		parameters_offset(1,1) int32
	end

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 8;
			out      = ZBP.EmissionDescriptor;
			out.emission_kind(:)     = typecast(bytes(1:4), 'int32');
			out.parameters_offset(:) = typecast(bytes(5:8), 'int32');
		end
	end
end

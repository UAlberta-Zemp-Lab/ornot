% See LICENSE for license details.

% GENERATED CODE

classdef EmissionDescriptor
	properties
		emission_kind(1,1)     int32
		parameters_offset(1,1) int32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 8
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.EmissionDescriptor
			end
			out = ZBP.EmissionDescriptor;
			out.emission_kind(:)     = typecast(bytes(1:4), 'int32');
			out.parameters_offset(:) = typecast(bytes(5:8), 'int32');
		end

		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.EmissionDescriptor
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.EmissionDescriptor.byteSize);
			bytes(1:4) = typecast(obj.emission_kind(:),     'uint8');
			bytes(5:8) = typecast(obj.parameters_offset(:), 'uint8');
		end
	end
end

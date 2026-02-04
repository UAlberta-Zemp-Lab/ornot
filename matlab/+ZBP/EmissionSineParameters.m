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
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.EmissionSineParameters
			end
			out = ZBP.EmissionSineParameters;
			out.cycles(:)    = typecast(bytes(1:4), 'single');
			out.frequency(:) = typecast(bytes(5:8), 'single');
		end

		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.EmissionSineParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.EmissionSineParameters.byteSize);
			bytes(1:4) = typecast(obj.cycles(:),    'uint8');
			bytes(5:8) = typecast(obj.frequency(:), 'uint8');
		end
	end
end

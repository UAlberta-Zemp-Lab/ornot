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

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.EmissionChirpParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.EmissionChirpParameters.byteSize);
			bytes(1:4)  = typecast(obj.duration(:),      'uint8');
			bytes(5:8)  = typecast(obj.min_frequency(:), 'uint8');
			bytes(9:12) = typecast(obj.max_frequency(:), 'uint8');
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.EmissionChirpParameters
			end
			out = ZBP.EmissionChirpParameters;
			out.duration(:)      = typecast(bytes(1:4),  'single');
			out.min_frequency(:) = typecast(bytes(5:8),  'single');
			out.max_frequency(:) = typecast(bytes(9:12), 'single');
		end
	end
end

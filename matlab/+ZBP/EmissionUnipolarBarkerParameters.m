% See LICENSE for license details.

% GENERATED CODE

classdef EmissionUnipolarBarkerParameters
	properties
		burst_parameters(1,1) ZBP.EmissionUnipolarBurstParameters
		code_length(1,1)      single
	end

	properties (Constant)
		byteSize(1,1) uint32 = 20
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.EmissionUnipolarBarkerParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.EmissionUnipolarBarkerParameters.byteSize);
			bytes(17:20) = typecast(obj.code_length(:), 'uint8');
			bytes(1:16) = obj.burst_parameters.toBytes();
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.EmissionUnipolarBarkerParameters
			end
			out = ZBP.EmissionUnipolarBarkerParameters;
			out.code_length(:) = typecast(bytes(17:20), 'single');
			out.burst_parameters = ZBP.EmissionUnipolarBurstParameters.fromBytes(bytes(1:16));
		end
	end
end

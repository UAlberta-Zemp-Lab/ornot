% See LICENSE for license details.

% GENERATED CODE

classdef EmissionUnipolarBurstParameters
	properties
		polarity(1,1)   single
		frequency(1,1)  single
		cycles(1,1)     single
		duty_cycle(1,1) single
	end

	properties (Constant)
		byteSize(1,1) uint32 = 16
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.EmissionUnipolarBurstParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.EmissionUnipolarBurstParameters.byteSize);
			bytes(1:4)   = typecast(obj.polarity(:),   'uint8');
			bytes(5:8)   = typecast(obj.frequency(:),  'uint8');
			bytes(9:12)  = typecast(obj.cycles(:),     'uint8');
			bytes(13:16) = typecast(obj.duty_cycle(:), 'uint8');
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.EmissionUnipolarBurstParameters
			end
			out = ZBP.EmissionUnipolarBurstParameters;
			out.polarity(:)   = typecast(bytes(1:4),   'single');
			out.frequency(:)  = typecast(bytes(5:8),   'single');
			out.cycles(:)     = typecast(bytes(9:12),  'single');
			out.duty_cycle(:) = typecast(bytes(13:16), 'single');
		end
	end
end

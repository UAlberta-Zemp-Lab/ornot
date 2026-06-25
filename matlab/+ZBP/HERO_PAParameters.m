% See LICENSE for license details.

% GENERATED CODE

classdef HERO_PAParameters
	properties
		transmit_receive_orientation(1,1) uint32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 4
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.HERO_PAParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.HERO_PAParameters.byteSize);
			bytes(1:4) = typecast(obj.transmit_receive_orientation(:), 'uint8');
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.HERO_PAParameters
			end
			out = ZBP.HERO_PAParameters;
			out.transmit_receive_orientation(:) = typecast(bytes(1:4), 'uint32');
		end
	end
end

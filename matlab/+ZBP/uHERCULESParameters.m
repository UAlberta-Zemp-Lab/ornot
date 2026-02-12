% See LICENSE for license details.

% GENERATED CODE

classdef uHERCULESParameters
	properties
		transmit_focus(1,1)         ZBP.RCATransmitFocus
		sparse_elements_offset(1,1) int32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 20
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.uHERCULESParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.uHERCULESParameters.byteSize);
			bytes(17:20) = typecast(obj.sparse_elements_offset(:), 'uint8');
			bytes(1:16) = obj.transmit_focus.toBytes();
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.uHERCULESParameters
			end
			out = ZBP.uHERCULESParameters;
			out.sparse_elements_offset(:) = typecast(bytes(17:20), 'int32');
			out.transmit_focus = ZBP.RCATransmitFocus.fromBytes(bytes(1:16));
		end
	end
end

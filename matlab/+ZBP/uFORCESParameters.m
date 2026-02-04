% See LICENSE for license details.

% GENERATED CODE

classdef uFORCESParameters
	properties
		transmit_focus(1,1)         ZBP.RCATransmitFocus
		sparse_elements_offset(1,1) int32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 20
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.uFORCESParameters
			end
			out = ZBP.uFORCESParameters;
			out.sparse_elements_offset(:) = typecast(bytes(17:20), 'int32');
			out.transmit_focus = ZBP.RCATransmitFocus.fromBytes(bytes(1:16));
		end
	end
end

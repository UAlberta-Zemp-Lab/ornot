% See LICENSE for license details.

% GENERATED CODE

classdef uHERCULESParameters
	properties
		transmit_focus(1,1)         ZBP.RCATransmitFocus
		sparse_elements_offset(1,1) int32
	end

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 20;
			out      = ZBP.uHERCULESParameters;
			out.sparse_elements_offset(:) = typecast(bytes(17:20), '*int32');
			[out.transmit_focus, ~] = ZBP.RCATransmitFocus.fromBytes(bytes(1:16));
		end
	end
end

% See LICENSE for license details.

% GENERATED CODE

classdef uFORCESParameters
	properties
		transmit_focus(1,1)         ZBP.RCATransmitFocus
		sparse_elements_offset(1,1) int32
	end

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 0;
			out      = ZBP.uFORCESParameters;

			[sub, subUsed] = ZBP.RCATransmitFocus.fromBytes(bytes((consumed + 1):end));
			out.transmit_focus = sub;
			consumed = consumed + subUsed;

			out.sparse_elements_offset(:) = typecast(bytes((consumed + 1):(consumed + 4)), 'int32');
			consumed = consumed + 4;
		end
	end
end

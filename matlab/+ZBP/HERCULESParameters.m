% See LICENSE for license details.

% GENERATED CODE

classdef HERCULESParameters
	properties
		transmit_focus(1,1) ZBP.RCATransmitFocus
	end

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 0;
			out      = ZBP.HERCULESParameters;

			[sub, subUsed] = ZBP.RCATransmitFocus.fromBytes(bytes((consumed + 1):end));
			out.transmit_focus = sub;
			consumed = consumed + subUsed;
		end
	end
end

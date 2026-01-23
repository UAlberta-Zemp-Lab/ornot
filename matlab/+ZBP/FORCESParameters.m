% See LICENSE for license details.

% GENERATED CODE

classdef FORCESParameters
	properties
		transmit_focus(1,1) ZBP.RCATransmitFocus
	end

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 0;
			out      = ZBP.FORCESParameters;

			[sub, subUsed] = ZBP.RCATransmitFocus.fromBytes(bytes((consumed + 1):end));
			out.transmit_focus = sub;
			consumed = consumed + subUsed;
		end
	end
end

% See LICENSE for license details.

% GENERATED CODE

classdef FORCESParameters
	properties
		transmit_focus(1,1) ZBP.RCATransmitFocus
	end

	methods (Static)
		function [out, consumed] = fromBytes(bytes)
			consumed = 16;
			out      = ZBP.FORCESParameters;
			[out.transmit_focus, ~] = ZBP.RCATransmitFocus.fromBytes(bytes(1:16));
		end
	end
end

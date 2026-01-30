% See LICENSE for license details.

% GENERATED CODE

classdef FORCESParameters
	properties
		transmit_focus(1,1) ZBP.RCATransmitFocus
	end

	properties (Constant)
		byteSize(1,1) uint32 = 16
	end

	methods (Static)
		function out = fromBytes(bytes)
			out = ZBP.FORCESParameters;
			[out.transmit_focus, ~] = ZBP.RCATransmitFocus.fromBytes(bytes(1:16));
		end
	end
end

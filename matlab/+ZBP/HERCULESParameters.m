% See LICENSE for license details.

% GENERATED CODE

classdef HERCULESParameters
	properties
		transmit_focus(1,1) ZBP.RCATransmitFocus
	end

	properties (Constant)
		byteSize(1,1) uint32 = 16
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.HERCULESParameters
			end
			out = ZBP.HERCULESParameters;
			out.transmit_focus = ZBP.RCATransmitFocus.fromBytes(bytes(1:16));
		end
	end
end

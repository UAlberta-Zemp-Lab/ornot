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

		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.HERCULESParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.HERCULESParameters.byteSize);
			bytes(1:16) = obj.transmit_focus.toBytes();
		end
	end
end

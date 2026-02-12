% See LICENSE for license details.

% GENERATED CODE

classdef FORCESParameters
	properties
		transmit_focus(1,1) ZBP.RCATransmitFocus
	end

	properties (Constant)
		byteSize(1,1) uint32 = 16
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.FORCESParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.FORCESParameters.byteSize);
			bytes(1:16) = obj.transmit_focus.toBytes();
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.FORCESParameters
			end
			out = ZBP.FORCESParameters;
			out.transmit_focus = ZBP.RCATransmitFocus.fromBytes(bytes(1:16));
		end
	end
end

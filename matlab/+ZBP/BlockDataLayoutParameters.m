% See LICENSE for license details.

% GENERATED CODE

classdef BlockDataLayoutParameters
	properties
		precedence(1,4)      uint32 % ZBP.LayoutPrecedence
		block_size(1,1)      uint32
		units_per_block(1,1) uint32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 24
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.BlockDataLayoutParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.BlockDataLayoutParameters.byteSize);
			bytes(1:16)  = typecast(obj.precedence(:),      'uint8');
			bytes(17:20) = typecast(obj.block_size(:),      'uint8');
			bytes(21:24) = typecast(obj.units_per_block(:), 'uint8');
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.BlockDataLayoutParameters
			end
			out = ZBP.BlockDataLayoutParameters;
			out.precedence(:)      = typecast(bytes(1:16),  'uint32');
			out.block_size(:)      = typecast(bytes(17:20), 'uint32');
			out.units_per_block(:) = typecast(bytes(21:24), 'uint32');
		end
	end
end

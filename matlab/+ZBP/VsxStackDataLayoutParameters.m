% See LICENSE for license details.

% GENERATED CODE

classdef VsxStackDataLayoutParameters
	properties
		precedence(1,3)                    uint32 % ZBP.LayoutPrecedence
		stack_size(1,1)                    uint32
		stack_channel_count(1,1)           uint32
		units_per_stack(1,1)               uint32
		row_channel_mapping_offset(1,1)    int32
		column_channel_mapping_offset(1,1) int32
		unit_indices_offset(1,1)           int32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 36
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.VsxStackDataLayoutParameters
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.VsxStackDataLayoutParameters.byteSize);
			bytes(1:12)  = typecast(obj.precedence(:),                    'uint8');
			bytes(13:16) = typecast(obj.stack_size(:),                    'uint8');
			bytes(17:20) = typecast(obj.stack_channel_count(:),           'uint8');
			bytes(21:24) = typecast(obj.units_per_stack(:),               'uint8');
			bytes(25:28) = typecast(obj.row_channel_mapping_offset(:),    'uint8');
			bytes(29:32) = typecast(obj.column_channel_mapping_offset(:), 'uint8');
			bytes(33:36) = typecast(obj.unit_indices_offset(:),           'uint8');
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.VsxStackDataLayoutParameters
			end
			out = ZBP.VsxStackDataLayoutParameters;
			out.precedence(:)                    = typecast(bytes(1:12),  'uint32');
			out.stack_size(:)                    = typecast(bytes(13:16), 'uint32');
			out.stack_channel_count(:)           = typecast(bytes(17:20), 'uint32');
			out.units_per_stack(:)               = typecast(bytes(21:24), 'uint32');
			out.row_channel_mapping_offset(:)    = typecast(bytes(25:28), 'int32');
			out.column_channel_mapping_offset(:) = typecast(bytes(29:32), 'int32');
			out.unit_indices_offset(:)           = typecast(bytes(33:36), 'int32');
		end
	end
end

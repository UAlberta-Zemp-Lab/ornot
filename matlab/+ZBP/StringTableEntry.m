% See LICENSE for license details.

% GENERATED CODE

classdef StringTableEntry
	properties
		string_tag_length(1,1) uint32
		string_tag_offset(1,1) int32
		string_length(1,1)     uint32
		string_offset(1,1)     int32
	end

	properties (Constant)
		byteSize(1,1) uint32 = 16
	end

	methods
		function bytes = toBytes(obj)
			arguments (Input)
				obj(1,1) ZBP.StringTableEntry
			end
			arguments (Output)
				bytes uint8
			end
			bytes = zeros(1, ZBP.StringTableEntry.byteSize);
			bytes(1:4)   = typecast(obj.string_tag_length(:), 'uint8');
			bytes(5:8)   = typecast(obj.string_tag_offset(:), 'uint8');
			bytes(9:12)  = typecast(obj.string_length(:),     'uint8');
			bytes(13:16) = typecast(obj.string_offset(:),     'uint8');
		end
	end

	methods (Static)
		function out = fromBytes(bytes)
			arguments (Input)
				bytes uint8
			end
			arguments (Output)
				out(1,1) ZBP.StringTableEntry
			end
			out = ZBP.StringTableEntry;
			out.string_tag_length(:) = typecast(bytes(1:4),   'uint32');
			out.string_tag_offset(:) = typecast(bytes(5:8),   'int32');
			out.string_length(:)     = typecast(bytes(9:12),  'uint32');
			out.string_offset(:)     = typecast(bytes(13:16), 'int32');
		end
	end
end
